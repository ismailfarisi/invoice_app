import 'package:flutter/material.dart';
import 'package:flutter_invoice_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/product/domain/models/product.dart';
import 'package:flutter_invoice_app/features/product/data/product_repository.dart';
import 'package:flutter_invoice_app/core/presentation/widgets/form/form_section.dart';
import 'package:uuid/uuid.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _skuController;
  late TextEditingController _descriptionController;
  late TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product == null
          ? ''
          : widget.product!.unitPrice.toStringAsFixed(2),
    );
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _unitController = TextEditingController(text: widget.product?.unit ?? '');
  }

  bool _saving = false;

  double? _parsePrice(String? text) =>
      double.tryParse((text ?? '').trim().replaceAll(',', ''));

  String? _orNull(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final existing = widget.product;
    final product = Product(
      id: existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      unitPrice: _parsePrice(_priceController.text) ?? 0,
      sku: _orNull(_skuController),
      description: _orNull(_descriptionController),
      stockQuantity: existing?.stockQuantity ?? 0,
      unit: _orNull(_unitController),
      // Carry over fields the form doesn't show.
      userId: existing?.userId,
      updatedAt: existing?.updatedAt,
    );

    setState(() => _saving = true);
    try {
      await ref.read(productRepositoryProvider).saveProduct(product);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Failed to save product: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the item. Try again.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.pageWash,
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'New Product' : 'Edit Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
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
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 0,
                ),
                children: [
                  FormSection(
                    title: 'Item Details',
                    icon: Icons.inventory_2_outlined,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.drive_file_rename_outline),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Enter a name'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Unit Price',
                          prefixIcon: Icon(Icons.sell_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter a price';
                          }
                          final price = _parsePrice(val);
                          if (price == null || price.isNaN || price.isInfinite) {
                            return 'Enter a number, like 150 or 99.50';
                          }
                          if (price < 0) return 'Price cannot be negative';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'SKU (Optional)',
                          prefixIcon: Icon(Icons.tag),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit (Optional)',
                          prefixIcon: Icon(Icons.ad_units_outlined),
                          hintText: 'e.g. PCS, NOS, KG',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
