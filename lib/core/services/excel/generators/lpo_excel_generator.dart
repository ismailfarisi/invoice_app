import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:intl/intl.dart';
import 'package:flutter_invoice_app/core/utils/number_to_words.dart';

class LpoExcelGenerator {
  static Future<Uint8List?> generate(
    Lpo lpo, {
    BusinessProfile? profile,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // 1. Set Column Widths (Mirroring PDF ratios)
    sheetObject.setColumnWidth(0, 8.0); // SI No
    sheetObject.setColumnWidth(1, 45.0); // Description
    sheetObject.setColumnWidth(2, 12.0); // Quantity
    sheetObject.setColumnWidth(3, 12.0); // Rate
    sheetObject.setColumnWidth(4, 10.0); // per
    sheetObject.setColumnWidth(5, 15.0); // Amount

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

    // 1. Header
    int currentRow = 0;
    sheetObject.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
    );
    var titleCell = sheetObject.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    titleCell.value = TextCellValue('PURCHASE ORDER');
    titleCell.cellStyle = headerStyle;
    currentRow += 2;

    // 2. Info Box
    // Supplier Section (Vendor)
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
      lpo.vendor.name.toString(),
    );
    sheetObject
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
            )
            .cellStyle =
        boldStyle;

    // Right side info
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow))
        .value = TextCellValue(
      'LPO No:',
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
      lpo.lpoNumber.toString(),
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
      lpo.vendor.address.toString(),
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
      lpo.date != null ? DateFormat('dd-MMM-yy').format(lpo.date!) : '-',
    );
    currentRow++;

    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        .value = TextCellValue(
      'TRN: ${lpo.vendor.taxId ?? ''}',
    );
    currentRow += 2;

    // Buyer Section (Our Company)
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
      profile?.companyName ?? '',
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
      profile?.address ?? '',
    );
    currentRow++;

    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        .value = TextCellValue(
      'TRN: ${profile?.taxId ?? ''}',
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

    for (int i = 0; i < labels.length; i++) {
      var hCell = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow),
      );
      hCell.value = TextCellValue(labels[i]);
      hCell.cellStyle = tableHeaderStyle;
    }
    currentRow++;

    // 4. Items Table Rows
    for (int i = 0; i < lpo.items.length; i++) {
      var item = lpo.items[i];

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
      lpo.total,
      currencyCode: lpo.currency ?? 'AED',
    );
    wordsCell.value = TextCellValue('Amount (in words):\n$amountInWords');
    wordsCell.cellStyle = CellStyle(
      fontSize: 10,
      italic: true,
      verticalAlign: VerticalAlign.Top,
    );

    // Totals
    int totalCol = 4;
    int amountCol = 5;

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

    addTotalRow('Subtotal', lpo.subtotal, false);
    if ((lpo.isVatApplicable ?? true) && lpo.taxAmount > 0) {
      addTotalRow('VAT', lpo.taxAmount, false);
    }
    addTotalRow('Total', lpo.total, true);
    currentRow += 2;

    // 6. Remarks
    if (lpo.notes != null && lpo.notes!.isNotEmpty) {
      sheetObject.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
      );
      var remarksCell = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      remarksCell.value = TextCellValue('Remarks: ${lpo.notes}');
      remarksCell.cellStyle = labelStyle;
      currentRow += 2;
    }

    // 7. Signature Area
    sheetObject.merge(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
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
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
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
