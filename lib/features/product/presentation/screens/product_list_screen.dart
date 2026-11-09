import 'package:flutter/material.dart';
import 'package:flutter_invoice_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/features/product/domain/models/product.dart';
import 'package:flutter_invoice_app/features/product/presentation/screens/product_form_screen.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';

class ProductListScreen extends ConsumerWidget {
  /// When true the screen is used as a picker: tapping a card returns the
  /// product to the caller and delete is hidden.
  final bool isSelecting;

  const ProductListScreen({super.key, this.isSelecting = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency =
        ref.watch(settingsRepositoryProvider).getBusinessProfile()?.currency ??
        'AED';
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.pageWash,
      appBar: AppBar(
        title: const Text(
          'Products & Services',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Product>('products').listenable(),
        builder: (context, Box<Product> box, _) {
          if (box.values.isEmpty) {
            final scheme = Theme.of(context).colorScheme;
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: scheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No products/services yet',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save what you sell with its price, then add it to a document in one tap.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final products = box.values.toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ProductCard(
                  product: product,
                  isSelecting: isSelecting,
                  currency: currency,
                  onDelete: () => box.delete(product.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
        },
        label: const Text(
          'Add Item',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isSelecting;
  final String currency;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.isSelecting,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sku = product.sku?.trim() ?? '';
    final unit = product.unit?.trim() ?? '';
    final meta = [
      if (sku.isNotEmpty) sku,
      if (unit.isNotEmpty) 'per $unit',
    ].join(' · ');

    return Material(
      color: Theme.of(context).cardTheme.color ?? scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (isSelecting) {
            Navigator.pop(context, product);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductFormScreen(product: product),
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, isSelecting ? 20 : 8, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.inventory_2_outlined, color: scheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    CurrencyFormatter.format(
                      product.unitPrice,
                      symbol: currency,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (!isSelecting)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  tooltip: 'Delete item',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Delete Item'),
                        content: Text(
                          'Delete ${product.name}? Documents that already use it are not changed.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.error,
                              foregroundColor: scheme.onError,
                            ),
                            onPressed: () {
                              onDelete();
                              Navigator.pop(dialogContext);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
