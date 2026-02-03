import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/core/utils/number_to_words.dart';
import '../widgets/pdf_styles.dart';
import '../widgets/pdf_headers.dart';
import '../widgets/pdf_footers.dart';
import '../widgets/pdf_common_widgets.dart';

class InvoicePdfGenerator {
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
        header: (context) =>
            PdfHeaders.buildInvoiceHeader(profile, image, 'Tax Invoice'),
        footer: (context) => PdfFooters.buildCommonPageFooter(
          profile,
          'This is a Computer Generated Invoice',
        ),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 10),
            _buildInvoiceInfoBox(invoice, profile),
            _buildItemsTable(invoice),
            _buildTotalSection(invoice, profile),
            pw.SizedBox(height: 10),
            PdfCommonWidgets.buildTermsAndConditions(
              invoice.termsAndConditions,
            ),
            pw.Spacer(),
            _buildInvoiceSignatures(invoice, profile),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInvoiceInfoBox(
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
                PdfCommonWidgets.buildBoxRow('TRN', profile?.taxId),
                pw.Divider(height: 1, thickness: 0.5),
                PdfCommonWidgets.buildBoxRow(
                  'Buyer',
                  invoice.client.name,
                  isBold: true,
                ),
                PdfCommonWidgets.buildBoxRow('Address', invoice.client.address),
                PdfCommonWidgets.buildBoxRow('TRN', invoice.client.taxId),
                PdfCommonWidgets.buildBoxRow(
                  'Place of Supply',
                  invoice.placeOfSupply ?? 'UAE',
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
                        'Invoice No.',
                        invoice.invoiceNumber,
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
                        'Delivery Note',
                        invoice.deliveryNote ?? '-',
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
                        invoice.paymentTerms ?? 'Cash',
                      ),
                    ),
                  ],
                ),
                pw.Divider(height: 1, thickness: 0.5),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: PdfCommonWidgets.buildGridItem(
                        'Supplier\'s Ref.',
                        invoice.supplierReference ?? '-',
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
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: PdfCommonWidgets.buildGridItem(
                        'Buyer\'s Order No.',
                        invoice.buyersOrderNumber ?? '-',
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
                        invoice.buyersOrderDate != null
                            ? DateFormat(
                                'dd-MMM-yy',
                              ).format(invoice.buyersOrderDate!)
                            : '-',
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

  static pw.Widget _buildItemsTable(Invoice invoice) {
    final isVat = invoice.isVatApplicable ?? true;
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
          if (isVat) 6: const pw.FixedColumnWidth(40), // VAT %
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
              if (isVat)
                PdfCommonWidgets.buildTableCell('VAT %', isHeader: true),
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
                if (isVat)
                  PdfCommonWidgets.buildTableCell('10%'), // 10% for Invoice
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalSection(
    Invoice invoice,
    BusinessProfile? profile,
  ) {
    // Basic Number to Words
    String amountInWords = NumberToWords.convert(
      invoice.total,
      currencyCode: invoice.currency ?? 'AED',
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
                  invoice.subtotal,
                  currency: invoice.currency ?? 'AED',
                ),
                if ((invoice.isVatApplicable ?? true) && invoice.taxAmount > 0)
                  _buildTotalRow(
                    'VAT (10%)',
                    invoice.taxAmount,
                    currency: invoice.currency ?? 'AED',
                  ),
                _buildTotalRow(
                  'Total',
                  invoice.total,
                  isBold: true,
                  currency: invoice.currency ?? 'AED',
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

  static pw.Widget _buildInvoiceSignatures(
    Invoice invoice,
    BusinessProfile? profile,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (profile?.bankDetails != null) ...[
                    pw.Text(
                      'Company\'s Bank Details',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      profile!.bankDetails!
                          .replaceAll('Bank Name:', 'Bank Name\t :')
                          .replaceAll('Account:', 'A/c No.\t :')
                          .replaceAll('IFSC:', 'Sort Code\t :'),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Declaration',
                    style: pw.TextStyle(
                      fontSize: 8,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.Text(
                    'We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.',
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
                      'for ${profile?.companyName ?? ""}\n\n\n${invoice.salesPerson ?? "Authorized Signatory"}',
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
        ),
      ],
    );
  }
}
