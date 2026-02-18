import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:intl/intl.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/core/utils/number_to_words.dart';

class InvoiceExcelGenerator {
  static Future<Uint8List?> generate(
    Invoice invoice, {
    BusinessProfile? profile,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // 1. Set Column Widths (Approximate to PDF ratios)
    // A: 5 (SI No), B: 40 (Description), C: 12 (Qty), D: 12 (Rate), E: 10 (Per), F: 15 (Amount), G: 10 (VAT)
    sheetObject.setColumnWidth(0, 8.0);
    sheetObject.setColumnWidth(1, 45.0);
    sheetObject.setColumnWidth(2, 12.0);
    sheetObject.setColumnWidth(3, 12.0);
    sheetObject.setColumnWidth(4, 10.0);
    sheetObject.setColumnWidth(5, 15.0);
    bool isVat = invoice.isVatApplicable ?? true;
    if (isVat) {
      sheetObject.setColumnWidth(6, 10.0);
    }

    // Styles
    final ExcelColor blue900 = ExcelColor.fromHexString('#0D47A1');
    final ExcelColor gray200 = ExcelColor.fromHexString('#EEEEEE');

    CellStyle headerStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: blue900,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    CellStyle boldStyle = CellStyle(bold: true);
    CellStyle labelStyle = CellStyle(fontSize: 10, italic: true);

    CellStyle tableHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: gray200,
      horizontalAlign: HorizontalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    CellStyle cellBorderStyle = CellStyle(
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    CellStyle rightAlignStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // 1. Header & Logo
    int currentRow = 0;

    // Logo (If available)
    if (profile?.logoPath != null && File(profile!.logoPath!).existsSync()) {
      // Note: excel package image support is sometimes tricky, placing it in the first cell for now
      // If ImageCellValue isn't available in this version, we fall back to text.
      try {
        // sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = ImageCellValue(profile.logoPath!);
      } catch (e) {
        // Fallback or ignore
      }
    }

    sheetObject.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      CellIndex.indexByColumnRow(
        columnIndex: isVat ? 6 : 5,
        rowIndex: currentRow,
      ),
    );
    var titleCell = sheetObject.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    titleCell.value = TextCellValue('TAX INVOICE');
    titleCell.cellStyle = headerStyle;
    currentRow += 2;

    // 2. Info Box (Supplier / Buyer / Details)
    // Supplier Section
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .value = TextCellValue(
      'Supplier:',
    );
    sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
            )
            .cellStyle =
        labelStyle;
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        .value = TextCellValue(
      profile?.companyName ?? '',
    );
    sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
            )
            .cellStyle =
        boldStyle;

    // Right side info (Invoice No)
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow))
        .value = TextCellValue(
      'Invoice No:',
    );
    sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
            )
            .cellStyle =
        labelStyle;
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow))
        .value = TextCellValue(
      invoice.invoiceNumber,
    );
    sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
            )
            .cellStyle =
        boldStyle;
    currentRow++;

    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        .value = TextCellValue(
      profile?.address ?? '',
    );
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow))
        .value = TextCellValue(
      'Date:',
    );
    sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
            )
            .cellStyle =
        labelStyle;
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow))
        .value = TextCellValue(
      invoice.date != null
          ? DateFormat('dd-MMM-yy').format(invoice.date!)
          : '-',
    );
    currentRow++;

    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        .value = TextCellValue(
      'TRN: ${profile?.taxId ?? ''}',
    );
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow))
        .value = TextCellValue(
      'Payment Terms:',
    );
    sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
            )
            .cellStyle =
        labelStyle;
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow))
        .value = TextCellValue(
      invoice.paymentTerms ?? 'Cash',
    );
    currentRow += 2;

    // Buyer Section
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .value = TextCellValue(
      'Buyer:',
    );
    sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
            )
            .cellStyle =
        labelStyle;
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        .value = TextCellValue(
      invoice.client.name.toString(),
    );
    sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
            )
            .cellStyle =
        boldStyle;
    currentRow++;

    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        .value = TextCellValue(
      invoice.client.address.toString(),
    );
    currentRow++;

    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        .value = TextCellValue(
      'TRN: ${invoice.client.taxId ?? ''}',
    );
    currentRow += 2;

    // 3. Items Table Header
    List<String> labels = [
      'SI No.',
      'Description of Goods',
      'Quantity',
      'Rate',
      'per',
      'Amount',
    ];
    if (isVat) labels.add('VAT %');

    for (int i = 0; i < labels.length; i++) {
      var hCell = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow),
      );
      hCell.value = TextCellValue(labels[i]);
      hCell.cellStyle = tableHeaderStyle;
    }
    currentRow++;

    // 4. Items Table Rows
    for (int i = 0; i < invoice.items.length; i++) {
      var item = invoice.items[i];

      var c1 = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      c1.value = TextCellValue((i + 1).toString());
      c1.cellStyle = cellBorderStyle;

      var c2 = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
      );
      c2.value = TextCellValue(item.description.toString());
      c2.cellStyle = cellBorderStyle;

      var c3 = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
      );
      c3.value = DoubleCellValue(item.quantity);
      c3.cellStyle = rightAlignStyle;

      var c4 = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
      );
      c4.value = DoubleCellValue(item.unitPrice);
      c4.cellStyle = rightAlignStyle;

      var c5 = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
      );
      c5.value = TextCellValue(item.unit ?? 'NOS');
      c5.cellStyle = cellBorderStyle;

      var c6 = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
      );
      c6.value = DoubleCellValue(item.total);
      c6.cellStyle = rightAlignStyle;

      if (isVat) {
        var c7 = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
        );
        c7.value = TextCellValue('10%');
        c7.cellStyle = cellBorderStyle;
      }
      currentRow++;
    }

    // 5. Totals Section
    currentRow++;
    // Amount in Words
    sheetObject.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow + 2),
    );
    var wordsCell = sheetObject.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    String amountInWords = NumberToWords.convert(
      invoice.total,
      currencyCode: invoice.currency ?? 'AED',
    );
    wordsCell.value = TextCellValue('Amount (in words):\n$amountInWords');
    wordsCell.cellStyle = CellStyle(
      fontSize: 10,
      italic: true,
      verticalAlign: VerticalAlign.Top,
    );

    // Totals
    int totalCol = isVat ? 5 : 4;
    int amountCol = isVat ? 6 : 5;

    void addTotalRow(String label, double value, bool isBold) {
      var lCell = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: totalCol, rowIndex: currentRow),
      );
      lCell.value = TextCellValue(label);
      lCell.cellStyle = isBold ? tableHeaderStyle : cellBorderStyle;

      var vCell = sheetObject.cell(
        CellIndex.indexByColumnRow(
          columnIndex: amountCol,
          rowIndex: currentRow,
        ),
      );
      vCell.value = DoubleCellValue(value);
      vCell.cellStyle = isBold ? tableHeaderStyle : rightAlignStyle;
      currentRow++;
    }

    addTotalRow('Subtotal', invoice.subtotal, false);
    if (isVat && invoice.taxAmount > 0) {
      addTotalRow('VAT (10%)', invoice.taxAmount, false);
    }
    addTotalRow('Total', invoice.total, true);
    currentRow += 2;

    // 6. Signatures & Declaration
    sheetObject.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      CellIndex.indexByColumnRow(
        columnIndex: isVat ? 6 : 5,
        rowIndex: currentRow,
      ),
    );
    var declCell = sheetObject.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    declCell.value = TextCellValue(
      'Declaration: We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.',
    );
    declCell.cellStyle = labelStyle;
    currentRow += 2;

    // Signature Area
    sheetObject.merge(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
      CellIndex.indexByColumnRow(
        columnIndex: isVat ? 6 : 5,
        rowIndex: currentRow,
      ),
    );
    var sigHeaderCell = sheetObject.cell(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
    );
    sigHeaderCell.value = TextCellValue('for ${profile?.companyName ?? ""}');
    sigHeaderCell.cellStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );
    currentRow += 4;

    sheetObject.merge(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
      CellIndex.indexByColumnRow(
        columnIndex: isVat ? 6 : 5,
        rowIndex: currentRow,
      ),
    );
    var sigCell = sheetObject.cell(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
    );
    sigCell.value = TextCellValue('Authorised Signatory');
    sigCell.cellStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      topBorder: Border(borderStyle: BorderStyle.Thin),
    );

    return Uint8List.fromList(excel.encode()!);
  }
}
