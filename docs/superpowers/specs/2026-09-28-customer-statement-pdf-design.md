# Customer Statement PDF & Excel Generation Design

## Overview
This document specifies the design for generating a Customer Statement of Account in both PDF and Excel formats in `flutter_invoice_app`. The feature allows users to filter invoices for any client across preset or custom date ranges, preview the generated statement, print/share the PDF, and export the statement as an Excel (.xlsx) spreadsheet.

---

## 1. Domain Models

### File: `lib/features/client/domain/models/customer_statement.dart`

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

  /// Factory to construct and calculate statement from raw invoices
  factory CustomerStatement.fromInvoices({
    required Client client,
    required List<Invoice> allInvoices,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? statementDate,
  }) {
    final now = statementDate ?? DateTime.now();

    // 1. Filter invoices matching client
    final clientInvoices = allInvoices.where((inv) {
      final matchesId = inv.client.id == client.id;
      final matchesName = inv.client.name.trim().toLowerCase() == client.name.trim().toLowerCase();
      return matchesId || matchesName;
    }).where((inv) {
      // 2. Exclude Draft and Cancelled
      return inv.status != InvoiceStatus.draft && inv.status != InvoiceStatus.cancelled;
    }).where((inv) {
      // 3. Date range filter
      final invDate = inv.date ?? DateTime.now();
      if (fromDate != null && invDate.isBefore(DateTime(fromDate.year, fromDate.month, fromDate.day))) {
        return false;
      }
      if (toDate != null && invDate.isAfter(DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59))) {
        return false;
      }
      return true;
    }).toList();

    // Sort chronologically
    clientInvoices.sort((a, b) => (a.date ?? DateTime(0)).compareTo(b.date ?? DateTime(0)));

    double running = 0.0;
    double sumInvoiced = 0.0;
    double sumPaid = 0.0;
    String currency = clientInvoices.isNotEmpty ? (clientInvoices.first.currency ?? 'AED') : 'AED';

    final List<CustomerStatementItem> items = [];
    for (final inv in clientInvoices) {
      final amount = inv.total;
      final paid = inv.status == InvoiceStatus.paid ? amount : 0.0;
      final balance = amount - paid;
      running += balance;
      sumInvoiced += amount;
      sumPaid += paid;

      items.add(CustomerStatementItem(
        invoiceId: inv.id,
        invoiceNumber: inv.invoiceNumber,
        date: inv.date ?? DateTime.now(),
        dueDate: inv.dueDate,
        status: inv.status,
        amount: amount,
        paidAmount: paid,
        balance: balance,
        runningBalance: running,
      ));
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
      currency: currency,
    );
  }
}
```

---

## 2. PDF Generator Service

### File: `lib/core/services/pdf/generators/customer_statement_pdf_generator.dart`

- Uses `pdf/pdf.dart` and `pdf/widgets.dart` (`pw`).
- Integrates `PdfHeaders.buildInvoiceHeader` with the title `"STATEMENT OF ACCOUNT"`.
- Uses `PdfStyles.buildPageTheme` and `PdfFooters.buildCommonPageFooter`.
- Builds Customer & Statement metadata box:
  - Left column: Customer Name, Address, TRN, Contact Person, Phone, Email.
  - Right column: Statement Date, Period ("All Time" or "DD/MM/YYYY - DD/MM/YYYY"), Total Invoices.
- Summary Cards row:
  - Total Invoiced (primary container)
  - Total Paid (green accent container)
  - Balance Due (prominent container with highlighted borders)
- Statement Activity Table:
  - Columns: Date, Invoice #, Due Date, Status, Invoice Amount, Paid Amount, Balance.
  - Alignment: text left-aligned, monetary values right-aligned.
  - If `items` is empty, displays an empty state container row.
  - Table footer with grand totals.
- Bank Account / Remittance Details section (if present in `BusinessProfile`).

### Integration: `lib/core/services/pdf/pdf_service.dart`
Adds method:
```dart
Future<Uint8List> generateCustomerStatement(
  CustomerStatement statement, {
  BusinessProfile? profile,
}) {
  return CustomerStatementPdfGenerator.generate(statement, profile: profile);
}
```

---

## 3. Excel Generator Service

### File: `lib/core/services/excel/generators/customer_statement_excel_generator.dart`

- Uses the `excel` package.
- Creates a sheet named `"Statement"`.
- Appends business title, statement title, customer info header.
- Appends summary stats (Total Invoiced, Total Paid, Balance Due).
- Formats table headers:
  - `['Date', 'Invoice #', 'Due Date', 'Status', 'Invoiced Amount ($currency)', 'Paid Amount ($currency)', 'Balance ($currency)', 'Running Balance ($currency)']`
- Adds data rows and bottom summary totals row.
- Returns `Uint8List?`.

### Integration: `lib/core/services/excel/excel_service.dart`
Adds method:
```dart
Future<Uint8List?> generateCustomerStatement(
  CustomerStatement statement, {
  BusinessProfile? profile,
}) {
  return CustomerStatementExcelGenerator.generate(statement, profile: profile);
}
```

---

## 4. UI Layer & Workflow

### 1. `lib/features/client/presentation/screens/client_list_screen.dart`
- In `_ClientCard`, add an `IconButton` before the delete icon:
  - Icon: `Icons.receipt_long_outlined`
  - Tooltip: `'Statement of Account'`
  - OnPressed: shows `_showStatementFilterDialog(context, client)`.

### 2. `_showStatementFilterDialog` Bottom Sheet
- Offers date range preset options:
  - `All Time` (Default)
  - `This Month`
  - `This Year`
  - `Custom Range` (triggers `showDateRangePicker`)
- Displays currently selected range description.
- Action: `"View Statement"` button:
  - Reads all invoices via `ref.read(invoiceRepositoryProvider).getAllInvoices()`.
  - Reads business profile via `ref.read(settingsRepositoryProvider).getBusinessProfile()`.
  - Builds `CustomerStatement.fromInvoices(...)`.
  - Navigates to `GenericPdfPreviewScreen`.

### 3. PDF Preview & Excel Export
- Screen: `GenericPdfPreviewScreen`
  - `title`: `'Statement - ${client.name}'`
  - `pdfFileName`: `'Statement_${client.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf'`
  - `buildEvent`: `(format) => PdfService().generateCustomerStatement(statement, profile: profile)`
  - `onExportExcel`: exports `.xlsx` using `ExcelService`, saves to temp file, and shares via `SharePlus` / `Printing.sharePdf`.

---

## 5. Verification & Testing Plan

1. **Unit Tests** (`test/features/client/customer_statement_test.dart`):
   - Invoices calculation test: verifying correct total invoiced, total paid, and balance due.
   - Status filtering test: ensuring `draft` and `cancelled` invoices are excluded.
   - Date range test: verifying invoices outside the specified range are excluded.
   - Running balance test: ensuring running balance updates progressively.
2. **Analysis Check**:
   - Run `flutter analyze` to ensure zero compilation or type errors.
