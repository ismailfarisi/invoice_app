import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/proforma/domain/models/proforma.dart';
import 'package:flutter_invoice_app/features/proforma/presentation/providers/proforma_provider.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart'; // For LineItem reuse
import 'package:flutter_invoice_app/features/client/presentation/widgets/client_selector.dart';
import 'package:flutter_invoice_app/features/client/presentation/screens/client_form_screen.dart';
import 'package:flutter_invoice_app/core/presentation/widgets/item_card.dart';
import 'package:flutter_invoice_app/core/presentation/widgets/form/form_section.dart';
import 'package:flutter_invoice_app/core/presentation/widgets/form/form_total_row.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_invoice_app/features/proforma/presentation/screens/proforma_pdf_preview_screen.dart';

class ProformaFormScreen extends ConsumerStatefulWidget {
  final ProformaInvoice? proforma;
  const ProformaFormScreen({super.key, this.proforma});

  @override
  ConsumerState<ProformaFormScreen> createState() => _ProformaFormScreenState();
}

class _ProformaFormScreenState extends ConsumerState<ProformaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Client? _selectedClient;
  late TextEditingController _proformaNumberController;
  late List<LineItem> _items;
  late DateTime _date;
  late ProformaStatus _status;
  late TextEditingController _termsAndConditionsController;
  late TextEditingController _salesPersonController;
  bool _isVatApplicable = true;

  @override
  void initState() {
    super.initState();
    _selectedClient = widget.proforma?.client;
    _proformaNumberController = TextEditingController(
      text:
          widget.proforma?.proformaNumber ??
          'PF-${DateTime.now().millisecondsSinceEpoch}',
    );
    _items = widget.proforma?.items.toList() ?? [];
    _date = widget.proforma?.date ?? DateTime.now();
    _status = widget.proforma?.status ?? ProformaStatus.draft;
    _termsAndConditionsController = TextEditingController(
      text: widget.proforma?.termsAndConditions,
    );
    _salesPersonController = TextEditingController(
      text: widget.proforma?.salesPerson,
    );
    _isVatApplicable = widget.proforma?.isVatApplicable ?? true;
  }

  @override
  void dispose() {
    _proformaNumberController.dispose();

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
      final tax = _isVatApplicable ? subtotal * 0.05 : 0.0;
      final total = subtotal + tax;

      final proforma = ProformaInvoice(
        id: widget.proforma?.id ?? const Uuid().v4(),
        proformaNumber: _proformaNumberController.text,
        date: _date,
        client: _selectedClient!,
        items: _items,
        subtotal: subtotal,
        taxAmount: tax,
        discount: 0,
        total: total,

        status: _status,

        termsAndConditions: _termsAndConditionsController.text,
        salesPerson: _salesPersonController.text,
        isVatApplicable: _isVatApplicable,
      );

      await ref.read(proformaListProvider.notifier).saveProforma(proforma);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: Text(
          widget.proforma == null ? 'New Proforma Invoice' : 'Edit Proforma',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.proforma != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () {
                if (widget.proforma != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProformaPdfPreviewScreen(proforma: widget.proforma!),
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
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
                              onChanged: (client) {
                                setState(() {
                                  _selectedClient = client;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ClientFormScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Proforma Details Section
                  FormSection(
                    title: 'Proforma Info',
                    icon: Icons.info_outline,
                    children: [
                      TextFormField(
                        controller: _proformaNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Proforma Number',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
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
                      DropdownButtonFormField<ProformaStatus>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.label_important_outline),
                        ),
                        items: ProformaStatus.values.map((status) {
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
                  const SizedBox(height: 32),

                  // Terms and Conditions Section
                  FormSection(
                    title: 'Terms & Conditions',
                    icon: Icons.description_outlined,
                    children: [
                      TextFormField(
                        controller: _termsAndConditionsController,
                        decoration: const InputDecoration(
                          labelText: 'Terms & Conditions',
                          hintText: 'Enter proforma terms and conditions...',
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
                        FormTotalRow(label: 'Subtotal', value: _subtotal),
                        const SizedBox(height: 8),
                        FormTotalRow(label: 'Subtotal', value: _subtotal),
                        const SizedBox(height: 8),
                        if (_isVatApplicable) ...[
                          FormTotalRow(
                            label: 'Tax (5%)',
                            value: _subtotal * 0.05,
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
                                _isVatApplicable ? _subtotal * 1.05 : _subtotal,
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
          ),
        ),
      ),
    );
  }
}
