import 'package:flutter/material.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/product/presentation/widgets/product_selector.dart';

class ItemCard extends StatelessWidget {
  final LineItem item;
  final int index;
  final ValueChanged<LineItem> onUpdate;
  final VoidCallback onRemove;

  const ItemCard({
    super.key,
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
        color:
            Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.2),
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
                          unit: product.unit ?? item.unit,
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
                unit: item.unit,
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
                        unit: item.unit,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item.unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  onChanged: (val) {
                    onUpdate(
                      LineItem(
                        description: item.description,
                        quantity: item.quantity,
                        unitPrice: item.unitPrice,
                        total: item.total,
                        unit: val,
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
                        unit: item.unit,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  item.total.toStringAsFixed(2),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
