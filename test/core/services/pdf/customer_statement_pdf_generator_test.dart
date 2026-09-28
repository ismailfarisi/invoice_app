import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_invoice_app/core/services/pdf/pdf_service.dart';
import 'package:flutter_invoice_app/core/services/pdf/generators/customer_statement_pdf_generator.dart';
import 'package:flutter_invoice_app/features/client/domain/models/customer_statement.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';

void main() {
  final testClient = Client(
    id: 'client-1',
    name: 'Acme Corp',
    email: 'billing@acme.com',
    phone: '+971501234567',
    address: 'Dubai, UAE',
    taxId: '100200300400003',
    contactPerson: 'John Smith',
  );

  final testProfile = BusinessProfile(
    companyName: 'My Invoicing Co LLC',
    email: 'info@myinvoicing.com',
    phone: '+9714000000',
    address: 'Business Bay, Dubai',
    taxId: '100999888777003',
    currency: 'AED',
    bankName: 'Emirates NBD',
    bankAccountName: 'My Invoicing Co LLC',
    bankAccountNumber: '123456789',
    bankIban: 'AE123456789012345678901',
    bankSwift: 'EBILAEADXXX',
  );

  Invoice createInvoice({
    required String id,
    required String number,
    required DateTime date,
    required double total,
    required InvoiceStatus status,
  }) {
    return Invoice(
      id: id,
      invoiceNumber: number,
      client: testClient,
      date: date,
      dueDate: date.add(const Duration(days: 30)),
      items: [],
      subtotal: total,
      taxAmount: 0.0,
      discount: 0.0,
      total: total,
      status: status,
      currency: 'AED',
    );
  }

  group('CustomerStatementPdfGenerator', () {
    test('generates valid PDF bytes for statement with items and profile', () async {
      final invoices = [
        createInvoice(
          id: 'inv-1',
          number: 'INV-001',
          date: DateTime(2026, 1, 15),
          total: 1500.0,
          status: InvoiceStatus.paid,
        ),
        createInvoice(
          id: 'inv-2',
          number: 'INV-002',
          date: DateTime(2026, 2, 20),
          total: 2500.0,
          status: InvoiceStatus.sent,
        ),
      ];

      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: invoices,
        fromDate: DateTime(2026, 1, 1),
        toDate: DateTime(2026, 3, 31),
        statementDate: DateTime(2026, 3, 28),
      );

      final pdfBytes = await CustomerStatementPdfGenerator.generate(
        statement,
        profile: testProfile,
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.isNotEmpty, isTrue);

      // Verify PDF header magic bytes "%PDF-"
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generates valid PDF for empty statement (empty state handling)', () async {
      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: [],
        statementDate: DateTime(2026, 3, 28),
      );

      final pdfBytes = await CustomerStatementPdfGenerator.generate(
        statement,
        profile: testProfile,
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.isNotEmpty, isTrue);
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generates valid PDF when profile is null or has no bank details', () async {
      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: [],
        statementDate: DateTime(2026, 3, 28),
      );

      // Without profile
      final bytesNoProfile = await CustomerStatementPdfGenerator.generate(
        statement,
        profile: null,
      );
      expect(bytesNoProfile.isNotEmpty, isTrue);

      // Profile without bank details
      final profileNoBank = BusinessProfile(companyName: 'Minimal Co');
      final bytesNoBank = await CustomerStatementPdfGenerator.generate(
        statement,
        profile: profileNoBank,
      );
      expect(bytesNoBank.isNotEmpty, isTrue);

      // Profile with unstructured free-text bankDetails
      final profileFreeTextBank = BusinessProfile(
        companyName: 'Text Co',
        bankDetails: 'Please wire to Commercial Bank, Acc: 987654321',
      );
      final bytesTextBank = await CustomerStatementPdfGenerator.generate(
        statement,
        profile: profileFreeTextBank,
      );
      expect(bytesTextBank.isNotEmpty, isTrue);
    });

    test('generates valid PDF with various date filter ranges', () async {
      // From date only
      final stmtFromOnly = CustomerStatement(
        client: testClient,
        items: [],
        totalInvoiced: 0,
        totalPaid: 0,
        totalBalanceDue: 0,
        statementDate: DateTime(2026, 3, 28),
        fromDate: DateTime(2026, 1, 1),
      );
      final bytesFrom = await CustomerStatementPdfGenerator.generate(stmtFromOnly);
      expect(bytesFrom.isNotEmpty, isTrue);

      // To date only
      final stmtToOnly = CustomerStatement(
        client: testClient,
        items: [],
        totalInvoiced: 0,
        totalPaid: 0,
        totalBalanceDue: 0,
        statementDate: DateTime(2026, 3, 28),
        toDate: DateTime(2026, 3, 31),
      );
      final bytesTo = await CustomerStatementPdfGenerator.generate(stmtToOnly);
      expect(bytesTo.isNotEmpty, isTrue);
    });

    test('PdfService delegates to CustomerStatementPdfGenerator correctly', () async {
      final pdfService = PdfService();
      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: [],
        statementDate: DateTime(2026, 3, 28),
      );

      final pdfBytes = await pdfService.generateCustomerStatement(
        statement,
        profile: testProfile,
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.isNotEmpty, isTrue);
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });
  });
}
