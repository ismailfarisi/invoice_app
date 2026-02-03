import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/core/utils/number_to_words.dart';
import '../widgets/pdf_styles.dart';
import '../widgets/pdf_headers.dart';
import '../widgets/pdf_common_widgets.dart';

class LpoPdfGenerator {
  static Future<Uint8List> generate(Lpo lpo, {BusinessProfile? profile}) async {
    final pdf = pw.Document();

    final image = profile?.logoPath != null
        ? pw.MemoryImage(File(profile!.logoPath!).readAsBytesSync())
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: PdfStyles.buildPageTheme(profile, image),
        header: (context) => PdfHeaders.buildLpoHeader(profile, image),
        footer: (context) => _buildLpoPageFooter(profile),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 10),
            _buildLpoInfoBox(lpo, profile),
            _buildLpoItemsTable(lpo),
            _buildLpoTotalSection(lpo, profile),
            _buildLpoTermsOfDelivery(lpo),
            pw.SizedBox(height: 10),
            PdfCommonWidgets.buildTermsAndConditions(lpo.termsAndConditions),
            pw.Spacer(),
            _buildLpoSignatures(lpo, profile),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildLpoInfoBox(Lpo lpo, BusinessProfile? profile) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left Column
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // In LPO: Supplier is the Vendor
                PdfCommonWidgets.buildBoxRow(
                  'Supplier',
                  lpo.vendor.name,
                  isBold: true,
                ),
                PdfCommonWidgets.buildBoxRow('Address', lpo.vendor.address),
                PdfCommonWidgets.buildBoxRow('TRN', lpo.vendor.taxId),
                pw.Divider(height: 1, thickness: 0.5),
                // In LPO: Buyer is Us (Profile)
                PdfCommonWidgets.buildBoxRow(
                  'Buyer',
                  profile?.companyName,
                  isBold: true,
                ),
                PdfCommonWidgets.buildBoxRow('Address', profile?.address),
                PdfCommonWidgets.buildBoxRow('TRN', profile?.taxId),
                PdfCommonWidgets.buildBoxRow(
                  'Place of Supply',
                  lpo.placeOfSupply ?? 'UAE',
                ),
              ],
            ),
          ),
          // Vertical Divider
          pw.Container(width: 0.5, height: 180, color: PdfColors.black),
          // Right Column
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: PdfCommonWidgets.buildGridItem(
                        'LPO No.',
                        lpo.lpoNumber,
                        isBold: true,
                      ),
                    ),
                    pw.Container(
                      width: 0.5,
                      height: 30,
                      color: PdfColors.black,
                    ),
                    pw.Expanded(
                      child: PdfCommonWidgets.buildGridItem(
                        'Dated',
                        DateFormat('dd-MMM-yy').format(lpo.date),
                      ),
                    ),
                  ],
                ),
                pw.Divider(height: 1, thickness: 0.5),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: PdfCommonWidgets.buildGridItem(
                        'Delivery Date',
                        lpo.expectedDeliveryDate != null
                            ? DateFormat(
                                'dd-MMM-yy',
                              ).format(lpo.expectedDeliveryDate!)
                            : '-',
                      ),
                    ),
                    pw.Container(
                      width: 0.5,
                      height: 30,
                      color: PdfColors.black,
                    ),
                    pw.Expanded(
                      child: PdfCommonWidgets.buildGridItem(
                        'Mode/Terms of Payment',
                        lpo.paymentTerms ?? 'Credit',
                      ),
                    ),
                  ],
                ),
                pw.Divider(height: 1, thickness: 0.5),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: PdfCommonWidgets.buildGridItem(
                        'Other Reference',
                        lpo.otherReference ?? '-',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLpoItemsTable(Lpo lpo) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(width: 0.5),
          right: pw.BorderSide(width: 0.5),
          bottom: pw.BorderSide(width: 0.5),
        ),
      ),
      child: pw.Table(
        border: pw.TableBorder.symmetric(inside: pw.BorderSide(width: 0.5)),
        columnWidths: {
          0: const pw.FixedColumnWidth(30), // SI No
          1: const pw.FlexColumnWidth(4), // Description
          2: const pw.FixedColumnWidth(50), // Quantity
          3: const pw.FixedColumnWidth(60), // Rate
          4: const pw.FixedColumnWidth(40), // Per
          5: const pw.FixedColumnWidth(70), // Amount
        },
        children: [
          // Header
          pw.TableRow(
            // Removed decoration as per user preference
            children: [
              PdfCommonWidgets.buildTableCell('SI No.', isHeader: true),
              PdfCommonWidgets.buildTableCell(
                'Description of Goods',
                isHeader: true,
              ),
              PdfCommonWidgets.buildTableCell('Quantity', isHeader: true),
              PdfCommonWidgets.buildTableCell('Rate', isHeader: true),
              PdfCommonWidgets.buildTableCell('per', isHeader: true),
              PdfCommonWidgets.buildTableCell('Amount', isHeader: true),
            ],
          ),
          // Rows
          ...lpo.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return pw.TableRow(
              children: [
                PdfCommonWidgets.buildTableCell((index + 1).toString()),
                PdfCommonWidgets.buildTableCell(
                  item.description,
                  alignLeft: true,
                ),
                PdfCommonWidgets.buildTableCell(
                  item.quantity.toStringAsFixed(0),
                ),
                PdfCommonWidgets.buildTableCell(
                  item.unitPrice.toStringAsFixed(2),
                ),
                PdfCommonWidgets.buildTableCell(
                  (item.unit == null || item.unit!.isEmpty)
                      ? 'NOS'
                      : item.unit!,
                ),
                PdfCommonWidgets.buildTableCell(item.total.toStringAsFixed(2)),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  static pw.Widget _buildLpoTotalSection(Lpo lpo, BusinessProfile? profile) {
    String amountInWords = NumberToWords.convert(
      lpo.total,
      currencyCode: lpo.currency ?? 'AED',
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
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
                    'Amount Chargeable (in words)',
                    style: pw.TextStyle(fontSize: 8),
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
          pw.Container(width: 0.5, height: 60, color: PdfColors.black),
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              children: [
                _buildTotalRow(
                  'Subtotal',
                  lpo.subtotal,
                  currency: lpo.currency ?? 'AED',
                ),
                if ((lpo.isVatApplicable ?? true) && lpo.taxAmount > 0)
                  _buildTotalRow(
                    'VAT',
                    lpo.taxAmount,
                    currency: lpo.currency ?? 'AED',
                  ),
                _buildTotalRow(
                  'Total',
                  lpo.total,
                  currency: lpo.currency ?? 'AED',
                  isBold: true,
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
        pw.Container(width: 0.5, height: 20, color: PdfColors.black),
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

  static pw.Widget _buildLpoSignatures(Lpo lpo, BusinessProfile? profile) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
              width: 200,
              padding: const pw.EdgeInsets.only(left: 5, top: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Remarks',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    lpo.notes ?? '',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
            pw.Container(
              width: 200,
              child: pw.Column(
                children: [
                  pw.Container(
                    height: 60,
                    alignment: pw.Alignment.topCenter,
                    child: pw.Text(
                      'for ${profile?.companyName ?? ""}\n\n\n${lpo.salesPerson ?? "Authorised Signatory"}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
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
        ),
      ],
    );
  }

  static pw.Widget _buildLpoTermsOfDelivery(Lpo lpo) {
    if (lpo.terms == null || lpo.terms!.isEmpty) return pw.Container();
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: 'Terms of Delivery\n',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
            pw.TextSpan(text: '\n', style: const pw.TextStyle(fontSize: 5)),
            pw.TextSpan(
              text: lpo.terms!,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildLpoPageFooter(BusinessProfile? profile) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.blue900),
        pw.Center(
          child: pw.Text(
            '${profile?.companyName ?? ""}, ${profile?.address ?? ""} | ${profile?.phone ?? ""} ${profile?.mobile != null ? "| " + profile!.mobile! : ""} ${profile?.email != null ? "| " + profile!.email! : ""} ${profile?.website != null ? "| " + profile!.website! : ""}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue900),
          ),
        ),
      ],
    );
  }
}
