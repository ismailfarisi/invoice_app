import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_invoice_app/core/services/excel/generators/credit_note_excel_generator.dart';
import 'package:flutter_invoice_app/core/services/excel/generators/customer_statement_excel_generator.dart';
import 'package:flutter_invoice_app/core/services/pdf/generators/credit_note_pdf_generator.dart';
import 'package:flutter_invoice_app/core/services/pdf/generators/customer_statement_pdf_generator.dart';
import 'package:flutter_invoice_app/features/client/domain/models/customer_statement.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/models/credit_note.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';

void main() {
  final client = Client(
    id: 'c1',
    name: 'Acme Corp',
    email: 'billing@acme.com',
    address: 'Dubai, UAE',
    taxId: '100200300400003',
  );

  final profile = BusinessProfile(
    companyName: 'My Invoicing Co LLC',
    email: 'info@myinvoicing.com',
    phone: '+9714000000',
    address: 'Business Bay, Dubai',
    taxId: '100999888777003',
    currency: 'AED',
  );

  CreditNote note({bool isVoided = false, bool isVat = true}) {
    return CreditNote(
      id: 'n1',
      creditNoteNumber: 'CN-0001',
      date: DateTime(2026, 3, 1),
      invoiceId: 'inv-1',
      invoiceNumber: 'INV-001',
      invoiceDate: DateTime(2026, 1, 10),
      client: client,
      items: [
        LineItem(
          description: 'Widget',
          quantity: 2.5,
          unitPrice: 100,
          total: 250,
        ),
      ],
      subtotal: 250,
      vatRate: isVat ? 5 : 0,
      taxAmount: isVat ? 12.5 : 0,
      total: isVat ? 262.5 : 250,
      reason: 'Goods returned',
      isVatApplicable: isVat,
      isVoided: isVoided,
    );
  }

  List<String> workbookText(List<int> bytes, String sheetName) {
    final sheet = Excel.decodeBytes(bytes)[sheetName];
    return [
      for (var r = 0; r < sheet.maxRows; r++)
        for (final cell in sheet.row(r))
          if (cell?.value != null) cell!.value.toString(),
    ];
  }

  group('CreditNotePdfGenerator', () {
    test('produces a PDF for a VAT credit note', () async {
      final bytes = await CreditNotePdfGenerator.generate(
        note(),
        profile: profile,
      );
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('produces a PDF without a profile, VAT or when void', () async {
      final bytes = await CreditNotePdfGenerator.generate(
        note(isVoided: true, isVat: false),
      );
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('CreditNoteExcelGenerator', () {
    test('writes the particulars of the credit note', () async {
      final bytes = await CreditNoteExcelGenerator.generate(
        note(),
        profile: profile,
      );

      final text = workbookText(bytes!, 'Credit Note');
      expect(text, contains('TAX CREDIT NOTE'));
      expect(text, contains('CN-0001'));
      expect(text, contains('INV-001'));
      expect(text, contains('Goods returned'));
      expect(text, contains('100999888777003'));
      expect(text, contains('100200300400003'));
      expect(text, contains('Widget'));
      expect(text, contains('VAT (5%)'));
      expect(text, contains('262.5'));
    });

    test('marks a voided credit note', () async {
      final bytes = await CreditNoteExcelGenerator.generate(
        note(isVoided: true),
      );

      expect(workbookText(bytes!, 'Credit Note'), contains('TAX CREDIT NOTE (VOID)'));
    });
  });

  group('customer statement with a credit note', () {
    final statement = CustomerStatement.fromInvoices(
      client: client,
      allInvoices: [
        Invoice(
          id: 'inv-1',
          invoiceNumber: 'INV-001',
          client: client,
          date: DateTime(2026, 1, 10),
          items: [],
          subtotal: 250,
          taxAmount: 12.5,
          discount: 0,
          total: 262.5,
          status: InvoiceStatus.paid,
        ),
      ],
      creditNotes: [note()],
      statementDate: DateTime(2026, 3, 28),
    );

    test('Excel shows the credit row and a credit balance', () async {
      final bytes = await CustomerStatementExcelGenerator.generate(statement);

      final text = workbookText(bytes!, 'Statement');
      expect(text, contains('CN-0001'));
      expect(text, contains('CREDIT NOTE'));
      expect(text, contains('Total Credited: 262.50 AED'));
      expect(text, contains('Credit Balance: 262.50 AED'));
    });

    test('PDF renders', () async {
      final bytes = await CustomerStatementPdfGenerator.generate(statement);
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });
}
