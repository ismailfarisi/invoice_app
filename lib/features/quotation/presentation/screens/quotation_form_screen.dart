import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/features/quotation/data/quotation_repository.dart';
import 'package:flutter_invoice_app/features/invoice/data/invoice_repository.dart';
import 'package:flutter_invoice_app/features/quotation/presentation/screens/quotation_pdf_preview_screen.dart';
import 'package:flutter_invoice_app/features/client/presentation/widgets/client_selector.dart';
import 'package:flutter_invoice_app/features/client/presentation/screens/client_form_screen.dart';
import 'package:flutter_invoice_app/features/product/presentation/widgets/product_selector.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
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
  late DateTime _date;
  late QuotationStatus _status;
  late TextEditingController _projectController;
  late TextEditingController _enquiryRefController;
  late TextEditingController _termsController;
  late TextEditingController _termsAndConditionsController;
  late TextEditingController _salesPersonController;
  bool _isVatApplicable = true;

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
    _date = widget.quotation?.date ?? DateTime.now();
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
      _items.add(
        LineItem(description: '', quantity: 1, unitPrice: 0, total: 0),
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, LineItem newItem) {
    setState(() {
      _items[index] = newItem;
    });
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item')),
        );
        return;
      }

      final subtotal = _subtotal;
      final tax = _isVatApplicable ? subtotal * 0.1 : 0.0;
      final total = subtotal + tax;

      final quotation = Quotation(
        id: widget.quotation?.id ?? const Uuid().v4(),
        quotationNumber: _quotationNumberController.text,
        date: _date,
        client: _selectedClient!,
        items: _items,
        subtotal: subtotal,
        taxAmount: tax,
        discount: 0,
        total: total,
        status: _status,
        project: _projectController.text,
        enquiryRef: _enquiryRefController.text,
        terms: _termsController.text,
        termsAndConditions: _termsAndConditionsController.text,
        salesPerson: _salesPersonController.text,
        isVatApplicable: _isVatApplicable,
      );

      await ref.read(quotationRepositoryProvider).saveQuotation(quotation);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _convertToInvoice() async {
    final invoice = widget.quotation!.toInvoice();
    await ref.read(invoiceRepositoryProvider).saveInvoice(invoice);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Converted to Invoice successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {
              if (widget.quotation != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        QuotationPdfPreviewScreen(quotation: widget.quotation!),
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
              onPressed: _save,
              icon: const Icon(Icons.save_outlined, size: 20),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Client Details Section
            _FormSection(
              title: 'Client Selection',
              icon: Icons.person_outline,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClientSelector(
                        selectedClient: _selectedClient,
                        onChanged: (client) =>
                            setState(() => _selectedClient = client),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
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
            _FormSection(
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
                      child: Text(status.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Terms Section
            _FormSection(
              title: 'Terms & Conditions',
              icon: Icons.description_outlined,
              children: [
                TextFormField(
                  controller: _termsController,
                  decoration: const InputDecoration(
                    labelText: 'Terms',
                    hintText: 'Enter payment terms, delivery terms, etc.',
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                child: _ItemCard(
                  item: item,
                  index: index,
                  onUpdate: (newItem) => _updateItem(index, newItem),
                  onRemove: () => _removeItem(index),
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
                  _TotalRow(label: 'Subtotal', value: _subtotal),
                  const SizedBox(height: 8),
                  _TotalRow(label: 'Subtotal', value: _subtotal),
                  const SizedBox(height: 8),
                  if (_isVatApplicable) ...[
                    _TotalRow(label: 'Tax (10%)', value: _subtotal * 0.1),
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
                          _isVatApplicable ? _subtotal * 1.1 : _subtotal,
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final LineItem item;
  final int index;
  final ValueChanged<LineItem> onUpdate;
  final VoidCallback onRemove;

  const _ItemCard({
    required this.item,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ProductSelector(
                  onChanged: (product) {
                    if (product != null) {
                      onUpdate(
                        LineItem(
                          description: product.name,
                          quantity: item.quantity,
                          unitPrice: product.unitPrice,
                          total: item.quantity * product.unitPrice,
                        ),
                      );
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: item.description,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (val) => onUpdate(
              LineItem(
                description: val,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                total: item.total,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  decoration: const InputDecoration(labelText: 'Qty'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final qty = double.tryParse(val) ?? 0;
                    onUpdate(
                      LineItem(
                        description: item.description,
                        quantity: qty,
                        unitPrice: item.unitPrice,
                        total: qty * item.unitPrice,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: item.unitPrice.toString(),
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final price = double.tryParse(val) ?? 0;
                    onUpdate(
                      LineItem(
                        description: item.description,
                        quantity: item.quantity,
                        unitPrice: price,
                        total: item.quantity * price,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        item.total.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;

  const _TotalRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          CurrencyFormatter.format(value),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
