import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../widgets/pdf_styles.dart';
import '../widgets/pdf_headers.dart';
import '../widgets/pdf_footers.dart';
import '../widgets/pdf_common_widgets.dart';

class DeliveryNotePdfGenerator {
  static Future<Uint8List> generate(
    Invoice invoice, {
    BusinessProfile? profile,
  }) async {
    final pdf = pw.Document();

    final image = profile?.logoPath != null
        ? pw.MemoryImage(File(profile!.logoPath!).readAsBytesSync())
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: PdfStyles.buildPageTheme(profile, image),
        header: (context) => PdfHeaders.buildDeliveryNoteHeader(profile, image),
        footer: (context) => PdfFooters.buildCommonPageFooter(
          profile,
          'This is a Computer Generated Delivery Note',
        ),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 10),
            _buildDeliveryNoteInfoBox(invoice, profile),
            _buildDeliveryNoteItemsTable(invoice),
            pw.SizedBox(height: 10),
            if (invoice.terms != null) ...[
              pw.Text(
                'Terms & Conditions:',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(invoice.terms!, style: const pw.TextStyle(fontSize: 8)),
            ],
            pw.Spacer(),
            _buildDeliveryNoteSignatures(invoice, profile),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildDeliveryNoteInfoBox(
    Invoice invoice,
    BusinessProfile? profile,
  ) {
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
                PdfCommonWidgets.buildBoxRow(
                  'Supplier',
                  profile?.companyName,
                  isBold: true,
                ),
                PdfCommonWidgets.buildBoxRow('Address', profile?.address),
                pw.Divider(height: 1, thickness: 0.5),
                PdfCommonWidgets.buildBoxRow(
                  'Buyer',
                  invoice.client.name,
                  isBold: true,
                ),
                PdfCommonWidgets.buildBoxRow('Address', invoice.client.address),
                PdfCommonWidgets.buildBoxRow(
                  'Place of Supply',
                  invoice.placeOfSupply ?? 'UAE',
                ),
              ],
            ),
          ),
          // Vertical Divider
          pw.Container(width: 0.5, height: 100, color: PdfColors.black),
          // Right Column
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: PdfCommonWidgets.buildGridItem(
                        'Delivery Note No.',
                        'DN-${invoice.invoiceNumber}',
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
                        DateFormat('dd-MMM-yy').format(invoice.date),
                      ),
                    ),
                  ],
                ),
                pw.Divider(height: 1, thickness: 0.5),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: PdfCommonWidgets.buildGridItem(
                        'Invoice Ref.',
                        invoice.invoiceNumber,
                      ),
                    ),
                    pw.Container(
                      width: 0.5,
                      height: 30,
                      color: PdfColors.black,
                    ),
                    pw.Expanded(
                      child: PdfCommonWidgets.buildGridItem(
                        'Other Reference(s)',
                        invoice.otherReference ?? '-',
                      ),
                    ),
                  ],
                ),
                pw.Divider(height: 1, thickness: 0.5),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Terms of Delivery',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        invoice.terms ?? '-',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDeliveryNoteItemsTable(Invoice invoice) {
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
          2: const pw.FixedColumnWidth(70), // Quantity
          3: const pw.FixedColumnWidth(70), // Per
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
              PdfCommonWidgets.buildTableCell('per', isHeader: true),
            ],
          ),
          // Rows
          ...invoice.items.asMap().entries.map((entry) {
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
                  item.quantity.toStringAsFixed(0) + ' ' + (item.unit ?? ''),
                ),
                PdfCommonWidgets.buildTableCell(item.unit ?? '-'),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  static pw.Widget _buildDeliveryNoteSignatures(
    Invoice invoice,
    BusinessProfile? profile,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Received By:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(width: 0.5)),
                  ),
                  child: pw.Text(
                    'Name & Signature',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              ],
            ),
            pw.Column(
              children: [
                pw.Container(
                  height: 50,
                  alignment: pw.Alignment.bottomCenter,
                  child: pw.Text(
                    'for ${profile?.companyName ?? ""}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(width: 0.5)),
                  ),
                  child: pw.Text(
                    'Authorized Signatory',
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
