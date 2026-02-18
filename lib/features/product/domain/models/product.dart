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
  @HiveField(6)
  final String? unit;
  @HiveField(7)
  final bool isSynced;
  @HiveField(8)
  final DateTime? updatedAt;
  @HiveField(9)
  final String? userId;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.unitPrice,
    this.sku,
    this.stockQuantity = 0,
    this.unit,
    this.isSynced = false,
    this.updatedAt,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unitPrice': unitPrice,
      'sku': sku,
      'stockQuantity': stockQuantity,
      'unit': unit,
      'isSynced': isSynced,
      'updatedAt': updatedAt?.toIso8601String(),
      'user_id': userId,
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
      unit: json['unit'],
      isSynced: json['isSynced'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      userId: json['user_id'],
    );
  }
}
