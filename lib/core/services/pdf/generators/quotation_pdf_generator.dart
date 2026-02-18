import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/core/utils/number_to_words.dart';
import '../widgets/pdf_styles.dart';
import '../widgets/pdf_headers.dart';
import '../widgets/pdf_footers.dart';

class QuotationPdfGenerator {
  static Future<Uint8List> generate(
    Quotation quotation, {
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
        header: (context) =>
            PdfHeaders.buildQuotationStyleHeader(profile, image, 'QUOTATION'),
        footer: (context) => PdfFooters.buildDetailedPageFooter(profile),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),
            _buildQuotationInfoBox(quotation, profile),
            pw.SizedBox(height: 15),
            pw.Text(
              'We thank you very much for inviting us to quote for the above job and are pleased to offer you our most competitive Price detailed in the following',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 10),
            _buildQuotationItemsTable(quotation),
            _buildQuotationTotalSection(quotation),
            pw.SizedBox(height: 20),
            _buildQuotationClosing(quotation, profile),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildQuotationInfoBox(
    Quotation quotation,
    BusinessProfile? profile,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Column(
        children: [
          _buildInfoRow(
            'Date',
            quotation.date != null
                ? DateFormat('d/M/yyyy').format(quotation.date!)
                : '-',
          ),
          _buildInfoRow('Company:', quotation.client.name),
          _buildInfoRow(
            'Attention:',
            quotation.client.contactPerson ?? 'Mr. : John',
          ),
          _buildInfoRow('Quotation No:', quotation.quotationNumber),
          _buildInfoRow('Contact:', quotation.client.phone ?? ''),
          _buildInfoRow(
            'Enquiry Ref:',
            quotation.enquiryRef ??
                (quotation.date != null
                    ? 'Verbal ${DateFormat("dd-MM-yyyy").format(quotation.date!)}'
                    : 'Verbal'),
          ),
          _buildInfoRow('Project:', quotation.project ?? ''),
          _buildInfoRow(
            'From:',
            '${quotation.salesPerson ?? profile?.companyName ?? ""}\nContact: ${profile?.mobile ?? profile?.phone ?? ""}',
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 100,
            padding: const pw.EdgeInsets.all(4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(right: pw.BorderSide(width: 0.5)),
            ),
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildQuotationItemsTable(Quotation quotation) {
    return pw.Table(
      border: pw.TableBorder.all(width: 2, color: PdfColors.black),
      columnWidths: {
        0: const pw.FixedColumnWidth(30), // S/N
        1: const pw.FlexColumnWidth(), // Description
        2: const pw.FixedColumnWidth(40), // Unit
        3: const pw.FixedColumnWidth(40), // Qty
        4: const pw.FixedColumnWidth(60), // Rate
        5: const pw.FixedColumnWidth(70), // Amount
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 2)),
          ),
          children: [
            _buildBoldCell('S/N'),
            _buildBoldCell('DESCRIPTION'),
            _buildBoldCell('UNIT'),
            _buildBoldCell('QTY'),
            _buildBoldCell('RATE'),
            _buildBoldCell('AMOUNT'),
          ],
        ),
        ...quotation.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildCell((index + 1).toString(), alignCenter: true),
              _buildCell(item.description),
              _buildCell(
                (item.unit == null || item.unit!.isEmpty) ? 'NOS' : item.unit!,
                alignCenter: true,
              ), // Default to NOS as per template
              _buildCell(item.quantity.toStringAsFixed(0), alignCenter: true),
              _buildCell(item.unitPrice.toStringAsFixed(2), alignCenter: true),
              _buildCell(item.total.toStringAsFixed(2), alignCenter: true),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildBoldCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
    );
  }

  static pw.Widget _buildCell(String text, {bool alignCenter = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: alignCenter
          ? pw.Center(
              child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
            )
          : pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _buildQuotationTotalSection(Quotation quotation) {
    String amountInWords = NumberToWords.convert(
      quotation.total,
      currencyCode: quotation.currency ?? 'AED',
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Amount in Words',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
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
          ),
          pw.Container(width: 2, height: 60, color: PdfColors.black),
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              children: [
                _buildTotalRow(
                  'TOTAL',
                  quotation.subtotal,
                  currency: quotation.currency ?? 'AED',
                ),
                if ((quotation.isVatApplicable ?? true) &&
                    quotation.taxAmount > 0)
                  _buildTotalRow(
                    'VAT',
                    quotation.taxAmount,
                    currency: quotation.currency ?? 'AED',
                  ),
                _buildTotalRow(
                  'NET',
                  quotation.total,
                  isBold: true,
                  currency: quotation.currency ?? 'AED',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    double value, {
    bool isBold = false,
    String? currency,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 80,
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            currency != null ? '$label ($currency)' : label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Container(width: 1, height: 20, color: PdfColors.black),
        pw.Container(
          width: 70,
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.center,
          child: pw.Text(
            CurrencyFormatter.format(value, symbol: ''),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildQuotationClosing(
    Quotation quotation,
    BusinessProfile? profile,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (quotation.termsAndConditions != null &&
            quotation.termsAndConditions!.isNotEmpty) ...[
          pw.Text(
            'Terms & Conditions',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            quotation.termsAndConditions!,
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 10),
        ],
        if (quotation.terms != null) ...[
          pw.Text(
            'Terms & Conditions',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.SizedBox(height: 5),
          pw.Text(quotation.terms!, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 20),
        ],
        pw.Text(
          'We hope our offer is most acceptable to you. However, if you have any queries, please do not hesitate to contact us.',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.Text(
          'Thanks & Regards',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
        pw.Text(
          quotation.salesPerson != null && quotation.salesPerson!.isNotEmpty
              ? '${quotation.salesPerson}\nContact: ${profile?.mobile ?? profile?.phone ?? ""}'
              : '${profile?.companyName ?? ""}\nContact: ${profile?.mobile ?? profile?.phone ?? ""}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ],
    );
  }
}
