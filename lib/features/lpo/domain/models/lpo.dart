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
  @HiveField(14)
  final String? salesPerson;
  @HiveField(15)
  final bool? isVatApplicable;
  @HiveField(16)
  final String? currency;
  @HiveField(17)
  final String? placeOfSupply;
  @HiveField(18)
  final String? paymentTerms;
  @HiveField(19)
  final String? otherReference;

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
    this.salesPerson,
    this.isVatApplicable = true,
    this.currency = 'AED',
    this.placeOfSupply,
    this.paymentTerms,
    this.otherReference,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lpoNumber': lpoNumber,
      'date': date.toIso8601String(),
      'expectedDeliveryDate': expectedDeliveryDate?.toIso8601String(),
      'vendor': vendor.toJson(),
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
      'paymentTerms': paymentTerms,
      'otherReference': otherReference,
    };
  }

  factory Lpo.fromJson(Map<String, dynamic> json) {
    return Lpo(
      id: json['id'],
      lpoNumber: json['lpoNumber'],
      date: DateTime.parse(json['date']),
      expectedDeliveryDate: json['expectedDeliveryDate'] != null
          ? DateTime.parse(json['expectedDeliveryDate'])
          : null,
      vendor: Client.fromJson(Map<String, dynamic>.from(json['vendor'])),
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
      status: LpoStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LpoStatus.draft,
      ),
      notes: json['notes'],
      terms: json['terms'],
      termsAndConditions: json['termsAndConditions'],
      salesPerson: json['salesPerson'],
      isVatApplicable: json['isVatApplicable'] ?? true,
      currency: json['currency'] ?? 'AED',
      placeOfSupply: json['placeOfSupply'],
      paymentTerms: json['paymentTerms'],
      otherReference: json['otherReference'],
    );
  }
}
