import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 4)
class Product {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final double unitPrice;
  @HiveField(4)
  final String? sku;
  @HiveField(5)
  final double stockQuantity; // For basic inventory tracking

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.unitPrice,
    this.sku,
    this.stockQuantity = 0,
  });
}
