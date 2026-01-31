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
    );
  }
}
