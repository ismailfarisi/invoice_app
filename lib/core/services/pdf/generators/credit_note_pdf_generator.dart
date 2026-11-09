import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/core/utils/number_to_words.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/models/credit_note.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../widgets/pdf_styles.dart';
import '../widgets/pdf_headers.dart';
import '../widgets/pdf_footers.dart';
import '../widgets/pdf_common_widgets.dart';

class CreditNotePdfGenerator {
  static final DateFormat _dateFormat = DateFormat('dd-MMM-yy');

  static Future<Uint8List> generate(
    CreditNote note, {
    BusinessProfile? profile,
  }) async {
    final pdf = pw.Document();

    final logoFile = profile?.logoPath != null
        ? File(profile!.logoPath!)
        : null;
    final image = (logoFile != null && logoFile.existsSync())
        ? pw.MemoryImage(logoFile.readAsBytesSync())
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: PdfStyles.buildPageTheme(profile, image),
        header: (context) => PdfHeaders.buildInvoiceHeader(
          profile,
          image,
          note.isVoided ? 'Tax Credit Note (VOID)' : 'Tax Credit Note',
        ),
        footer: (context) => PdfFooters.buildCommonPageFooter(
          profile,
          'This is a Computer Generated Credit Note',
        ),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 10),
            _buildInfoBox(note, profile),
            _buildItemsTable(note),
            _buildTotalSection(note),
            pw.SizedBox(height: 24),
            _buildSignatures(note, profile),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInfoBox(CreditNote note, BusinessProfile? profile) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: [
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.top,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfCommonWidgets.buildBoxRow(
                  'Supplier',
                  profile?.companyName,
                  isBold: true,
                ),
                PdfCommonWidgets.buildBoxRow('Address', profile?.address),
                PdfCommonWidgets.buildBoxRow('TRN', profile?.taxId),
                pw.Divider(height: 1, thickness: 0.5),
                PdfCommonWidgets.buildBoxRow(
                  'Buyer',
                  note.client.name,
                  isBold: true,
                ),
                PdfCommonWidgets.buildBoxRow('Address', note.client.address),
                PdfCommonWidgets.buildBoxRow('TRN', note.client.taxId),
                PdfCommonWidgets.buildBoxRow(
                  'Place of Supply',
                  note.placeOfSupply == null || note.placeOfSupply!.isEmpty
                      ? 'UAE'
                      : note.placeOfSupply,
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfCommonWidgets.buildGridItem(
                  'Credit Note No.',
                  note.creditNoteNumber,
                  isBold: true,
                ),
                pw.Divider(height: 1, thickness: 0.5),
                PdfCommonWidgets.buildGridItem(
                  'Dated',
                  _dateFormat.format(note.date),
                ),
                pw.Divider(height: 1, thickness: 0.5),
                PdfCommonWidgets.buildGridItem(
                  'Against Tax Invoice No.',
                  note.invoiceNumber,
                  isBold: true,
                ),
                pw.Divider(height: 1, thickness: 0.5),
                PdfCommonWidgets.buildGridItem(
                  'Invoice Date',
                  note.invoiceDate != null
                      ? _dateFormat.format(note.invoiceDate!)
                      : '-',
                ),
                pw.Divider(height: 1, thickness: 0.5),
                PdfCommonWidgets.buildGridItem('Reason', note.reason),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(CreditNote note) {
    final vatLabel = '${_formatRate(note.vatRate)}%';
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(width: 0.5),
          right: pw.BorderSide(width: 0.5),
          bottom: pw.BorderSide(width: 0.5),
        ),
      ),
      child: pw.Table(
        border: pw.TableBorder.symmetric(
          inside: const pw.BorderSide(width: 0.5),
        ),
        columnWidths: {
          0: const pw.FixedColumnWidth(30),
          1: const pw.FlexColumnWidth(4),
          2: const pw.FixedColumnWidth(50),
          3: const pw.FixedColumnWidth(40),
          4: const pw.FixedColumnWidth(60),
          5: const pw.FixedColumnWidth(70),
          if (note.isVatApplicable) 6: const pw.FixedColumnWidth(40),
        },
        children: [
          pw.TableRow(
            children: [
              PdfCommonWidgets.buildTableCell('SI No.', isHeader: true),
              PdfCommonWidgets.buildTableCell(
                'Description of Goods',
                isHeader: true,
              ),
              PdfCommonWidgets.buildTableCell('Qty', isHeader: true),
              PdfCommonWidgets.buildTableCell('per', isHeader: true),
              PdfCommonWidgets.buildTableCell('Rate', isHeader: true),
              PdfCommonWidgets.buildTableCell('Amount', isHeader: true),
              if (note.isVatApplicable)
                PdfCommonWidgets.buildTableCell('VAT %', isHeader: true),
            ],
          ),
          ...note.items.asMap().entries.map((entry) {
            final item = entry.value;
            return pw.TableRow(
              children: [
                PdfCommonWidgets.buildTableCell((entry.key + 1).toString()),
                PdfCommonWidgets.buildTableCell(
                  item.description,
                  alignLeft: true,
                ),
                PdfCommonWidgets.buildTableCell(_formatQuantity(item.quantity)),
                PdfCommonWidgets.buildTableCell(
                  (item.unit == null || item.unit!.isEmpty)
                      ? 'NOS'
                      : item.unit!,
                ),
                PdfCommonWidgets.buildTableCell(
                  item.unitPrice.toStringAsFixed(2),
                ),
                PdfCommonWidgets.buildTableCell(item.total.toStringAsFixed(2)),
                if (note.isVatApplicable)
                  PdfCommonWidgets.buildTableCell(vatLabel),
              ],
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalSection(CreditNote note) {
    final amountInWords = NumberToWords.convert(
      note.total,
      currencyCode: note.currency,
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.top,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Amount Credited (in words)',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    amountInWords,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.Column(
              children: [
                _buildTotalRow('Subtotal', note.subtotal, note.currency),
                if (note.isVatApplicable && note.taxAmount > 0)
                  _buildTotalRow(
                    'VAT (${_formatRate(note.vatRate)}%)',
                    note.taxAmount,
                    note.currency,
                  ),
                _buildTotalRow(
                  'Total Credit',
                  note.total,
                  note.currency,
                  isBold: true,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    double value,
    String currency, {
    bool isBold = false,
  }) {
    final style = pw.TextStyle(
      fontSize: 9,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('$label ($currency)', style: style),
          pw.Text(CurrencyFormatter.format(value, symbol: ''), style: style),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatures(CreditNote note, BusinessProfile? profile) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Declaration',
                style: const pw.TextStyle(
                  fontSize: 8,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.Text(
                'We declare that this credit note shows the actual amount credited against the invoice stated above and that all particulars are true and correct.',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Container(
          width: 200,
          child: pw.Column(
            children: [
              pw.Container(
                height: 60,
                alignment: pw.Alignment.topCenter,
                child: pw.Text(
                  'for ${profile?.companyName ?? ""}\n\n\n${note.salesPerson == null || note.salesPerson!.isEmpty ? "Authorized Signatory" : note.salesPerson}',
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Prepared by',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Verified by',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Authorised Signatory',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatRate(double rate) {
    return rate == rate.roundToDouble()
        ? rate.toInt().toString()
        : rate.toStringAsFixed(2);
  }

  static String _formatQuantity(double quantity) {
    return quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
