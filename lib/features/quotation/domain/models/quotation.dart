import 'package:hive/hive.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';

part 'quotation.g.dart';

@HiveType(typeId: 6)
enum QuotationStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  sent,
  @HiveField(2)
  accepted,
  @HiveField(3)
  rejected,
  @HiveField(4)
  expired,
}

@HiveType(typeId: 7)
class Quotation {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String quotationNumber;
  @HiveField(2)
  final DateTime date;
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
  final QuotationStatus status;
  @HiveField(11)
  final String? notes;
  @HiveField(12)
  final String? terms;
  @HiveField(13)
  final String? enquiryRef;
  @HiveField(14)
  final String? project;
  @HiveField(15)
  final String? termsAndConditions;
  @HiveField(16)
  final String? salesPerson;
  @HiveField(
    17,
  ) // Keeping original index to avoid conflict with @HiveField(15) for termsAndConditions
  final bool? isVatApplicable;
  @HiveField(18)
  final String? currency;
  @HiveField(19)
  final bool isSynced;
  @HiveField(20)
  final DateTime? updatedAt;
  @HiveField(21)
  final String? userId;

  Quotation({
    required this.id,
    required this.quotationNumber,
    required this.date,
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
    this.enquiryRef,
    this.project,
    this.termsAndConditions,
    this.salesPerson,
    this.isVatApplicable = true,
    this.currency = 'AED',
    this.isSynced = false,
    this.updatedAt,
    this.userId,
  });

  // Helper to convert to Invoice
  Invoice toInvoice({String? invoiceNumber}) {
    return Invoice(
      id: id, // Or generate new one
      invoiceNumber: invoiceNumber ?? 'INV-FROM-$quotationNumber',
      date: DateTime.now(),
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
      'quotationNumber': quotationNumber,
      'date': date.toIso8601String(),
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
      'enquiryRef': enquiryRef,
      'project': project,
      'termsAndConditions': termsAndConditions,
      'salesPerson': salesPerson,
      'isVatApplicable': isVatApplicable,
      'currency': currency,
      'isSynced': isSynced,
      'updatedAt': updatedAt?.toIso8601String(),
      'user_id': userId,
      'client_id': client.id,
    };
  }

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['id'],
      quotationNumber: json['quotationNumber'],
      date: DateTime.parse(json['date']),
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
      status: QuotationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => QuotationStatus.draft,
      ),
      notes: json['notes'],
      terms: json['terms'],
      enquiryRef: json['enquiryRef'],
      project: json['project'],
      termsAndConditions: json['termsAndConditions'],
      salesPerson: json['salesPerson'],
      isVatApplicable: json['isVatApplicable'] ?? true,
      currency: json['currency'] ?? 'AED',
      isSynced: json['isSynced'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      userId: json['user_id'],
    );
  }
}
