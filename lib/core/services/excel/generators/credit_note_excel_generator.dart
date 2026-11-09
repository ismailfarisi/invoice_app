import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_invoice_app/core/utils/number_to_words.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/models/credit_note.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:intl/intl.dart';

class CreditNoteExcelGenerator {
  static Future<Uint8List?> generate(
    CreditNote note, {
    BusinessProfile? profile,
  }) async {
    final excel = Excel.createExcel();
    const sheetName = 'Credit Note';
    if (excel.sheets.containsKey('Sheet1')) {
      excel.rename('Sheet1', sheetName);
    }
    final sheet = excel[sheetName];

    sheet.setColumnWidth(0, 16.0);
    sheet.setColumnWidth(1, 45.0);
    sheet.setColumnWidth(2, 22.0);
    sheet.setColumnWidth(3, 16.0);
    sheet.setColumnWidth(4, 12.0);
    sheet.setColumnWidth(5, 15.0);
    sheet.setColumnWidth(6, 10.0);

    final dateFormat = DateFormat('dd-MMM-yy');
    final boldStyle = CellStyle(bold: true);
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#EEEEEE'),
      horizontalAlign: HorizontalAlign.Center,
    );

    TextCellValue text(String? value) => TextCellValue(value ?? '');

    void styleLastRow(int columns, CellStyle style) {
      final rowIndex = sheet.maxRows - 1;
      for (var col = 0; col < columns; col++) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: col,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle =
            style;
      }
    }

    sheet.appendRow([text(profile?.companyName.toUpperCase())]);
    styleLastRow(
      1,
      CellStyle(
        bold: true,
        fontSize: 16,
        fontColorHex: ExcelColor.fromHexString('#0D47A1'),
      ),
    );
    sheet.appendRow([
      text(note.isVoided ? 'TAX CREDIT NOTE (VOID)' : 'TAX CREDIT NOTE'),
    ]);
    styleLastRow(1, CellStyle(bold: true, fontSize: 13));
    sheet.appendRow([text('')]);

    sheet.appendRow([
      text('Supplier:'),
      text(profile?.companyName),
      text('Credit Note No:'),
      text(note.creditNoteNumber),
    ]);
    sheet.appendRow([
      text('Address:'),
      text(profile?.address),
      text('Date:'),
      text(dateFormat.format(note.date)),
    ]);
    sheet.appendRow([
      text('TRN:'),
      text(profile?.taxId),
      text('Against Tax Invoice:'),
      text(note.invoiceNumber),
    ]);
    sheet.appendRow([
      text('Buyer:'),
      text(note.client.name),
      text('Invoice Date:'),
      text(note.invoiceDate != null ? dateFormat.format(note.invoiceDate!) : '-'),
    ]);
    sheet.appendRow([
      text('Address:'),
      text(note.client.address),
      text('Place of Supply:'),
      text(
        note.placeOfSupply == null || note.placeOfSupply!.isEmpty
            ? 'UAE'
            : note.placeOfSupply,
      ),
    ]);
    sheet.appendRow([
      text('TRN:'),
      text(note.client.taxId),
      text('Currency:'),
      text(note.currency),
    ]);
    sheet.appendRow([text('Reason:'), text(note.reason)]);
    sheet.appendRow([text('')]);

    final isVat = note.isVatApplicable;
    final headers = [
      'SI No.',
      'Description of Goods',
      'Quantity',
      'Rate',
      'per',
      'Amount',
      if (isVat) 'VAT %',
    ];
    sheet.appendRow(headers.map(text).toList());
    styleLastRow(headers.length, headerStyle);

    for (var i = 0; i < note.items.length; i++) {
      final item = note.items[i];
      sheet.appendRow([
        text((i + 1).toString()),
        text(item.description),
        DoubleCellValue(item.quantity),
        DoubleCellValue(item.unitPrice),
        text(item.unit == null || item.unit!.isEmpty ? 'NOS' : item.unit),
        DoubleCellValue(item.total),
        if (isVat) text('${_formatRate(note.vatRate)}%'),
      ]);
    }

    sheet.appendRow([text('')]);
    sheet.appendRow([
      text('Subtotal'),
      text(''),
      text(''),
      text(''),
      text(''),
      DoubleCellValue(note.subtotal),
    ]);
    if (isVat && note.taxAmount > 0) {
      sheet.appendRow([
        text('VAT (${_formatRate(note.vatRate)}%)'),
        text(''),
        text(''),
        text(''),
        text(''),
        DoubleCellValue(note.taxAmount),
      ]);
    }
    sheet.appendRow([
      text('Total Credit (${note.currency})'),
      text(''),
      text(''),
      text(''),
      text(''),
      DoubleCellValue(note.total),
    ]);
    styleLastRow(6, boldStyle);

    sheet.appendRow([text('')]);
    sheet.appendRow([
      text(
        'Amount Credited (in words): ${NumberToWords.convert(note.total, currencyCode: note.currency)}',
      ),
    ]);
    sheet.appendRow([
      text(
        'Declaration: We declare that this credit note shows the actual amount credited against the invoice stated above and that all particulars are true and correct.',
      ),
    ]);

    final bytes = excel.save() ?? excel.encode();
    return bytes != null ? Uint8List.fromList(bytes) : null;
  }

  static String _formatRate(double rate) {
    return rate == rate.roundToDouble()
        ? rate.toInt().toString()
        : rate.toStringAsFixed(2);
  }
}
