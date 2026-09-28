import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_invoice_app/core/services/excel/excel_service.dart';
import 'package:flutter_invoice_app/core/services/excel/generators/customer_statement_excel_generator.dart';
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

  group('CustomerStatementExcelGenerator', () {
    test('generates valid Excel bytes and readable workbook with items and profile', () async {
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

      final bytes = await CustomerStatementExcelGenerator.generate(
        statement,
        profile: testProfile,
      );

      expect(bytes, isNotNull);
      expect(bytes, isA<Uint8List>());
      expect(bytes!.isNotEmpty, isTrue);

      // Verify readable workbook
      final excel = Excel.decodeBytes(bytes);
      expect(excel.sheets.containsKey('Statement'), isTrue);

      final sheet = excel['Statement'];
      expect(sheet.maxRows, greaterThan(0));

      // Check Company Name Header (row 0, col 0)
      final companyCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      expect(companyCell.value.toString(), contains('MY INVOICING CO LLC'));

      // Check Statement title (row 1, col 0)
      final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
      expect(titleCell.value.toString(), equals('STATEMENT OF ACCOUNT'));

      // Verify customer info exists in cells
      bool foundCustomer = false;
      bool foundPeriod = false;
      bool foundTotalInvoiced = false;
      bool foundInv001 = false;
      bool foundInv002 = false;
      bool foundTotalRow = false;

      for (int r = 0; r < sheet.maxRows; r++) {
        final row = sheet.row(r);
        final rowValues = row.map((c) => c?.value?.toString() ?? '').toList();

        if (rowValues.any((v) => v.contains('Acme Corp'))) {
          foundCustomer = true;
        }
        if (rowValues.any((v) => v.contains('01/01/2026 - 31/03/2026'))) {
          foundPeriod = true;
        }
        if (rowValues.any((v) => v.contains('Total Invoiced: 4000.00 AED'))) {
          foundTotalInvoiced = true;
        }
        if (rowValues.any((v) => v.contains('INV-001'))) {
          foundInv001 = true;
        }
        if (rowValues.any((v) => v.contains('INV-002'))) {
          foundInv002 = true;
        }
        if (rowValues.isNotEmpty && rowValues[0] == 'TOTAL') {
          foundTotalRow = true;
        }
      }

      expect(foundCustomer, isTrue, reason: 'Customer name should be in workbook');
      expect(foundPeriod, isTrue, reason: 'Period should be in workbook');
      expect(foundTotalInvoiced, isTrue, reason: 'Total invoiced summary should be in workbook');
      expect(foundInv001, isTrue, reason: 'INV-001 row should be in workbook');
      expect(foundInv002, isTrue, reason: 'INV-002 row should be in workbook');
      expect(foundTotalRow, isTrue, reason: 'TOTAL row should be in workbook');
    });

    test('generates valid Excel for empty statement', () async {
      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: [],
        statementDate: DateTime(2026, 3, 28),
      );

      final bytes = await CustomerStatementExcelGenerator.generate(
        statement,
        profile: testProfile,
      );

      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);

      final excel = Excel.decodeBytes(bytes);
      expect(excel.sheets.containsKey('Statement'), isTrue);
      final sheet = excel['Statement'];
      expect(sheet.maxRows, greaterThan(0));

      bool foundTotalRow = false;
      for (int r = 0; r < sheet.maxRows; r++) {
        final rowValues = sheet.row(r).map((c) => c?.value?.toString() ?? '').toList();
        if (rowValues.isNotEmpty && rowValues[0] == 'TOTAL') {
          foundTotalRow = true;
        }
      }
      expect(foundTotalRow, isTrue);
    });

    test('generates valid Excel when profile is null (fallback to STATEMENT)', () async {
      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: [],
        statementDate: DateTime(2026, 3, 28),
      );

      final bytes = await CustomerStatementExcelGenerator.generate(
        statement,
        profile: null,
      );

      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);

      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Statement'];
      final companyCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      expect(companyCell.value.toString(), equals('STATEMENT'));
    });

    test('generates valid Excel without TRN when client has no taxId', () async {
      final clientNoTrn = Client(
        id: 'client-2',
        name: 'No TRN Client',
        email: 'notrn@example.com',
      );

      final statement = CustomerStatement.fromInvoices(
        client: clientNoTrn,
        allInvoices: [],
        statementDate: DateTime(2026, 3, 28),
      );

      final bytes = await CustomerStatementExcelGenerator.generate(statement);

      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);

      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Statement'];

      bool foundTrn = false;
      for (int r = 0; r < sheet.maxRows; r++) {
        final rowValues = sheet.row(r).map((c) => c?.value?.toString() ?? '').toList();
        if (rowValues.any((v) => v.contains('TRN:'))) {
          foundTrn = true;
        }
      }
      expect(foundTrn, isFalse);
    });

    test('generates valid Excel with various date filter ranges', () async {
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
      final bytesFrom = await CustomerStatementExcelGenerator.generate(stmtFromOnly);
      expect(bytesFrom, isNotNull);

      final excelFrom = Excel.decodeBytes(bytesFrom!);
      final sheetFrom = excelFrom['Statement'];
      bool foundFromPeriod = false;
      for (int r = 0; r < sheetFrom.maxRows; r++) {
        final rowValues = sheetFrom.row(r).map((c) => c?.value?.toString() ?? '').toList();
        if (rowValues.any((v) => v.contains('From 01/01/2026'))) {
          foundFromPeriod = true;
        }
      }
      expect(foundFromPeriod, isTrue);

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
      final bytesTo = await CustomerStatementExcelGenerator.generate(stmtToOnly);
      expect(bytesTo, isNotNull);

      final excelTo = Excel.decodeBytes(bytesTo!);
      final sheetTo = excelTo['Statement'];
      bool foundToPeriod = false;
      for (int r = 0; r < sheetTo.maxRows; r++) {
        final rowValues = sheetTo.row(r).map((c) => c?.value?.toString() ?? '').toList();
        if (rowValues.any((v) => v.contains('Until 31/03/2026'))) {
          foundToPeriod = true;
        }
      }
      expect(foundToPeriod, isTrue);
    });

    test('ExcelService delegates generateCustomerStatement correctly', () async {
      final excelService = ExcelService();
      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: [],
        statementDate: DateTime(2026, 3, 28),
      );

      final bytes = await excelService.generateCustomerStatement(
        statement,
        profile: testProfile,
      );

      expect(bytes, isNotNull);
      expect(bytes, isA<Uint8List>());
      expect(bytes!.isNotEmpty, isTrue);

      final excel = Excel.decodeBytes(bytes);
      expect(excel.sheets.containsKey('Statement'), isTrue);
    });
  });
}
