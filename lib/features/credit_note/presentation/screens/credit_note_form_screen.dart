import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/core/presentation/widgets/form/form_section.dart';
import 'package:flutter_invoice_app/core/presentation/widgets/form/form_total_row.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/features/credit_note/data/credit_note_repository.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/credit_note_rules.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/models/credit_note.dart';
import 'package:flutter_invoice_app/features/credit_note/presentation/screens/credit_note_preview_screen.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Opens the form, or explains why there is nothing left to credit.
void openCreditNoteForm(BuildContext context, WidgetRef ref, Invoice invoice) {
  final notes = ref.read(creditNoteRepositoryProvider).getAll();
  if (CreditNoteRules.creditableLines(invoice, notes).isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This invoice has already been fully credited.'),
      ),
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => CreditNoteFormScreen(invoice: invoice)),
  );
}

class CreditNoteFormScreen extends ConsumerStatefulWidget {
  final Invoice invoice;

  const CreditNoteFormScreen({super.key, required this.invoice});

  @override
  ConsumerState<CreditNoteFormScreen> createState() =>
      _CreditNoteFormScreenState();
}

class _CreditLine {
  static const double _inputTolerance = 0.0005;

  final CreditableLine source;
  final String _initialQuantity;
  final String _initialRate;
  final TextEditingController quantity;
  final TextEditingController rate;
  bool selected = true;

  _CreditLine._(this.source, this._initialQuantity, this._initialRate)
    : quantity = TextEditingController(text: _initialQuantity),
      rate = TextEditingController(text: _initialRate);

  factory _CreditLine(CreditableLine source) {
    return _CreditLine._(
      source,
      _formatNumber(source.remainingQuantity),
      _formatNumber(source.line.unitPrice),
    );
  }

  bool get _isUnchanged =>
      quantity.text == _initialQuantity && rate.text == _initialRate;

  // Untouched lines use the exact stored values, so a full credit cannot drift
  // from the invoice because of what the text fields round to.
  double get quantityValue => _isUnchanged
      ? source.remainingQuantity
      : double.tryParse(quantity.text) ?? 0;

  double get rateValue =>
      _isUnchanged ? source.line.unitPrice : double.tryParse(rate.text) ?? 0;

  double get amount {
    if (!selected) return 0;
    return _isUnchanged ? source.remainingAmount : quantityValue * rateValue;
  }

  /// What is wrong with this line, in words the user can act on.
  String? get problem {
    if (!selected || _isUnchanged) return null;
    final enteredQuantity = double.tryParse(quantity.text);
    final enteredRate = double.tryParse(rate.text);
    if (enteredQuantity == null || enteredQuantity <= 0) {
      return 'Enter a quantity above zero.';
    }
    if (enteredRate == null || enteredRate <= 0) {
      return 'Enter a rate above zero.';
    }
    if (enteredQuantity > source.line.quantity + _inputTolerance) {
      return 'Quantity can\'t be more than the ${_formatNumber(source.line.quantity)} invoiced.';
    }
    if (enteredRate > source.line.unitPrice + _inputTolerance) {
      return 'Rate can\'t be more than the ${_formatNumber(source.line.unitPrice)} invoiced.';
    }
    if (amount > source.remainingAmount + CreditNoteRules.tolerance) {
      return 'This is more than can be credited on this line.';
    }
    return null;
  }

  LineItem toLineItem() {
    return LineItem(
      description: source.line.description,
      quantity: quantityValue,
      unitPrice: rateValue,
      total: amount,
      unit: source.line.unit,
    );
  }

  void dispose() {
    quantity.dispose();
    rate.dispose();
  }

  static String _formatNumber(double value) {
    return value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class _CreditNoteFormScreenState extends ConsumerState<CreditNoteFormScreen> {
  static const _reasonSuggestions = [
    'Order cancelled',
    'Goods returned',
    'Pricing correction',
    'Service not delivered',
  ];

  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  late final List<_CreditLine> _lines;
  late final String _number;
  late final double _vatRate;
  late final double _alreadyCredited;
  late final double _remainingSubtotal;
  late DateTime _date;
  bool _saving = false;

  Invoice get _invoice => widget.invoice;
  bool get _isVat => (_invoice.isVatApplicable ?? true) && _vatRate > 0;
  String get _currency => _invoice.currency ?? 'AED';
  double get _subtotal => _lines.fold(0.0, (sum, l) => sum + l.amount);
  double get _tax => _isVat ? _subtotal * (_vatRate / 100) : 0.0;
  bool get _allSelected => _lines.every((l) => l.selected);

  @override
  void initState() {
    super.initState();
    final repository = ref.read(creditNoteRepositoryProvider);
    final notes = repository.getAll();
    _lines = CreditNoteRules.creditableLines(
      _invoice,
      notes,
    ).map(_CreditLine.new).toList();
    _number = repository.nextNumber();
    _vatRate = CreditNoteRules.vatRateOf(_invoice);
    _alreadyCredited =
        CreditNoteRules.creditedByInvoice(notes)[_invoice.id] ?? 0;
    _remainingSubtotal = CreditNoteRules.remainingSubtotal(_invoice, notes);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final invoiceDate = _invoice.date;
    _date = invoiceDate != null && invoiceDate.isAfter(today)
        ? invoiceDate
        : today;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  String _money(double value) {
    return CurrencyFormatter.format(value, symbol: _currency);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _invoice.date ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _toggleAll() {
    final select = !_allSelected;
    setState(() {
      for (final line in _lines) {
        line.selected = select;
      }
    });
  }

  Future<void> _issue() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) {
      _showMessage('Add a reason before issuing.');
      return;
    }

    final selected = _lines.where((l) => l.selected).toList();
    if (selected.isEmpty) {
      _showMessage('Select at least one item to credit.');
      return;
    }
    if (selected.any((l) => l.problem != null)) {
      _showMessage('Correct the highlighted items before issuing.');
      return;
    }
    final subtotal = _subtotal;
    if (subtotal > _remainingSubtotal + CreditNoteRules.tolerance) {
      _showMessage(
        'Only ${_money(_remainingSubtotal)} before VAT is left to credit on this invoice.',
      );
      return;
    }

    setState(() => _saving = true);
    final repository = ref.read(creditNoteRepositoryProvider);
    final tax = _tax;
    final note = CreditNote(
      id: const Uuid().v4(),
      creditNoteNumber: repository.nextNumber(),
      date: _date,
      invoiceId: _invoice.id,
      invoiceNumber: _invoice.invoiceNumber,
      invoiceDate: _invoice.date,
      client: _invoice.client,
      items: selected.map((l) => l.toLineItem()).toList(),
      subtotal: subtotal,
      vatRate: _vatRate,
      taxAmount: tax,
      total: subtotal + tax,
      reason: _reasonController.text.trim(),
      isVatApplicable: _invoice.isVatApplicable ?? true,
      currency: _currency,
      placeOfSupply: _invoice.placeOfSupply,
      salesPerson: _invoice.salesPerson,
      updatedAt: DateTime.now(),
    );

    try {
      await repository.save(note);
    } catch (e) {
      debugPrint('Failed to save credit note: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Could not save the credit note. Please try again.');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CreditNotePreviewScreen(note: note)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final invoiceDate = _invoice.date;

    return Scaffold(
      backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text(
          'New Credit Note',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _saving ? null : _issue,
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Issue'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Form(
              key: _formKey,
              // Not a lazy list: a field scrolled out of a ListView is
              // unmounted, and the form would skip validating it.
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormSection(
                      title: 'Original Invoice',
                      icon: Icons.receipt_long_outlined,
                      children: [
                        _InfoField(
                          label: 'Customer',
                          value: _invoice.client.name,
                        ),
                        _InfoField(
                          label: 'Invoice',
                          value: invoiceDate != null
                              ? '${_invoice.invoiceNumber} • ${DateFormat.yMMMd().format(invoiceDate)}'
                              : _invoice.invoiceNumber,
                        ),
                        _InfoField(
                          label: 'Invoice Total',
                          value: _money(_invoice.total),
                        ),
                        _InfoField(
                          label: 'Already Credited',
                          value: _money(_alreadyCredited),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    FormSection(
                      title: 'Credit Note Details',
                      icon: Icons.info_outline,
                      children: [
                        _InfoField(label: 'Credit Note Number', value: _number),
                        InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Credit Note Date',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(DateFormat.yMMMd().format(_date)),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              key: const ValueKey('credit-note-reason'),
                              controller: _reasonController,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: const InputDecoration(
                                labelText: 'Reason',
                                hintText: 'Shown on the credit note',
                              ),
                              maxLines: 2,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Enter the reason for this credit note'
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _reasonSuggestions.map((reason) {
                                return ActionChip(
                                  label: Text(reason),
                                  onPressed: () => setState(
                                    () => _reasonController.text = reason,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Items to Credit',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _toggleAll,
                            child: Text(
                              _allSelected ? 'Clear All' : 'Select All',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).cardTheme.color ?? colors.surface,
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < _lines.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _CreditLineRow(
                              index: i,
                              line: _lines[i],
                              currency: _currency,
                              onChanged: () => setState(() {}),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          FormTotalRow(
                            label: 'Subtotal',
                            value: _subtotal,
                            currency: _currency,
                          ),
                          const SizedBox(height: 8),
                          if (_isVat) ...[
                            FormTotalRow(
                              label: 'VAT (${_formatRate(_vatRate)}%)',
                              value: _tax,
                              currency: _currency,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(),
                            ),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Credit',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Large amounts shrink rather than overflow on phones.
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _money(_subtotal + _tax),
                                    key: const ValueKey('credit-note-total'),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatRate(double rate) {
    return rate == rate.roundToDouble()
        ? rate.toInt().toString()
        : rate.toStringAsFixed(2);
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _CreditLineRow extends StatelessWidget {
  final int index;
  final _CreditLine line;
  final String currency;
  final VoidCallback onChanged;

  const _CreditLineRow({
    required this.index,
    required this.line,
    required this.currency,
    required this.onChanged,
  });

  Widget _numberField({
    required String label,
    required Key key,
    required TextEditingController controller,
  }) {
    return TextField(
      key: key,
      controller: controller,
      enabled: line.selected,
      decoration: InputDecoration(
        labelText: label,
        // Marks the field only. The message sits under the description,
        // because these fields are too narrow to hold it.
        errorText: line.problem != null ? '' : null,
        errorStyle: const TextStyle(height: 0, fontSize: 0),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      onChanged: (_) => onChanged(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final source = line.source;
    final titleColor = line.selected ? null : colors.onSurfaceVariant;
    final problem = line.problem;

    final checkbox = Semantics(
      label: 'Credit ${source.line.description}',
      child: Checkbox(
        key: ValueKey('credit-select-$index'),
        value: line.selected,
        onChanged: (value) {
          line.selected = value ?? false;
          onChanged();
        },
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          source.line.description,
          style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
        ),
        const SizedBox(height: 2),
        Text(
          'Up to ${CurrencyFormatter.format(source.remainingAmount, symbol: currency)} can be credited',
          style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
        ),
        if (problem != null) ...[
          const SizedBox(height: 2),
          Text(problem, style: TextStyle(fontSize: 13, color: colors.error)),
        ],
      ],
    );

    final quantityField = _numberField(
      label: 'Qty',
      key: ValueKey('credit-quantity-$index'),
      controller: line.quantity,
    );
    final rateField = _numberField(
      label: 'Rate',
      key: ValueKey('credit-rate-$index'),
      controller: line.rate,
    );
    final amount = Text(
      CurrencyFormatter.format(line.amount, symbol: currency),
      textAlign: TextAlign.right,
      style: TextStyle(fontWeight: FontWeight.w700, color: titleColor),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 560) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                checkbox,
                const SizedBox(width: 4),
                Expanded(child: details),
                const SizedBox(width: 16),
                SizedBox(width: 96, child: quantityField),
                const SizedBox(width: 12),
                SizedBox(width: 112, child: rateField),
                const SizedBox(width: 16),
                SizedBox(width: 128, child: amount),
              ],
            );
          }
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  checkbox,
                  const SizedBox(width: 4),
                  Expanded(child: details),
                  const SizedBox(width: 12),
                  amount,
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: quantityField),
                    const SizedBox(width: 12),
                    Expanded(child: rateField),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
