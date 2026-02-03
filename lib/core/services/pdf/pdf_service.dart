import 'dart:typed_data';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';
import 'package:flutter_invoice_app/features/proforma/domain/models/proforma.dart';
import 'generators/invoice_pdf_generator.dart';
import 'generators/quotation_pdf_generator.dart';
import 'generators/lpo_pdf_generator.dart';
import 'generators/proforma_pdf_generator.dart';
import 'generators/letterhead_pdf_generator.dart';
import 'generators/delivery_note_pdf_generator.dart';

class PdfService {
  Future<Uint8List> generateInvoice(
    Invoice invoice, {
    BusinessProfile? profile,
  }) {
    return InvoicePdfGenerator.generate(invoice, profile: profile);
  }

  Future<Uint8List> generateQuotation(
    Quotation quotation, {
    BusinessProfile? profile,
  }) {
    return QuotationPdfGenerator.generate(quotation, profile: profile);
  }

  Future<Uint8List> generateLpo(Lpo lpo, {BusinessProfile? profile}) {
    return LpoPdfGenerator.generate(lpo, profile: profile);
  }

  Future<Uint8List> generateProforma(
    ProformaInvoice proforma, {
    BusinessProfile? profile,
  }) {
    return ProformaPdfGenerator.generate(proforma, profile: profile);
  }

  Future<Uint8List> generateLetterHead({
    BusinessProfile? profile,
    String? content,
  }) {
    return LetterHeadPdfGenerator.generate(profile: profile, content: content);
  }

  Future<Uint8List> generateDeliveryNote(
    Invoice invoice, {
    BusinessProfile? profile,
  }) {
    return DeliveryNotePdfGenerator.generate(invoice, profile: profile);
  }
}
