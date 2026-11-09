import 'package:hive/hive.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';

part 'credit_note.g.dart';

/// A tax credit note issued against an invoice.
///
/// Issued credit notes are never edited. A mistake is corrected by voiding the
/// note, which keeps its number on record and removes its effect on balances.
@HiveType(typeId: 12)
class CreditNote {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String creditNoteNumber; // e.g. CN-0001
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final String invoiceId;
  @HiveField(4)
  final String invoiceNumber;
  @HiveField(5)
  final DateTime? invoiceDate;
  @HiveField(6)
  final Client client;
  @HiveField(7)
  final List<LineItem> items;
  @HiveField(8)
  final double subtotal;
  @HiveField(9)
  final double vatRate;
  @HiveField(10)
  final double taxAmount;
  @HiveField(11)
  final double total;
  @HiveField(12)
  final String reason;
  @HiveField(13, defaultValue: true)
  final bool isVatApplicable;
  @HiveField(14, defaultValue: 'AED')
  final String currency;
  @HiveField(15)
  final String? placeOfSupply;
  @HiveField(16)
  final String? salesPerson;
  @HiveField(17, defaultValue: false)
  final bool isVoided;
  @HiveField(18, defaultValue: false)
  final bool isSynced;
  @HiveField(19)
  final DateTime? updatedAt;
  @HiveField(20)
  final String? userId;

  CreditNote({
    required this.id,
    required this.creditNoteNumber,
    required this.date,
    required this.invoiceId,
    required this.invoiceNumber,
    this.invoiceDate,
    required this.client,
    required this.items,
    required this.subtotal,
    required this.vatRate,
    required this.taxAmount,
    required this.total,
    required this.reason,
    this.isVatApplicable = true,
    this.currency = 'AED',
    this.placeOfSupply,
    this.salesPerson,
    this.isVoided = false,
    this.isSynced = false,
    this.updatedAt,
    this.userId,
  });

  CreditNote copyWith({
    bool? isVoided,
    bool? isSynced,
    DateTime? updatedAt,
    String? userId,
  }) {
    return CreditNote(
      id: id,
      creditNoteNumber: creditNoteNumber,
      date: date,
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      client: client,
      items: items,
      subtotal: subtotal,
      vatRate: vatRate,
      taxAmount: taxAmount,
      total: total,
      reason: reason,
      isVatApplicable: isVatApplicable,
      currency: currency,
      placeOfSupply: placeOfSupply,
      salesPerson: salesPerson,
      isVoided: isVoided ?? this.isVoided,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creditNoteNumber': creditNoteNumber,
      'date': date.toIso8601String(),
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate?.toIso8601String(),
      'client': client.toJson(),
      'items': items.map((x) => x.toJson()).toList(),
      'subtotal': subtotal,
      'vatRate': vatRate,
      'taxAmount': taxAmount,
      'total': total,
      'reason': reason,
      'isVatApplicable': isVatApplicable,
      'currency': currency,
      'placeOfSupply': placeOfSupply,
      'salesPerson': salesPerson,
      'isVoided': isVoided,
      'isSynced': isSynced,
      'updatedAt': updatedAt?.toIso8601String(),
      'user_id': userId,
      'client_id': client.id,
    };
  }

  factory CreditNote.fromJson(Map<String, dynamic> json) {
    return CreditNote(
      id: json['id'],
      creditNoteNumber: json['creditNoteNumber'],
      date: DateTime.parse(json['date']),
      invoiceId: json['invoiceId'],
      invoiceNumber: json['invoiceNumber'],
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.parse(json['invoiceDate'])
          : null,
      client: Client.fromJson(Map<String, dynamic>.from(json['client'])),
      items: List<LineItem>.from(
        (json['items'] as List? ?? []).map(
          (x) => LineItem.fromJson(Map<String, dynamic>.from(x)),
        ),
      ),
      subtotal: (json['subtotal'] as num).toDouble(),
      vatRate: (json['vatRate'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      reason: json['reason'],
      isVatApplicable: json['isVatApplicable'] ?? true,
      currency: json['currency'] ?? 'AED',
      placeOfSupply: json['placeOfSupply'],
      salesPerson: json['salesPerson'],
      isVoided: json['isVoided'] ?? false,
      isSynced: json['isSynced'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      userId: json['user_id'],
    );
  }
}
