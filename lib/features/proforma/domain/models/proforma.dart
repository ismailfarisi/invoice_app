import 'package:hive/hive.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';

part 'proforma.g.dart';

@HiveType(typeId: 10)
enum ProformaStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  sent,
  @HiveField(2)
  accepted,
  @HiveField(3)
  rejected,
  @HiveField(4)
  converted, // To Invoice
}

@HiveType(typeId: 11)
class ProformaInvoice {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String proformaNumber;
  @HiveField(2)
  final DateTime? date;
  @HiveField(3)
  final DateTime? validUntil;
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
  final ProformaStatus status;
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
  final String? project;
  @HiveField(18)
  final bool isSynced;
  @HiveField(19)
  final DateTime? updatedAt;
  @HiveField(20)
  final String? userId;

  ProformaInvoice({
    required this.id,
    required this.proformaNumber,
    this.date,
    this.validUntil,
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
    this.project,
    this.isSynced = false,
    this.updatedAt,
    this.userId,
  });

  // Helper to convert to Invoice
  Invoice toInvoice({String? invoiceNumber}) {
    return Invoice(
      id: id, // Or generate new one, usually new
      invoiceNumber: invoiceNumber ?? 'INV-FROM-$proformaNumber',
      date: date ?? DateTime.now(),
      client: client,
      items: items,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discount: discount,
      total: total,
      status: InvoiceStatus.draft,
      notes: notes,
      terms: terms,
      termsAndConditions: termsAndConditions,
      salesPerson: salesPerson,
      isVatApplicable: isVatApplicable,
      currency: currency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proformaNumber': proformaNumber,
      'date': date?.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
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
      'project': project,
      'isSynced': isSynced,
      'updatedAt': updatedAt?.toIso8601String(),
      'user_id': userId,
      'client_id': client.id,
    };
  }

  factory ProformaInvoice.fromJson(Map<String, dynamic> json) {
    return ProformaInvoice(
      id: json['id'],
      proformaNumber: json['proformaNumber'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'])
          : null,
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
      status: ProformaStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProformaStatus.draft,
      ),
      notes: json['notes'],
      terms: json['terms'],
      termsAndConditions: json['termsAndConditions'],
      salesPerson: json['salesPerson'],
      isVatApplicable: json['isVatApplicable'] ?? true,
      currency: json['currency'] ?? 'AED',
      project: json['project'],
      isSynced: json['isSynced'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      userId: json['user_id'],
    );
  }
}
