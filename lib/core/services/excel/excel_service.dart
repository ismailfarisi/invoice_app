import 'dart:typed_data';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:flutter_invoice_app/features/client/domain/models/customer_statement.dart';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';
import 'package:flutter_invoice_app/features/proforma/domain/models/proforma.dart';
import 'generators/customer_statement_excel_generator.dart';
import 'generators/invoice_excel_generator.dart';
import 'generators/quotation_excel_generator.dart';
import 'generators/lpo_excel_generator.dart';
import 'generators/proforma_excel_generator.dart';
import 'generators/credit_note_excel_generator.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/models/credit_note.dart';

class ExcelService {
  Future<Uint8List?> generateCreditNote(
    CreditNote note, {
    BusinessProfile? profile,
  }) {
    return CreditNoteExcelGenerator.generate(note, profile: profile);
  }

  Future<Uint8List?> generateInvoice(
    Invoice invoice, {
    BusinessProfile? profile,
  }) {
    return InvoiceExcelGenerator.generate(invoice, profile: profile);
  }

  Future<Uint8List?> generateQuotation(
    Quotation quotation, {
    BusinessProfile? profile,
  }) {
    return QuotationExcelGenerator.generate(quotation, profile: profile);
  }

  Future<Uint8List?> generateLpo(Lpo lpo, {BusinessProfile? profile}) {
    return LpoExcelGenerator.generate(lpo, profile: profile);
  }

  Future<Uint8List?> generateProforma(
    ProformaInvoice proforma, {
    BusinessProfile? profile,
  }) {
    return ProformaExcelGenerator.generate(proforma, profile: profile);
  }

  Future<Uint8List?> generateCustomerStatement(
    CustomerStatement statement, {
    BusinessProfile? profile,
  }) {
    return CustomerStatementExcelGenerator.generate(statement, profile: profile);
  }
}
