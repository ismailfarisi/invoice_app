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
        (profile.bankName == null &&
            profile.bankIban == null &&
            (profile.bankDetails == null || profile.bankDetails!.trim().isEmpty))) {
      return pw.SizedBox.shrink();
    }

    final hasStructured = profile.bankName != null ||
        profile.bankAccountName != null ||
        profile.bankAccountNumber != null ||
        profile.bankIban != null ||
        profile.bankSwift != null;

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
          if (hasStructured) ...[
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
          ] else if (profile.bankDetails != null &&
              profile.bankDetails!.trim().isNotEmpty) ...[
            pw.Text(
              profile.bankDetails!.trim(),
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ],
      ),
    );
  }
}
