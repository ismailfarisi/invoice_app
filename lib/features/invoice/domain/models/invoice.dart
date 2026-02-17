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
  @HiveField(16)
  final String? currency;
  @HiveField(17)
  final String? placeOfSupply;
  @HiveField(18)
  final String? deliveryNote;
  @HiveField(19)
  final String? paymentTerms;
  @HiveField(20)
  final String? supplierReference;
  @HiveField(21)
  final String? otherReference;
  @HiveField(22)
  final String? buyersOrderNumber;
  @HiveField(23)
  final DateTime? buyersOrderDate;
  @HiveField(24)
  final bool isSynced;
  @HiveField(25)
  final DateTime? updatedAt;
  @HiveField(26)
  final String? userId;

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
    this.currency = 'AED',
    this.placeOfSupply,
    this.deliveryNote,
    this.paymentTerms,
    this.supplierReference,
    this.otherReference,
    this.buyersOrderNumber,
    this.buyersOrderDate,
    this.isSynced = false,
    this.updatedAt,
    this.userId,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'client': client.toJson(),
      'items': items.map((x) => x.toJson()).toList(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'discount': discount,
      'total': total,
      'status': status.name,
      'notes': notes,
      'terms': terms,
      'termsAndConditions': termsAndConditions,
      'salesPerson': salesPerson,
      'isVatApplicable': isVatApplicable,
      'currency': currency,
      'placeOfSupply': placeOfSupply,
      'deliveryNote': deliveryNote,
      'paymentTerms': paymentTerms,
      'supplierReference': supplierReference,
      'otherReference': otherReference,
      'buyersOrderNumber': buyersOrderNumber,
      'buyersOrderDate': buyersOrderDate?.toIso8601String(),
      'isSynced': isSynced,
      'updatedAt': updatedAt?.toIso8601String(),
      'user_id': userId,
      'client_id': client.id, // For Supabase relation
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      invoiceNumber: json['invoiceNumber'],
      date: DateTime.parse(json['date']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      client: Client.fromJson(Map<String, dynamic>.from(json['client'])),
      items: List<LineItem>.from(
        json['items']?.map(
              (x) => LineItem.fromJson(Map<String, dynamic>.from(x)),
            ) ??
            [],
      ),
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      notes: json['notes'],
      terms: json['terms'],
      termsAndConditions: json['termsAndConditions'],
      salesPerson: json['salesPerson'],
      isVatApplicable: json['isVatApplicable'] ?? true,
      currency: json['currency'] ?? 'AED',
      placeOfSupply: json['placeOfSupply'],
      deliveryNote: json['deliveryNote'],
      paymentTerms: json['paymentTerms'],
      supplierReference: json['supplierReference'],
      otherReference: json['otherReference'],
      buyersOrderNumber: json['buyersOrderNumber'],
      buyersOrderDate: json['buyersOrderDate'] != null
          ? DateTime.parse(json['buyersOrderDate'])
          : null,
      isSynced: json['isSynced'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      userId: json['user_id'],
    );
  }
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

  @HiveField(7)
  final bool isSynced;
  @HiveField(8)
  final DateTime? updatedAt;
  @HiveField(9)
  final String? userId;

  Client({
    required this.id,
    required this.name,
    required this.email,
    this.address,
    this.phone,
    this.contactPerson,
    this.taxId,
    this.isSynced = false,
    this.updatedAt,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'address': address,
      'phone': phone,
      'contactPerson': contactPerson,
      'taxId': taxId,
      'isSynced': isSynced,
      'updatedAt': updatedAt?.toIso8601String(),
      'user_id': userId,
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      address: json['address'],
      phone: json['phone'],
      contactPerson: json['contactPerson'],
      taxId: json['taxId'],
      isSynced: json['isSynced'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      userId: json['user_id'],
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
      'unit': unit,
    };
  }

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      id: json['id'],
      description: json['description'],
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      unit: json['unit'],
    );
  }
}
