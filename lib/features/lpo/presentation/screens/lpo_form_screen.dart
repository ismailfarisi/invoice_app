import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';
import 'package:flutter_invoice_app/features/lpo/presentation/providers/lpo_provider.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/client/presentation/widgets/client_selector.dart';
import 'package:flutter_invoice_app/features/client/presentation/screens/client_form_screen.dart';
import 'package:flutter_invoice_app/core/presentation/widgets/item_card.dart';
import 'package:flutter_invoice_app/core/presentation/widgets/form/form_section.dart';
import 'package:flutter_invoice_app/core/presentation/widgets/form/form_total_row.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_invoice_app/features/lpo/presentation/screens/lpo_pdf_preview_screen.dart';

class LpoFormScreen extends ConsumerStatefulWidget {
  final Lpo? lpo;
  const LpoFormScreen({super.key, this.lpo});

  @override
  ConsumerState<LpoFormScreen> createState() => _LpoFormScreenState();
}

class _LpoFormScreenState extends ConsumerState<LpoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Client? _selectedVendor;
  late TextEditingController _lpoNumberController;
  late List<LineItem> _items;
  late DateTime _date;
  late LpoStatus _status;
  late TextEditingController _termsAndConditionsController;
  late TextEditingController _salesPersonController;
  bool _isVatApplicable = true;

  @override
  void initState() {
    super.initState();
    _selectedVendor = widget.lpo?.vendor;
    _lpoNumberController = TextEditingController(
      text:
          widget.lpo?.lpoNumber ??
          'LPO-${DateTime.now().millisecondsSinceEpoch}',
    );
    _items = widget.lpo?.items.toList() ?? [];
    _date = widget.lpo?.date ?? DateTime.now();
    _status = widget.lpo?.status ?? LpoStatus.draft;
    _termsAndConditionsController = TextEditingController(
      text: widget.lpo?.termsAndConditions,
    );
    _salesPersonController = TextEditingController(
      text: widget.lpo?.salesPerson,
    );
    _isVatApplicable = widget.lpo?.isVatApplicable ?? true;
  }

  @override
  void dispose() {
    _lpoNumberController.dispose();

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
      if (_selectedVendor == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a vendor')));
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

      final lpo = Lpo(
        id: widget.lpo?.id ?? const Uuid().v4(),
        lpoNumber: _lpoNumberController.text,
        date: _date,
        vendor: _selectedVendor!,
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

      await ref.read(lpoListProvider.notifier).saveLpo(lpo);
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
          widget.lpo == null ? 'New Purchase Order' : 'Edit Purchase Order',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // PDF Preview Button Placeholder
          if (widget.lpo != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LpoPdfPreviewScreen(lpo: widget.lpo!),
                  ),
                );
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
                  // Vendor Details Section
                  FormSection(
                    title: 'Vendor Selection',
                    icon: Icons.store_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ClientSelector(
                              selectedClient: _selectedVendor,
                              onChanged: (client) {
                                setState(() {
                                  _selectedVendor = client;
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

                  // LPO Details Section
                  FormSection(
                    title: 'LPO Info',
                    icon: Icons.info_outline,
                    children: [
                      TextFormField(
                        controller: _lpoNumberController,
                        decoration: const InputDecoration(
                          labelText: 'LPO Number',
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
                      DropdownButtonFormField<LpoStatus>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.label_important_outline),
                        ),
                        items: LpoStatus.values.map((status) {
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
                          hintText:
                              'Enter purchase order terms and conditions...',
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
