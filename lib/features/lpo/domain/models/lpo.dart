import 'package:hive/hive.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';

part 'lpo.g.dart';

@HiveType(typeId: 8)
enum LpoStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  sent,
  @HiveField(2)
  approved,
  @HiveField(3)
  rejected,
  @HiveField(4)
  completed,
}

@HiveType(typeId: 9)
class Lpo {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String lpoNumber;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final DateTime? expectedDeliveryDate;
  @HiveField(4)
  final Client vendor; // Reusing Client model for Vendor
  @HiveField(5)
  final List<LineItem> items;
  @HiveField(6)
  final double subtotal;
  @HiveField(7)
  final double taxAmount;
  @HiveField(8)
  final double discount;
  @HiveField(9)
  final double total;
  @HiveField(10)
  final LpoStatus status;
  @HiveField(11)
  final String? notes;
  @HiveField(12)
  final String? terms;
  @HiveField(13)
  final String? termsAndConditions;

  Lpo({
    required this.id,
    required this.lpoNumber,
    required this.date,
    this.expectedDeliveryDate,
    required this.vendor,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.discount,
    required this.total,
    required this.status,
    this.notes,
    this.terms,
    this.termsAndConditions,
  });
}
