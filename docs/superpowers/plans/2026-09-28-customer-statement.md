# Customer Statement PDF & Excel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to generate, preview, print/share, and export a Customer Statement of Account in PDF and Excel formats with customizable date filtering.

**Architecture:** A domain model (`CustomerStatement`) filters and aggregates raw invoices for a given client, calculating chronological running balances and summary totals. Two specialized generators (`CustomerStatementPdfGenerator` and `CustomerStatementExcelGenerator`) produce the PDF and Excel documents, which are integrated into the existing `PdfService` and `ExcelService`. On the frontend, a Statement action on the Company card opens a date-filter bottom sheet and presents the result in `GenericPdfPreviewScreen`.

**Tech Stack:** Flutter, Riverpod, Hive, `pdf`, `printing`, `excel`, `share_plus`, `intl`.

## Global Constraints
- Target platform: Flutter / Dart (Windows/Android/iOS/Web/macOS).
- Only include active invoices: exclude `InvoiceStatus.draft` and `InvoiceStatus.cancelled`.
- Match client by ID and fallback to case-insensitive name matching.
- Currency formatting must use `CurrencyFormatter.format`.
- All tests must pass with `flutter test` and zero warnings in `flutter analyze`.

---

### Task 1: Domain Model & Calculation Logic (TDD)

**Files:**
- Create: `test/features/client/customer_statement_test.dart`
- Create: `lib/features/client/domain/models/customer_statement.dart`

**Interfaces:**
- Consumes: `Client`, `Invoice`, `InvoiceStatus` from `lib/features/invoice/domain/models/invoice.dart`.
- Produces:
  ```dart
  class CustomerStatementItem {
    final String invoiceId;
    final String invoiceNumber;
    final DateTime date;
    final DateTime? dueDate;
    final InvoiceStatus status;
    final double amount;
    final double paidAmount;
    final double balance;
    final double runningBalance;
  }

  class CustomerStatement {
    final Client client;
    final DateTime statementDate;
    final DateTime? fromDate;
    final DateTime? toDate;
    final List<CustomerStatementItem> items;
    final double totalInvoiced;
    final double totalPaid;
    final double totalBalanceDue;
    final String currency;

    factory CustomerStatement.fromInvoices({
      required Client client,
      required List<Invoice> allInvoices,
      DateTime? fromDate,
      DateTime? toDate,
      DateTime? statementDate,
    });
  }
  ```

- [ ] **Step 1: Write the failing unit tests**
Create `test/features/client/customer_statement_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/client/domain/models/customer_statement.dart';

void main() {
  final testClient = Client(
    id: 'client-1',
    name: 'Acme Corp',
    email: 'billing@acme.com',
    phone: '+971501234567',
    address: 'Dubai, UAE',
    taxId: '100200300400003',
  );

  final otherClient = Client(
    id: 'client-2',
    name: 'Beta Ltd',
    email: 'info@beta.com',
  );

  Invoice createInvoice({
    required String id,
    required String number,
    required Client client,
    required DateTime date,
    required double total,
    required InvoiceStatus status,
  }) {
    return Invoice(
      id: id,
      invoiceNumber: number,
      client: client,
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

  group('CustomerStatement.fromInvoices', () {
    test('calculates totals, paid, and balance due correctly while filtering clients and excluding draft/cancelled', () {
      final invoices = [
        createInvoice(
          id: 'inv-1',
          number: 'INV-001',
          client: testClient,
          date: DateTime(2026, 1, 10),
          total: 1000.0,
          status: InvoiceStatus.paid,
        ),
        createInvoice(
          id: 'inv-2',
          number: 'INV-002',
          client: testClient,
          date: DateTime(2026, 2, 15),
          total: 2500.0,
          status: InvoiceStatus.sent,
        ),
        createInvoice(
          id: 'inv-3',
          number: 'INV-003',
          client: testClient,
          date: DateTime(2026, 3, 1),
          total: 500.0,
          status: InvoiceStatus.draft, // should be excluded
        ),
        createInvoice(
          id: 'inv-4',
          number: 'INV-004',
          client: testClient,
          date: DateTime(2026, 3, 5),
          total: 800.0,
          status: InvoiceStatus.cancelled, // should be excluded
        ),
        createInvoice(
          id: 'inv-5',
          number: 'INV-005',
          client: otherClient, // different client
          date: DateTime(2026, 3, 10),
          total: 3000.0,
          status: InvoiceStatus.sent,
        ),
        createInvoice(
          id: 'inv-6',
          number: 'INV-006',
          client: testClient,
          date: DateTime(2026, 3, 20),
          total: 1200.0,
          status: InvoiceStatus.overdue,
        ),
      ];

      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: invoices,
        statementDate: DateTime(2026, 3, 28),
      );

      expect(statement.items.length, 3);
      // Item 1: INV-001 (paid)
      expect(statement.items[0].invoiceNumber, 'INV-001');
      expect(statement.items[0].amount, 1000.0);
      expect(statement.items[0].paidAmount, 1000.0);
      expect(statement.items[0].balance, 0.0);
      expect(statement.items[0].runningBalance, 0.0);

      // Item 2: INV-002 (sent)
      expect(statement.items[1].invoiceNumber, 'INV-002');
      expect(statement.items[1].amount, 2500.0);
      expect(statement.items[1].paidAmount, 0.0);
      expect(statement.items[1].balance, 2500.0);
      expect(statement.items[1].runningBalance, 2500.0);

      // Item 3: INV-006 (overdue)
      expect(statement.items[2].invoiceNumber, 'INV-006');
      expect(statement.items[2].amount, 1200.0);
      expect(statement.items[2].paidAmount, 0.0);
      expect(statement.items[2].balance, 1200.0);
      expect(statement.items[2].runningBalance, 3700.0);

      // Totals
      expect(statement.totalInvoiced, 4700.0);
      expect(statement.totalPaid, 1000.0);
      expect(statement.totalBalanceDue, 3700.0);
      expect(statement.currency, 'AED');
    });

    test('respects date range filters correctly', () {
      final invoices = [
        createInvoice(
          id: 'inv-1',
          number: 'INV-001',
          client: testClient,
          date: DateTime(2026, 1, 10),
          total: 1000.0,
          status: InvoiceStatus.paid,
        ),
        createInvoice(
          id: 'inv-2',
          number: 'INV-002',
          client: testClient,
          date: DateTime(2026, 2, 15),
          total: 2000.0,
          status: InvoiceStatus.sent,
        ),
        createInvoice(
          id: 'inv-3',
          number: 'INV-003',
          client: testClient,
          date: DateTime(2026, 3, 20),
          total: 3000.0,
          status: InvoiceStatus.sent,
        ),
      ];

      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: invoices,
        fromDate: DateTime(2026, 2, 1),
        toDate: DateTime(2026, 2, 28),
      );

      expect(statement.items.length, 1);
      expect(statement.items.first.invoiceNumber, 'INV-002');
      expect(statement.totalInvoiced, 2000.0);
      expect(statement.totalPaid, 0.0);
      expect(statement.totalBalanceDue, 2000.0);
    });

    test('matches client by name if id is different or empty', () {
      final legacyClient = Client(
        id: 'legacy-id',
        name: 'Acme Corp',
        email: 'legacy@acme.com',
      );
      final invoices = [
        createInvoice(
          id: 'inv-1',
          number: 'INV-001',
          client: legacyClient,
          date: DateTime(2026, 1, 10),
          total: 1500.0,
          status: InvoiceStatus.sent,
        ),
      ];

      final statement = CustomerStatement.fromInvoices(
        client: testClient,
        allInvoices: invoices,
      );

      expect(statement.items.length, 1);
      expect(statement.totalInvoiced, 1500.0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/client/customer_statement_test.dart`
Expected: Compilation failure because `customer_statement.dart` does not exist.

- [ ] **Step 3: Implement `CustomerStatement`**
Create `lib/features/client/domain/models/customer_statement.dart`:
```dart
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';

class CustomerStatementItem {
  final String invoiceId;
  final String invoiceNumber;
  final DateTime date;
  final DateTime? dueDate;
  final InvoiceStatus status;
  final double amount;
  final double paidAmount;
  final double balance;
  final double runningBalance;

  CustomerStatementItem({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.date,
    this.dueDate,
    required this.status,
    required this.amount,
    required this.paidAmount,
    required this.balance,
    required this.runningBalance,
  });
}

class CustomerStatement {
  final Client client;
  final DateTime statementDate;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<CustomerStatementItem> items;
  final double totalInvoiced;
  final double totalPaid;
  final double totalBalanceDue;
  final String currency;

  CustomerStatement({
    required this.client,
    required this.statementDate,
    this.fromDate,
    this.toDate,
    required this.items,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.totalBalanceDue,
    this.currency = 'AED',
  });

  factory CustomerStatement.fromInvoices({
    required Client client,
    required List<Invoice> allInvoices,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? statementDate,
  }) {
    final now = statementDate ?? DateTime.now();

    final clientInvoices = allInvoices.where((inv) {
      final matchesId = inv.client.id == client.id;
      final matchesName =
          inv.client.name.trim().toLowerCase() == client.name.trim().toLowerCase();
      return matchesId || matchesName;
    }).where((inv) {
      return inv.status != InvoiceStatus.draft &&
          inv.status != InvoiceStatus.cancelled;
    }).where((inv) {
      final invDate = inv.date ?? now;
      if (fromDate != null &&
          invDate.isBefore(DateTime(fromDate.year, fromDate.month, fromDate.day))) {
        return false;
      }
      if (toDate != null &&
          invDate.isAfter(DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59))) {
        return false;
      }
      return true;
    }).toList();

    clientInvoices.sort((a, b) {
      final dateA = a.date ?? DateTime(0);
      final dateB = b.date ?? DateTime(0);
      return dateA.compareTo(dateB);
    });

    double running = 0.0;
    double sumInvoiced = 0.0;
    double sumPaid = 0.0;
    String detectedCurrency = 'AED';
    if (clientInvoices.isNotEmpty && clientInvoices.first.currency != null && clientInvoices.first.currency!.isNotEmpty) {
      detectedCurrency = clientInvoices.first.currency!;
    }

    final List<CustomerStatementItem> items = [];
    for (final inv in clientInvoices) {
      final amount = inv.total;
      final paid = inv.status == InvoiceStatus.paid ? amount : 0.0;
      final balance = amount - paid;
      running += balance;
      sumInvoiced += amount;
      sumPaid += paid;

      items.add(
        CustomerStatementItem(
          invoiceId: inv.id,
          invoiceNumber: inv.invoiceNumber,
          date: inv.date ?? now,
          dueDate: inv.dueDate,
          status: inv.status,
          amount: amount,
          paidAmount: paid,
          balance: balance,
          runningBalance: running,
        ),
      );
    }

    return CustomerStatement(
      client: client,
      statementDate: now,
      fromDate: fromDate,
      toDate: toDate,
      items: items,
      totalInvoiced: sumInvoiced,
      totalPaid: sumPaid,
      totalBalanceDue: sumInvoiced - sumPaid,
      currency: detectedCurrency,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/client/customer_statement_test.dart`
Expected: All 3 tests pass.

- [ ] **Step 5: Commit**
```bash
git add test/features/client/customer_statement_test.dart lib/features/client/domain/models/customer_statement.dart
git commit -m "feat(client): add CustomerStatement domain model with calculation logic"
```

---

### Task 2: PDF Generator Service

**Files:**
- Create: `lib/core/services/pdf/generators/customer_statement_pdf_generator.dart`
- Modify: `lib/core/services/pdf/pdf_service.dart`

**Interfaces:**
- Consumes:
  - `CustomerStatement` from `lib/features/client/domain/models/customer_statement.dart`
  - `BusinessProfile` from `lib/features/settings/domain/models/business_profile.dart`
  - `PdfStyles`, `PdfHeaders`, `PdfFooters`, `PdfCommonWidgets` from `lib/core/services/pdf/widgets/`
  - `CurrencyFormatter` from `lib/core/utils/currency_formatter.dart`
- Produces:
  - `CustomerStatementPdfGenerator.generate(CustomerStatement statement, {BusinessProfile? profile}) -> Future<Uint8List>`
  - `PdfService.generateCustomerStatement(CustomerStatement statement, {BusinessProfile? profile}) -> Future<Uint8List>`

- [ ] **Step 1: Create `CustomerStatementPdfGenerator`**
Create `lib/core/services/pdf/generators/customer_statement_pdf_generator.dart`:
```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/features/client/domain/models/customer_statement.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import '../widgets/pdf_styles.dart';
import '../widgets/pdf_headers.dart';
import '../widgets/pdf_footers.dart';
import '../widgets/pdf_common_widgets.dart';

class CustomerStatementPdfGenerator {
  static Future<Uint8List> generate(
    CustomerStatement statement, {
    BusinessProfile? profile,
  }) async {
    final pdf = pw.Document();

    final logoFile = profile?.logoPath != null ? File(profile!.logoPath!) : null;
    final image = (logoFile != null && logoFile.existsSync())
        ? pw.MemoryImage(logoFile.readAsBytesSync())
        : null;

    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: PdfStyles.buildPageTheme(profile, image),
        header: (context) => PdfHeaders.buildInvoiceHeader(
          profile,
          image,
          'STATEMENT OF ACCOUNT',
        ),
        footer: (context) => PdfFooters.buildCommonPageFooter(
          profile,
          'Statement generated on ${dateFormat.format(statement.statementDate)}',
        ),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 10),
            _buildInfoBox(statement, profile, dateFormat),
            pw.SizedBox(height: 12),
            _buildSummaryCards(statement),
            pw.SizedBox(height: 16),
            _buildItemsTable(statement, dateFormat),
            pw.SizedBox(height: 16),
            _buildBankDetails(profile),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInfoBox(
    CustomerStatement statement,
    BusinessProfile? profile,
    DateFormat dateFormat,
  ) {
    String periodText = 'All Time';
    if (statement.fromDate != null && statement.toDate != null) {
      periodText =
          '${dateFormat.format(statement.fromDate!)} - ${dateFormat.format(statement.toDate!)}';
    } else if (statement.fromDate != null) {
      periodText = 'From ${dateFormat.format(statement.fromDate!)}';
    } else if (statement.toDate != null) {
      periodText = 'Until ${dateFormat.format(statement.toDate!)}';
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Customer details
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'STATEMENT TO',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  statement.client.name,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (statement.client.address != null &&
                    statement.client.address!.isNotEmpty)
                  pw.Text(
                    statement.client.address!,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                if (statement.client.taxId != null &&
                    statement.client.taxId!.isNotEmpty)
                  pw.Text(
                    'TRN: ${statement.client.taxId}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                if (statement.client.contactPerson != null &&
                    statement.client.contactPerson!.isNotEmpty)
                  pw.Text(
                    'Contact: ${statement.client.contactPerson}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                if (statement.client.email.isNotEmpty)
                  pw.Text(
                    'Email: ${statement.client.email}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                if (statement.client.phone != null &&
                    statement.client.phone!.isNotEmpty)
                  pw.Text(
                    'Phone: ${statement.client.phone}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
              ],
            ),
          ),
          pw.Container(width: 0.5, height: 75, color: PdfColors.grey400),
          pw.SizedBox(width: 10),
          // Statement metadata
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfCommonWidgets.buildBoxRow(
                  'Statement Date',
                  dateFormat.format(statement.statementDate),
                ),
                PdfCommonWidgets.buildBoxRow('Period', periodText),
                PdfCommonWidgets.buildBoxRow(
                  'Invoices Count',
                  statement.items.length.toString(),
                ),
                PdfCommonWidgets.buildBoxRow('Currency', statement.currency),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCards(CustomerStatement statement) {
    return pw.Row(
      children: [
        _buildMetricBox(
          'TOTAL INVOICED',
          CurrencyFormatter.format(
            statement.totalInvoiced,
            currency: statement.currency,
          ),
          PdfColors.blue50,
          PdfColors.blue800,
        ),
        pw.SizedBox(width: 10),
        _buildMetricBox(
          'TOTAL PAID',
          CurrencyFormatter.format(
            statement.totalPaid,
            currency: statement.currency,
          ),
          PdfColors.green50,
          PdfColors.green800,
        ),
        pw.SizedBox(width: 10),
        _buildMetricBox(
          'BALANCE DUE',
          CurrencyFormatter.format(
            statement.totalBalanceDue,
            currency: statement.currency,
          ),
          PdfColors.orange50,
          PdfColors.deepOrange900,
          isBold: true,
        ),
      ],
    );
  }

  static pw.Widget _buildMetricBox(
    String label,
    String value,
    PdfColor bgColor,
    PdfColor textColor, {
    bool isBold = false,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          border: pw.Border.all(color: textColor, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildItemsTable(
    CustomerStatement statement,
    DateFormat dateFormat,
  ) {
    if (statement.items.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(
          'No transactions found for the selected period.',
          style: pw.TextStyle(
            fontSize: 10,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey600,
          ),
        ),
      );
    }

    final headers = [
      'Date',
      'Invoice #',
      'Due Date',
      'Status',
      'Invoiced',
      'Paid',
      'Balance',
      'Running Balance',
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2), // Date
        1: pw.FlexColumnWidth(1.5), // Invoice #
        2: pw.FlexColumnWidth(1.2), // Due Date
        3: pw.FlexColumnWidth(1.1), // Status
        4: pw.FlexColumnWidth(1.4), // Invoiced
        5: pw.FlexColumnWidth(1.4), // Paid
        6: pw.FlexColumnWidth(1.4), // Balance
        7: pw.FlexColumnWidth(1.6), // Running Balance
      },
      children: [
        // Table Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers.map((h) {
            final isRightAligned = h == 'Invoiced' ||
                h == 'Paid' ||
                h == 'Balance' ||
                h == 'Running Balance';
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              child: pw.Text(
                h,
                textAlign:
                    isRightAligned ? pw.TextAlign.right : pw.TextAlign.left,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
        // Item Rows
        ...statement.items.map((item) {
          return pw.TableRow(
            children: [
              _tableCell(dateFormat.format(item.date)),
              _tableCell(item.invoiceNumber, isBold: true),
              _tableCell(
                item.dueDate != null ? dateFormat.format(item.dueDate!) : '-',
              ),
              _tableCell(item.status.name.toUpperCase()),
              _tableCell(
                CurrencyFormatter.format(
                  item.amount,
                  currency: statement.currency,
                ),
                align: pw.TextAlign.right,
              ),
              _tableCell(
                CurrencyFormatter.format(
                  item.paidAmount,
                  currency: statement.currency,
                ),
                align: pw.TextAlign.right,
              ),
              _tableCell(
                CurrencyFormatter.format(
                  item.balance,
                  currency: statement.currency,
                ),
                align: pw.TextAlign.right,
              ),
              _tableCell(
                CurrencyFormatter.format(
                  item.runningBalance,
                  currency: statement.currency,
                ),
                align: pw.TextAlign.right,
                isBold: true,
              ),
            ],
          );
        }),
        // Totals Footer Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _tableCell('TOTAL', isBold: true),
            _tableCell(''),
            _tableCell(''),
            _tableCell(''),
            _tableCell(
              CurrencyFormatter.format(
                statement.totalInvoiced,
                currency: statement.currency,
              ),
              align: pw.TextAlign.right,
              isBold: true,
            ),
            _tableCell(
              CurrencyFormatter.format(
                statement.totalPaid,
                currency: statement.currency,
              ),
              align: pw.TextAlign.right,
              isBold: true,
            ),
            _tableCell(
              CurrencyFormatter.format(
                statement.totalBalanceDue,
                currency: statement.currency,
              ),
              align: pw.TextAlign.right,
              isBold: true,
            ),
            _tableCell(
              CurrencyFormatter.format(
                statement.totalBalanceDue,
                currency: statement.currency,
              ),
              align: pw.TextAlign.right,
              isBold: true,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildBankDetails(BusinessProfile? profile) {
    if (profile == null ||
        (profile.bankName == null && profile.bankIban == null)) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'BANK DETAILS FOR REMITTANCE',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              if (profile.bankName != null)
                pw.Expanded(
                  child: PdfCommonWidgets.buildBoxRow('Bank', profile.bankName),
                ),
              if (profile.bankAccountName != null)
                pw.Expanded(
                  child: PdfCommonWidgets.buildBoxRow(
                    'Account Name',
                    profile.bankAccountName,
                  ),
                ),
            ],
          ),
          pw.Row(
            children: [
              if (profile.bankAccountNumber != null)
                pw.Expanded(
                  child: PdfCommonWidgets.buildBoxRow(
                    'Account #',
                    profile.bankAccountNumber,
                  ),
                ),
              if (profile.bankIban != null)
                pw.Expanded(
                  child: PdfCommonWidgets.buildBoxRow('IBAN', profile.bankIban),
                ),
              if (profile.bankSwift != null)
                pw.Expanded(
                  child: PdfCommonWidgets.buildBoxRow(
                    'SWIFT/BIC',
                    profile.bankSwift,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Add `generateCustomerStatement` to `PdfService`**
In `lib/core/services/pdf/pdf_service.dart`, import `customer_statement.dart` and `customer_statement_pdf_generator.dart`, and add:
```dart
  Future<Uint8List> generateCustomerStatement(
    CustomerStatement statement, {
    BusinessProfile? profile,
  }) {
    return CustomerStatementPdfGenerator.generate(statement, profile: profile);
  }
```

- [ ] **Step 3: Run static analysis check**
Run: `flutter analyze lib/core/services/pdf/`
Expected: No errors found.

- [ ] **Step 4: Commit**
```bash
git add lib/core/services/pdf/generators/customer_statement_pdf_generator.dart lib/core/services/pdf/pdf_service.dart
git commit -m "feat(pdf): add CustomerStatementPdfGenerator and wire to PdfService"
```

---

### Task 3: Excel Generator Service

**Files:**
- Create: `lib/core/services/excel/generators/customer_statement_excel_generator.dart`
- Modify: `lib/core/services/excel/excel_service.dart`

**Interfaces:**
- Consumes:
  - `CustomerStatement` from `lib/features/client/domain/models/customer_statement.dart`
  - `BusinessProfile` from `lib/features/settings/domain/models/business_profile.dart`
  - `excel` package
- Produces:
  - `CustomerStatementExcelGenerator.generate(CustomerStatement statement, {BusinessProfile? profile}) -> Future<Uint8List?>`
  - `ExcelService.generateCustomerStatement(CustomerStatement statement, {BusinessProfile? profile}) -> Future<Uint8List?>`

- [ ] **Step 1: Create `CustomerStatementExcelGenerator`**
Create `lib/core/services/excel/generators/customer_statement_excel_generator.dart`:
```dart
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:flutter_invoice_app/features/client/domain/models/customer_statement.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';

class CustomerStatementExcelGenerator {
  static Future<Uint8List?> generate(
    CustomerStatement statement, {
    BusinessProfile? profile,
  }) async {
    final excel = Excel.createExcel();
    final String sheetName = 'Statement';

    // Rename default Sheet1 or use Statement
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    final dateFormat = DateFormat('dd/MM/yyyy');

    // Header Styles
    final CellStyle titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#0D47A1'),
    );

    final CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E0E0E0'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final CellStyle boldStyle = CellStyle(bold: true);

    // Row 1: Company Header
    final compCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    );
    compCell.value = TextCellValue(profile?.companyName.toUpperCase() ?? 'STATEMENT');
    compCell.cellStyle = titleStyle;

    // Row 2: Title
    final titleCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
    );
    titleCell.value = TextCellValue('STATEMENT OF ACCOUNT');
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 13);

    // Customer & Statement Info
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('Customer:'),
      TextCellValue(statement.client.name),
      TextCellValue('Statement Date:'),
      TextCellValue(dateFormat.format(statement.statementDate)),
    ]);
    sheet.appendRow([
      TextCellValue('Email:'),
      TextCellValue(statement.client.email),
      TextCellValue('Period:'),
      TextCellValue(
        statement.fromDate != null && statement.toDate != null
            ? '${dateFormat.format(statement.fromDate!)} - ${dateFormat.format(statement.toDate!)}'
            : 'All Time',
      ),
    ]);
    if (statement.client.taxId != null) {
      sheet.appendRow([
        TextCellValue('TRN:'),
        TextCellValue(statement.client.taxId!),
        TextCellValue('Currency:'),
        TextCellValue(statement.currency),
      ]);
    }

    // Summary Block
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('SUMMARY'),
      TextCellValue('Total Invoiced: ${statement.totalInvoiced.toStringAsFixed(2)} ${statement.currency}'),
      TextCellValue('Total Paid: ${statement.totalPaid.toStringAsFixed(2)} ${statement.currency}'),
      TextCellValue('Balance Due: ${statement.totalBalanceDue.toStringAsFixed(2)} ${statement.currency}'),
    ]);
    sheet.appendRow([TextCellValue('')]);

    // Transactions Table Headers
    final tableHeaders = [
      'Date',
      'Invoice #',
      'Due Date',
      'Status',
      'Invoiced Amount (${statement.currency})',
      'Paid Amount (${statement.currency})',
      'Balance (${statement.currency})',
      'Running Balance (${statement.currency})',
    ];

    sheet.appendRow(tableHeaders.map((h) => TextCellValue(h)).toList());
    final headerRowIndex = sheet.maxRows - 1;
    for (int col = 0; col < tableHeaders.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIndex))
          .cellStyle = headerStyle;
    }

    // Data rows
    for (final item in statement.items) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(item.date)),
        TextCellValue(item.invoiceNumber),
        TextCellValue(item.dueDate != null ? dateFormat.format(item.dueDate!) : '-'),
        TextCellValue(item.status.name.toUpperCase()),
        DoubleCellValue(item.amount),
        DoubleCellValue(item.paidAmount),
        DoubleCellValue(item.balance),
        DoubleCellValue(item.runningBalance),
      ]);
    }

    // Totals row
    sheet.appendRow([
      TextCellValue('TOTAL'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(statement.totalInvoiced),
      DoubleCellValue(statement.totalPaid),
      DoubleCellValue(statement.totalBalanceDue),
      DoubleCellValue(statement.totalBalanceDue),
    ]);

    final totalRowIndex = sheet.maxRows - 1;
    for (int col = 0; col < tableHeaders.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: totalRowIndex))
          .cellStyle = boldStyle;
    }

    return Uint8List.fromList(excel.save()!);
  }
}
```

- [ ] **Step 2: Add `generateCustomerStatement` to `ExcelService`**
In `lib/core/services/excel/excel_service.dart`, import `customer_statement.dart` and `customer_statement_excel_generator.dart`, and add:
```dart
  Future<Uint8List?> generateCustomerStatement(
    CustomerStatement statement, {
    BusinessProfile? profile,
  }) {
    return CustomerStatementExcelGenerator.generate(statement, profile: profile);
  }
```

- [ ] **Step 3: Run static analysis check**
Run: `flutter analyze lib/core/services/excel/`
Expected: No errors found.

- [ ] **Step 4: Commit**
```bash
git add lib/core/services/excel/generators/customer_statement_excel_generator.dart lib/core/services/excel/excel_service.dart
git commit -m "feat(excel): add CustomerStatementExcelGenerator and wire to ExcelService"
```

---

### Task 4: UI Integration in Company List Screen

**Files:**
- Modify: `lib/features/client/presentation/screens/client_list_screen.dart`

**Interfaces:**
- Consumes:
  - `CustomerStatement` from `lib/features/client/domain/models/customer_statement.dart`
  - `invoiceRepositoryProvider` from `lib/features/invoice/data/invoice_repository.dart`
  - `settingsRepositoryProvider` from `lib/features/settings/data/settings_repository.dart`
  - `GenericPdfPreviewScreen` from `lib/features/invoice/presentation/screens/generic_pdf_preview_screen.dart`
  - `PdfService` and `ExcelService`
  - `FileUtils` or `share_plus` for Excel export

- [ ] **Step 1: Implement Statement Button and Date Filter Bottom Sheet in `client_list_screen.dart`**
1. Convert `_ClientCard` into a `ConsumerWidget` or pass down `onGenerateStatement` callback.
2. In `_ClientCard`, add an `IconButton(icon: Icon(Icons.receipt_long_outlined, color: Theme.of(context).colorScheme.primary), tooltip: 'Statement of Account', onPressed: () => _showStatementOptions(context, ref, client))` right before the delete button.
3. Implement `_showStatementOptions`:
   - Shows a bottom sheet with filter presets:
     - All Time
     - This Month
     - This Year
     - Custom Range (shows `showDateRangePicker`)
   - "Generate Statement" button:
     - Extracts all invoices from `ref.read(invoiceRepositoryProvider).getAllInvoices()`.
     - Fetches `BusinessProfile` from `ref.read(settingsRepositoryProvider).getBusinessProfile()`.
     - Builds `statement = CustomerStatement.fromInvoices(...)`.
     - Navigates to `GenericPdfPreviewScreen`:
       - `title`: `'Statement - ${client.name}'`
       - `pdfFileName`: `'Statement_${client.name.replaceAll(RegExp(r'\s+'), '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf'`
       - `buildEvent`: `(format) => PdfService().generateCustomerStatement(statement, profile: profile)`
       - `onExportExcel`: Generates bytes via `ExcelService().generateCustomerStatement(statement, profile: profile)`, writes to temporary file via `path_provider`, and invokes `SharePlus.shareXFiles([XFile(path)])`.

- [ ] **Step 2: Run static analysis check**
Run: `flutter analyze lib/features/client/presentation/screens/client_list_screen.dart`
Expected: No errors found.

- [ ] **Step 3: Commit**
```bash
git add lib/features/client/presentation/screens/client_list_screen.dart
git commit -m "feat(client): add statement generation action and date filter dialog to client list"
```

---

### Task 5: End-to-End Verification & Sanity Check

**Files:**
- Entire codebase

- [ ] **Step 1: Run all unit tests**
Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 2: Run full project analysis**
Run: `flutter analyze`
Expected: No errors found.

- [ ] **Step 3: Verification commit (if any tidy up needed)**
```bash
git status
```
