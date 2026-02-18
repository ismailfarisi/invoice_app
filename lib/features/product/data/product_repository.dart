import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/features/product/domain/models/product.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());

class ProductRepository {
  final Box<Product> _box = Hive.box<Product>('products');

  ValueListenable<Box<Product>> get listenable => _box.listenable();

  List<Product> getAllProducts() {
    return _box.values.toList();
  }

  Product? getProduct(String id) {
    return _box.get(id);
  }

  Future<void> saveProduct(Product product) async {
    await _box.put(product.id, product);
  }

  Future<void> deleteProduct(String id) async {
    await _box.delete(id);
  }
}
