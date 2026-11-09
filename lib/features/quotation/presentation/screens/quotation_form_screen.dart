import 'package:flutter/material.dart';
import 'package:flutter_invoice_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/features/quotation/data/quotation_repository.dart';
import 'package:flutter_invoice_app/features/invoice/data/invoice_repository.dart';
import 'package:flutter_invoice_app/features/quotation/presentation/screens/quotation_pdf_preview_screen.dart';
import 'package:flutter_invoice_app/features/client/presentation/widgets/client_selector.dart';
import 'package:flutter_invoice_app/features/client/presentation/screens/client_form_screen.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';
import 'package:flutter_invoice_app/core/presentation/widgets/item_card.dart';
import 'package:flutter_invoice_app/core/presentation/widgets/form/form_section.dart';
import 'package:flutter_invoice_app/core/presentation/widgets/form/form_total_row.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class QuotationFormScreen extends ConsumerStatefulWidget {
  final Quotation? quotation;
  const QuotationFormScreen({super.key, this.quotation});

  @override
  ConsumerState<QuotationFormScreen> createState() =>
      _QuotationFormScreenState();
}

class _QuotationFormScreenState extends ConsumerState<QuotationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Client? _selectedClient;
  late TextEditingController _quotationNumberController;
  late List<LineItem> _items;
  DateTime? _date;
  late QuotationStatus _status;
  late TextEditingController _projectController;
  late TextEditingController _enquiryRefController;
  late TextEditingController _termsController;
  late TextEditingController _termsAndConditionsController;
  late TextEditingController _salesPersonController;
  bool _isVatApplicable = true;
  String _currency = 'AED';
  double _vatRate = 5.0;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedClient = widget.quotation?.client;
    _quotationNumberController = TextEditingController(
      text:
          widget.quotation?.quotationNumber ??
          'QTN-${DateTime.now().millisecondsSinceEpoch}',
    );
    _items = widget.quotation?.items.toList() ?? [];
    _date = widget.quotation?.date;
    _status = widget.quotation?.status ?? QuotationStatus.draft;
    _projectController = TextEditingController(text: widget.quotation?.project);
    _enquiryRefController = TextEditingController(
      text: widget.quotation?.enquiryRef,
    );
    _termsController = TextEditingController(text: widget.quotation?.terms);
    _termsAndConditionsController = TextEditingController(
      text: widget.quotation?.termsAndConditions,
    );
    _salesPersonController = TextEditingController(
      text: widget.quotation?.salesPerson,
    );
    _isVatApplicable = widget.quotation?.isVatApplicable ?? true;
    _currency = widget.quotation?.currency ?? 'AED';

    // Load Default VAT Rate from settings
    final profile = ref.read(businessProfileRepositoryProvider).getProfile();
    _vatRate = profile?.defaultVatRate ?? 5.0;
    // Editing: keep the rate the quotation was issued with, not today's default.
    final existing = widget.quotation;
    if (existing != null &&
        existing.isVatApplicable != false &&
        existing.subtotal > 0 &&
        existing.taxAmount > 0) {
      _vatRate = existing.taxAmount / existing.subtotal * 100;
    }
  }

  @override
  void dispose() {
    _quotationNumberController.dispose();
    _projectController.dispose();
    _enquiryRefController.dispose();
    _termsController.dispose();
    _termsAndConditionsController.dispose();
    _salesPersonController.dispose();

    super.dispose();
  }

  void _addItem() {
    setState(() {
      _dirty = true;
      _items.add(
        LineItem(description: '', quantity: 1, unitPrice: 0, total: 0),
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _dirty = true;
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, LineItem newItem) {
    setState(() {
      _dirty = true;
      _items[index] = newItem.copyWith(id: _items[index].id);
    });
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedClient == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a client')));
        return;
      }
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item')),
        );
        return;
      }

      final subtotal = _subtotal;
      final tax = _isVatApplicable ? subtotal * (_vatRate / 100) : 0.0;
      final total = subtotal + tax;

      final old = widget.quotation;
      final quotation = Quotation(
        id: old?.id ?? const Uuid().v4(),
        quotationNumber: _quotationNumberController.text,
        date: _date,
        validUntil: old?.validUntil,
        notes: old?.notes,
        isSynced: false,
        updatedAt: DateTime.now(),
        userId: old?.userId,
        client: _selectedClient!,
        items: _items,
        subtotal: subtotal,
        taxAmount: tax,
        discount: old?.discount ?? 0,
        total: total,
        status: _status,
        project: _projectController.text,
        enquiryRef: _enquiryRefController.text,
        terms: _termsController.text,
        termsAndConditions: _termsAndConditionsController.text,
        salesPerson: _salesPersonController.text,
        isVatApplicable: _isVatApplicable,
        currency: _currency,
      );

      if (_saving) return;
      setState(() => _saving = true);
      try {
        await ref.read(quotationRepositoryProvider).saveQuotation(quotation);
        if (!mounted) return;
        setState(() => _dirty = false);
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the quotation. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _convertToInvoice() async {
    if (_dirty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save your changes first, then convert to an invoice.'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convert to invoice?'),
        content: const Text(
          'This creates a draft invoice from this quotation. The quotation stays as it is.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Convert'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final invoice = widget.quotation!.toInvoice();
      await ref.read(invoiceRepositoryProvider).saveInvoice(invoice);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Converted to Invoice successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not convert. Please try again.')),
      );
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your changes to this quotation are not saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _dirty = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.pageWash,
        appBar: AppBar(
          title: Text(
            widget.quotation == null ? 'New Quotation' : 'Edit Quotation',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (widget.quotation != null &&
                widget.quotation!.status == QuotationStatus.accepted)
              IconButton(
                tooltip: 'Convert to Invoice',
                icon: const Icon(Icons.receipt_long_outlined),
                onPressed: _convertToInvoice,
              ),
            IconButton(
              tooltip: 'Preview PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () {
                if (widget.quotation != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuotationPdfPreviewScreen(
                        quotation: widget.quotation!,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please save the quotation first'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined, size: 20),
                label: const Text('Save'),
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
                onChanged: () {
                  if (!_dirty) setState(() => _dirty = true);
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 0,
                  ),
                  children: [
                    // Client Details Section
                    FormSection(
                      title: 'Client Selection',
                      icon: Icons.person_outline,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ClientSelector(
                                selectedClient: _selectedClient,
                                onChanged: (client) => setState(() {
                                  _selectedClient = client;
                                  _dirty = true;
                                }),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton.filledTonal(
                              tooltip: 'Add new client',
                              icon: const Icon(Icons.add),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ClientFormScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quotation Details Section
                    FormSection(
                      title: 'Quotation Info',
                      icon: Icons.info_outline,
                      children: [
                        TextFormField(
                          controller: _quotationNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Quotation Number',
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _currency,
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          items: ['AED', 'USD', 'EUR', 'GBP'].map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _currency = val;
                                _dirty = true;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _projectController,
                          decoration: const InputDecoration(
                            labelText: 'Project',
                            prefixIcon: Icon(Icons.work_outline),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _enquiryRefController,
                          decoration: const InputDecoration(
                            labelText: 'Enquiry Ref',
                            prefixIcon: Icon(Icons.bookmark_border),
                          ),
                        ),

                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _salesPersonController,
                          decoration: const InputDecoration(
                            labelText: 'Sales Person',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SwitchListTile(
                          title: const Text('VAT Applicable'),
                          value: _isVatApplicable,
                          onChanged: (val) {
                            setState(() {
                              _isVatApplicable = val;
                              _dirty = true;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<QuotationStatus>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.label_important_outline),
                          ),
                          items: QuotationStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(
                                status.name[0].toUpperCase() +
                                    status.name.substring(1),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _status = val;
                                _dirty = true;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _date ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() {
                                _date = date;
                                _dirty = true;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Quotation Date',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _date != null
                                  ? DateFormat.yMMMd().format(_date!)
                                  : 'Select Date (Optional)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Terms Section
                    FormSection(
                      title: 'Terms & Conditions',
                      icon: Icons.description_outlined,
                      children: [
                        TextFormField(
                          controller: _termsController,
                          decoration: const InputDecoration(
                            labelText: 'Terms',
                            hintText:
                                'Enter payment terms, delivery terms, etc.',
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _termsAndConditionsController,
                          decoration: const InputDecoration(
                            labelText: 'Terms & Conditions',
                            hintText: 'Enter quotation terms and conditions...',
                          ),
                          maxLines: 4,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Line Items Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ItemCard(
                          key: ValueKey(item.id),
                          item: item,
                          index: index,
                          onUpdate: (newItem) => _updateItem(index, newItem),
                          onRemove: () => _removeItem(index),
                          currency: _currency,
                        ),
                      );
                    }),

                    const SizedBox(height: 32),
                    // Totals Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
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
                          if (_isVatApplicable) ...[
                            FormTotalRow(
                              label: 'Tax (${_vatRate.toStringAsFixed(0)}%)',
                              value: _subtotal * (_vatRate / 100),
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
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(
                                  _isVatApplicable
                                      ? _subtotal * (1 + _vatRate / 100)
                                      : _subtotal,
                                  symbol: _currency,
                                ),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.primary,
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
}
