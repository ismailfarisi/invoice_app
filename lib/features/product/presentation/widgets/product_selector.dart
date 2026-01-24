import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/features/product/domain/models/product.dart';
import 'package:flutter_invoice_app/features/product/presentation/screens/product_form_screen.dart';

class ProductSelector extends StatelessWidget {
  final ValueChanged<Product?> onChanged;

  const ProductSelector({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Product>('products').listenable(),
      builder: (context, Box<Product> box, _) {
        final products = box.values.toList();

        return DropdownButtonFormField<Product>(
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Select Product/Service',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                );
              },
            ),
          ),
          items: products.map((product) {
            return DropdownMenuItem(
              value: product,
              child: Text(
                '${product.name} (\$${product.unitPrice})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
