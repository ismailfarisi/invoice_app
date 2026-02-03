import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'invoice.g.dart';

@HiveType(typeId: 0)
class Invoice {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String invoiceNumber; // e.g. INV-001
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final DateTime? dueDate;
  @HiveField(4)
  final Client client;
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
  final InvoiceStatus status;
  @HiveField(11)
  final String? notes;
  @HiveField(12)
  final String? terms;
  @HiveField(13)
  final String? termsAndConditions;
  @HiveField(14)
  final String? salesPerson;
  @HiveField(15)
  final bool? isVatApplicable;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    this.dueDate,
    required this.client,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.discount,
    required this.total,
    required this.status,
    this.notes,
    this.terms,
    this.termsAndConditions,
    this.salesPerson,
    this.isVatApplicable = true,
  });
}

@HiveType(typeId: 1)
enum InvoiceStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  sent,
  @HiveField(2)
  paid,
  @HiveField(3)
  overdue,
  @HiveField(4)
  cancelled,
}

@HiveType(typeId: 2)
class Client {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name; // Company Name
  @HiveField(2)
  final String email;
  @HiveField(3)
  final String? address;
  @HiveField(4)
  final String? phone;
  @HiveField(5)
  final String? contactPerson;
  @HiveField(6)
  final String? taxId;

  Client({
    required this.id,
    required this.name,
    required this.email,
    this.address,
    this.phone,
    this.contactPerson,
    this.taxId,
  });
}

@HiveType(typeId: 3)
class LineItem {
  final String id;
  @HiveField(0)
  final String description;
  @HiveField(1)
  final double quantity;
  @HiveField(2)
  final double unitPrice;
  @HiveField(3)
  final double total;
  @HiveField(4)
  final String? unit;

  LineItem({
    String? id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.unit,
  }) : id = id ?? const Uuid().v4();

  LineItem copyWith({
    String? id,
    String? description,
    double? quantity,
    double? unitPrice,
    double? total,
    String? unit,
  }) {
    return LineItem(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      unit: unit ?? this.unit,
    );
  }
}
