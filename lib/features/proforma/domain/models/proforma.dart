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
  final ProformaStatus status;
  @HiveField(11)
  final String? notes;
  @HiveField(12)
  final String? terms;
  @HiveField(13)
  final String? termsAndConditions;

  ProformaInvoice({
    required this.id,
    required this.proformaNumber,
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
    this.termsAndConditions,
  });

  // Helper to convert to Invoice
  Invoice toInvoice({String? invoiceNumber}) {
    return Invoice(
      id: id, // Or generate new one, usually new
      invoiceNumber: invoiceNumber ?? 'INV-FROM-$proformaNumber',
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
    );
  }
}
