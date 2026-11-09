import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';
import 'package:flutter_invoice_app/features/product/domain/models/product.dart';
import 'package:flutter_invoice_app/features/product/presentation/screens/product_form_screen.dart';

class ProductSelector extends ConsumerWidget {
  final ValueChanged<Product?> onChanged;
  final Product? selectedProduct;

  const ProductSelector({
    super.key,
    required this.onChanged,
    this.selectedProduct,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency =
        ref.watch(settingsRepositoryProvider).getBusinessProfile()?.currency ??
        'AED';
    return ValueListenableBuilder(
      valueListenable: Hive.box<Product>('products').listenable(),
      builder: (context, Box<Product> box, _) {
        final products = box.values.toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            return Autocomplete<Product>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final query = textEditingValue.text.trim().toLowerCase();
                if (query.isEmpty) {
                  // Show saved items on focus so nothing has to be remembered.
                  return products;
                }
                return products.where((Product product) {
                  return product.name.toLowerCase().contains(query) ||
                      (product.sku?.toLowerCase().contains(query) ?? false);
                });
              },
              displayStringForOption: (Product option) => option.name,
              onSelected: (Product selection) {
                onChanged(selection);
              },
              fieldViewBuilder:
                  (
                    BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    // Clear the controller if no product is selected (optional, or handle initial value)
                    // Note: We don't have an easy way to set initial value here unless we pass it in.
                    // But for "Add Item", it usually starts empty.

                    return TextFormField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Select Product/Service',
                        hintText: 'Type to search...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Add a new product/service',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProductFormScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
              optionsViewBuilder:
                  (
                    BuildContext context,
                    AutocompleteOnSelected<Product> onSelected,
                    Iterable<Product> options,
                  ) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        color: Theme.of(context).cardColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        child: Container(
                          width: constraints.maxWidth,
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Product option = options.elementAt(index);
                              return ListTile(
                                title: Text(
                                  option.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                subtitle: Text(
                                  CurrencyFormatter.format(
                                    option.unitPrice,
                                    symbol: currency,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                onTap: () {
                                  onSelected(option);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
            );
          },
        );
      },
    );
  }
}
