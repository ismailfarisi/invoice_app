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
    if (excel.sheets.containsKey('Sheet1')) {
      excel.rename('Sheet1', sheetName);
    }
    final sheet = excel[sheetName];

    // Column widths
    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 16.0);
    sheet.setColumnWidth(2, 14.0);
    sheet.setColumnWidth(3, 14.0);
    sheet.setColumnWidth(4, 22.0);
    sheet.setColumnWidth(5, 20.0);
    sheet.setColumnWidth(6, 18.0);
    sheet.setColumnWidth(7, 22.0);

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
    compCell.value = TextCellValue(
      profile?.companyName != null && profile!.companyName.trim().isNotEmpty
          ? profile.companyName.toUpperCase()
          : 'STATEMENT',
    );
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

    String periodText = 'All Time';
    if (statement.fromDate != null && statement.toDate != null) {
      periodText =
          '${dateFormat.format(statement.fromDate!)} - ${dateFormat.format(statement.toDate!)}';
    } else if (statement.fromDate != null) {
      periodText = 'From ${dateFormat.format(statement.fromDate!)}';
    } else if (statement.toDate != null) {
      periodText = 'Until ${dateFormat.format(statement.toDate!)}';
    }

    sheet.appendRow([
      TextCellValue('Email:'),
      TextCellValue(statement.client.email),
      TextCellValue('Period:'),
      TextCellValue(periodText),
    ]);
    if (statement.client.taxId != null && statement.client.taxId!.isNotEmpty) {
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
      TextCellValue(
        'Total Invoiced: ${statement.totalInvoiced.toStringAsFixed(2)} ${statement.currency}',
      ),
      TextCellValue(
        'Total Paid: ${statement.totalPaid.toStringAsFixed(2)} ${statement.currency}',
      ),
      TextCellValue(
        'Balance Due: ${statement.totalBalanceDue.toStringAsFixed(2)} ${statement.currency}',
      ),
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
          .cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIndex),
          )
          .cellStyle = headerStyle;
    }

    // Data rows
    for (final item in statement.items) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(item.date)),
        TextCellValue(item.invoiceNumber),
        TextCellValue(
          item.dueDate != null ? dateFormat.format(item.dueDate!) : '-',
        ),
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
          .cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: totalRowIndex),
          )
          .cellStyle = boldStyle;
    }

    final bytes = excel.save() ?? excel.encode();
    return bytes != null ? Uint8List.fromList(bytes) : null;
  }
}
