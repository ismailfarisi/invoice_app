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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unitPrice': unitPrice,
      'sku': sku,
      'stockQuantity': stockQuantity,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      sku: json['sku'],
      stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0,
    );
  }
}
