import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';
import 'package:flutter_invoice_app/features/proforma/domain/models/proforma.dart';
import 'package:intl/intl.dart';

class PdfService {
  pw.PageTheme _buildPageTheme(
    BusinessProfile? profile,
    pw.ImageProvider? image,
  ) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      buildBackground: (context) {
        if (image != null) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Opacity(
              opacity: 0.08,
              child: pw.Center(child: pw.Image(image, width: 400)),
            ),
          );
        }
        return pw.Container();
      },
    );
  }

  Future<Uint8List> generateInvoice(
    Invoice invoice, {
    BusinessProfile? profile,
  }) async {
    final pdf = pw.Document();

    final image = profile?.logoPath != null
        ? pw.MemoryImage(File(profile!.logoPath!).readAsBytesSync())
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildPageTheme(profile, image),
        build: (pw.Context context) {
          return [
            _buildHeader(invoice, profile, image),
            pw.SizedBox(height: 10),
            _buildInvoiceInfoBox(invoice, profile),
            _buildItemsTable(invoice),
            _buildTotalSection(invoice, profile),
            pw.SizedBox(height: 10),
            _buildTermsAndConditions(invoice.termsAndConditions),
            pw.Spacer(),
            _buildFooter(invoice, profile),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateQuotation(
    Quotation quotation, {
    BusinessProfile? profile,
  }) async {
    final pdf = pw.Document();

    final image = profile?.logoPath != null
        ? pw.MemoryImage(File(profile!.logoPath!).readAsBytesSync())
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildPageTheme(profile, image),
        build: (pw.Context context) {
          return [
            _buildQuotationHeader(quotation, profile, image),
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
            _buildQuotationTermsAndFooter(quotation, profile),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateLpo(Lpo lpo, {BusinessProfile? profile}) async {
    final pdf = pw.Document();

    final image = profile?.logoPath != null
        ? pw.MemoryImage(File(profile!.logoPath!).readAsBytesSync())
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildPageTheme(profile, image),
        build: (pw.Context context) {
          return [
            _buildLpoHeader(lpo, profile, image),
            pw.SizedBox(height: 10),
            _buildLpoInfoBox(lpo, profile),
            _buildLpoItemsTable(lpo),
            _buildLpoTotalSection(lpo, profile),
            pw.SizedBox(height: 10),
            _buildTermsAndConditions(lpo.termsAndConditions),
            pw.Spacer(),

            _buildLpoFooter(lpo, profile),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateProforma(
    ProformaInvoice proforma, {
    BusinessProfile? profile,
  }) async {
    final pdf = pw.Document();

    final image = profile?.logoPath != null
        ? pw.MemoryImage(File(profile!.logoPath!).readAsBytesSync())
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildPageTheme(profile, image),
        build: (pw.Context context) {
          return [
            _buildProformaHeader(proforma, profile, image),
            pw.SizedBox(height: 20),
            _buildProformaInfoBox(proforma, profile),
            pw.SizedBox(height: 15),
            _buildProformaItemsTable(proforma),
            _buildProformaTotalSection(proforma),
            pw.Spacer(),
            _buildProformaFooter(proforma, profile),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
    Invoice invoice,
    BusinessProfile? profile,
    pw.ImageProvider? image,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                if (image != null)
                  pw.Container(width: 60, height: 60, child: pw.Image(image)),
                pw.SizedBox(width: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile?.companyName.toUpperCase() ??
                          'OCEAN POWER TRADING LLC',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    if (profile?.address != null)
                      pw.Container(
                        width: 200,
                        child: pw.Text(
                          profile!.address!,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (profile?.phone != null)
                  pw.Text(
                    profile!.phone!,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.blue),
                  ),
                if (profile?.email != null)
                  pw.Text(
                    profile!.email!,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.blue),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Container(height: 2, color: PdfColors.blue900),
        pw.Container(
          width: double.infinity,
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(
            'Tax Invoice',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
        ),
        pw.Container(height: 2, color: PdfColors.blue900),
      ],
    );
  }

  pw.Widget _buildInvoiceInfoBox(Invoice invoice, BusinessProfile? profile) {
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
                _buildBoxRow('Supplier', profile?.companyName, isBold: true),
                _buildBoxRow('Address', profile?.address),
                _buildBoxRow('TRN', profile?.taxId),
                pw.Divider(height: 1, thickness: 0.5),
                _buildBoxRow('Buyer', invoice.client.name, isBold: true),
                _buildBoxRow('Address', invoice.client.address),
                _buildBoxRow('TRN', invoice.client.taxId),
                _buildBoxRow('Place of Supply', 'UAE'),
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
                      child: _buildGridItem(
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
                      child: _buildGridItem(
                        'Dated',
                        DateFormat('dd-MMM-yy').format(invoice.date),
                      ),
                    ),
                  ],
                ),
                pw.Divider(height: 1, thickness: 0.5),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildGridItem('Delivery Note', '-')),
                    pw.Container(
                      width: 0.5,
                      height: 30,
                      color: PdfColors.black,
                    ),
                    pw.Expanded(
                      child: _buildGridItem('Mode/Terms of Payment', 'Cash'),
                    ), // Placeholder
                  ],
                ),
                pw.Divider(height: 1, thickness: 0.5),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildGridItem('Supplier\'s Ref.', '-')),
                    pw.Container(
                      width: 0.5,
                      height: 30,
                      color: PdfColors.black,
                    ),
                    pw.Expanded(
                      child: _buildGridItem('Other Reference(s)', '-'),
                    ),
                  ],
                ),
                pw.Divider(height: 1, thickness: 0.5),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildGridItem('Buyer\'s Order No.', '-'),
                    ),
                    pw.Container(
                      width: 0.5,
                      height: 30,
                      color: PdfColors.black,
                    ),
                    pw.Expanded(child: _buildGridItem('Dated', '-')),
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

  pw.Widget _buildBoxRow(String label, String? value, {bool isBold = false}) {
    if (value == null) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty && label != 'Supplier' && label != 'Buyer')
            pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGridItem(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(Invoice invoice) {
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
          6: const pw.FixedColumnWidth(40), // VAT %
        },
        children: [
          // Header
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.white),
            children: [
              _buildTableCell('SI No.', isHeader: true),
              _buildTableCell('Description of Goods', isHeader: true),
              _buildTableCell('Quantity', isHeader: true),
              _buildTableCell('Rate', isHeader: true),
              _buildTableCell('per', isHeader: true),
              _buildTableCell('Amount', isHeader: true),
              _buildTableCell('VAT %', isHeader: true),
            ],
          ),
          // Rows
          ...invoice.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return pw.TableRow(
              children: [
                _buildTableCell((index + 1).toString()),
                _buildTableCell(item.description, alignLeft: true),
                _buildTableCell(
                  item.quantity.toStringAsFixed(0) + ' ' + (item.unit ?? ''),
                ),
                _buildTableCell(item.unitPrice.toStringAsFixed(2)),
                _buildTableCell(item.unit ?? '-'),
                _buildTableCell(item.total.toStringAsFixed(2)),
                _buildTableCell('5%'), // Assuming 5% as per image example
              ],
            );
          }).toList(),
          // Add some empty rows to fill space if needed, or just a bottom border
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool alignLeft = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        maxLines: 2,
        textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildTotalSection(Invoice invoice, BusinessProfile? profile) {
    // Basic Number to Words (Simplified)
    String amountInWords =
        'UAE Dirham ${invoice.total.toStringAsFixed(2)} Only';
    // Creating a proper converter is complex, using placeholder or simple string for now.

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(width: 0.5),
          right: pw.BorderSide(width: 0.5),
          bottom: pw.BorderSide(width: 0.5),
        ),
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
          pw.Container(width: 0.5, height: 40, color: PdfColors.black),
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Total', style: const pw.TextStyle(fontSize: 9)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'AED ${invoice.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
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

  pw.Widget _buildFooter(Invoice invoice, BusinessProfile? profile) {
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
                      'for ${profile?.companyName ?? "OCEAN POWER TRADING LLC"}',
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
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.blue900),
        pw.Center(
          child: pw.Text(
            '${profile?.companyName ?? "Ocean Power Trading LLC"}, ${profile?.address ?? "Muweilah, Sharjah"} | ${profile?.phone ?? ""}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue900),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'This is a Computer Generated Invoice',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ],
    );
  }

  // LPO Specific Builders

  pw.Widget _buildLpoHeader(
    Lpo lpo,
    BusinessProfile? profile,
    pw.ImageProvider? image,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                if (image != null)
                  pw.Container(width: 60, height: 60, child: pw.Image(image)),
                pw.SizedBox(width: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile?.companyName.toUpperCase() ??
                          'OCEAN POWER TRADING LLC',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    if (profile?.address != null)
                      pw.Container(
                        width: 200,
                        child: pw.Text(
                          profile!.address!,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (profile?.phone != null)
                  pw.Text(
                    profile!.phone!,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.blue),
                  ),
                if (profile?.email != null)
                  pw.Text(
                    profile!.email!,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.blue),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Container(height: 2, color: PdfColors.blue900),
        pw.Container(
          width: double.infinity,
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(
            'Local Purchase Order',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
        ),
        pw.Container(height: 2, color: PdfColors.blue900),
      ],
    );
  }

  pw.Widget _buildLpoInfoBox(Lpo lpo, BusinessProfile? profile) {
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
                _buildBoxRow('Supplier', lpo.vendor.name, isBold: true),
                _buildBoxRow('Address', lpo.vendor.address),
                _buildBoxRow('TRN', lpo.vendor.taxId),
                pw.Divider(height: 1, thickness: 0.5),
                // In LPO: Buyer is Us (Profile)
                _buildBoxRow('Buyer', profile?.companyName, isBold: true),
                _buildBoxRow('Address', profile?.address),
                _buildBoxRow('TRN', profile?.taxId),
                _buildBoxRow('Place of Supply', 'UAE'),
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
                      child: _buildGridItem(
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
                      child: _buildGridItem(
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
                      child: _buildGridItem(
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
                      child: _buildGridItem('Mode/Terms of Payment', 'Credit'),
                    ), // Placeholder
                  ],
                ),
                pw.Divider(height: 1, thickness: 0.5),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildGridItem('Other Reference', '-')),
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
                        lpo.terms ?? '-',
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

  pw.Widget _buildLpoItemsTable(Lpo lpo) {
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
            decoration: const pw.BoxDecoration(color: PdfColors.white),
            children: [
              _buildTableCell('SI No.', isHeader: true),
              _buildTableCell('Description of Goods', isHeader: true),
              _buildTableCell('Quantity', isHeader: true),
              _buildTableCell('Rate', isHeader: true),
              _buildTableCell('per', isHeader: true),
              _buildTableCell('Amount', isHeader: true),
            ],
          ),
          // Rows
          ...lpo.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return pw.TableRow(
              children: [
                _buildTableCell((index + 1).toString()),
                _buildTableCell(item.description, alignLeft: true),
                _buildTableCell(
                  item.quantity.toStringAsFixed(0) + ' ' + (item.unit ?? ''),
                ),
                _buildTableCell(item.unitPrice.toStringAsFixed(2)),
                _buildTableCell(item.unit ?? '-'),
                _buildTableCell(item.total.toStringAsFixed(2)),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  pw.Widget _buildLpoTotalSection(Lpo lpo, BusinessProfile? profile) {
    String amountInWords = 'UAE Dirham ${lpo.total.toStringAsFixed(2)} Only';

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(width: 0.5),
          right: pw.BorderSide(width: 0.5),
          bottom: pw.BorderSide(width: 0.5),
        ),
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
          pw.Container(width: 0.5, height: 40, color: PdfColors.black),
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 9)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'AED ${lpo.subtotal.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (lpo.taxAmount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text('VAT', style: const pw.TextStyle(fontSize: 9)),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'AED ${lpo.taxAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                pw.Divider(height: 1, thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Total', style: const pw.TextStyle(fontSize: 9)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'AED ${lpo.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
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

  pw.Widget _buildLpoFooter(Lpo lpo, BusinessProfile? profile) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
              width: 200,
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
                      'for ${profile?.companyName ?? "OCEAN POWER TRADING LLC"}',
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
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.blue900),
        pw.Center(
          child: pw.Text(
            '${profile?.companyName ?? "Ocean Power Trading LLC"}, ${profile?.address ?? "Muweilah, Sharjah"} | ${profile?.phone ?? ""}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue900),
          ),
        ),
      ],
    );
  }
  // Quotation Specific Builders

  pw.Widget _buildQuotationHeader(
    Quotation quotation,
    BusinessProfile? profile,
    pw.ImageProvider? image,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (image != null)
                  pw.Container(
                    width: 70,
                    height: 70,
                    child: pw.Image(image),
                    margin: const pw.EdgeInsets.only(right: 15),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile?.companyName.toUpperCase() ??
                          'OCEAN POWER TRADING LLC',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Container(
                      height: 3,
                      width: 250,
                      color: PdfColors.blue900,
                      margin: const pw.EdgeInsets.only(top: 2),
                    ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (profile?.phone != null)
                  pw.Text(
                    profile!.phone!,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.blue900),
                  ),
                if (profile?.email != null)
                  pw.Text(
                    'info@oceanpowertradingllc.com', // Using standard format or data
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.blue900),
                  ),
                pw.Text(
                  'www.oceanpowertradingllc.com',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.blue900),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          height: 2,
          color: PdfColors.blue900,
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'QUOTATION',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildQuotationInfoBox(
    Quotation quotation,
    BusinessProfile? profile,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Column(
        children: [
          _buildInfoRow('Date', DateFormat('d/M/yyyy').format(quotation.date)),
          _buildInfoRow('Company:', quotation.client.name),
          _buildInfoRow(
            'Attention:',
            quotation.client.contactPerson ?? 'Mr. : John',
          ),
          _buildInfoRow('Quotation No:', quotation.quotationNumber),
          _buildInfoRow('Mobile:', quotation.client.phone ?? ''),
          _buildInfoRow(
            'Enquiry Ref:',
            quotation.enquiryRef ??
                'Verbal ${DateFormat("dd-MM-yyyy").format(quotation.date)}',
          ),
          _buildInfoRow('Project:', quotation.project ?? ''),
          _buildInfoRow(
            'From:',
            'Sunil PV, Mob: +971569016267', // Hardcoded as per template request or dynamic
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
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

  pw.Widget _buildQuotationItemsTable(Quotation quotation) {
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
                'NOS',
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

  pw.Widget _buildBoldCell(String text) {
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

  pw.Widget _buildCell(String text, {bool alignCenter = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: alignCenter
          ? pw.Center(
              child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
            )
          : pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  pw.Widget _buildQuotationTotalSection(Quotation quotation) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Column(
        children: [
          _buildTotalRow('TOTAL', quotation.subtotal),
          _buildTotalRow('VAT', quotation.taxAmount),
          _buildTotalRow('NET', quotation.total, isBold: true),
        ],
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, double value, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 80,
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            label,
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
            value.toStringAsFixed(2),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildQuotationTermsAndFooter(
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
          'Sunil PV\nSr. Sales Executive\nMobile: 0569016267',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 3,
          width: double.infinity,
          color: PdfColors.blue, // Banner bottom like structure
        ),
        pw.Container(
          height: 3,
          width: double.infinity,
          color: PdfColors.blue900,
          margin: const pw.EdgeInsets.only(left: 100),
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'Ocean Power Trading LLC,',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Muweilah , Sharjah | Mob & WhatsApp : +971522660055',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'For enquiries, kindly mail to : info@oceanpowertradingllc.com | web : www.oceanpowertradingllc.com',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Proforma Specific Builders

  pw.Widget _buildProformaHeader(
    ProformaInvoice proforma,
    BusinessProfile? profile,
    pw.ImageProvider? image,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (image != null)
                  pw.Container(
                    width: 70,
                    height: 70,
                    child: pw.Image(image),
                    margin: const pw.EdgeInsets.only(right: 15),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile?.companyName.toUpperCase() ??
                          'OCEAN POWER TRADING LLC',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Container(
                      height: 3,
                      width: 250,
                      color: PdfColors.blue900,
                      margin: const pw.EdgeInsets.only(top: 2),
                    ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (profile?.phone != null)
                  pw.Text(
                    profile!.phone!,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.blue900),
                  ),
                if (profile?.email != null)
                  pw.Text(
                    'info@oceanpowertradingllc.com',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.blue900),
                  ),
                pw.Text(
                  'www.oceanpowertradingllc.com',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.blue900),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          height: 2,
          color: PdfColors.blue900,
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'PROFORMA INVOICE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildProformaInfoBox(
    ProformaInvoice proforma,
    BusinessProfile? profile,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Column(
        children: [
          _buildInfoRow('Date', DateFormat('d/M/yyyy').format(proforma.date)),
          _buildInfoRow('Company:', proforma.client.name),
          _buildInfoRow(
            'Attention:',
            proforma.client.contactPerson ?? 'Mr. : John',
          ),
          _buildInfoRow('Proforma No:', proforma.proformaNumber),
          _buildInfoRow('Mobile:', proforma.client.phone ?? ''),
          // _buildInfoRow('Project:', proforma.project ?? ''), // If added to model
          _buildInfoRow('From:', 'Sunil PV, Mob: +971569016267'),
        ],
      ),
    );
  }

  pw.Widget _buildProformaItemsTable(ProformaInvoice proforma) {
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
        ...proforma.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildCell((index + 1).toString(), alignCenter: true),
              _buildCell(item.description),
              _buildCell(
                'NOS',
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

  pw.Widget _buildProformaTotalSection(ProformaInvoice proforma) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Column(
        children: [
          _buildTotalRow('TOTAL', proforma.subtotal),
          _buildTotalRow('VAT', proforma.taxAmount),
          _buildTotalRow('NET', proforma.total, isBold: true),
        ],
      ),
    );
  }

  pw.Widget _buildProformaFooter(
    ProformaInvoice proforma,
    BusinessProfile? profile,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (proforma.termsAndConditions != null &&
            proforma.termsAndConditions!.isNotEmpty) ...[
          pw.Text(
            'Terms & Conditions',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            proforma.termsAndConditions!,
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 10),
        ],
        if (proforma.terms != null) ...[
          pw.Text(
            'Terms & Conditions',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.SizedBox(height: 5),
          pw.Text(proforma.terms!, style: const pw.TextStyle(fontSize: 9)),
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
          'Sunil PV\nSr. Sales Executive\nMobile: 0569016267',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 3,
          width: double.infinity,
          color: PdfColors.blue, // Banner bottom like structure
        ),
        pw.Container(
          height: 3,
          width: double.infinity,
          color: PdfColors.blue900,
          margin: const pw.EdgeInsets.only(left: 100),
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'Ocean Power Trading LLC,',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Muweilah , Sharjah | Mob & WhatsApp : +971522660055',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'For enquiries, kindly mail to : info@oceanpowertradingllc.com | web : www.oceanpowertradingllc.com',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTermsAndConditions(String? terms) {
    if (terms == null || terms.isEmpty) return pw.Container();
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Terms & Conditions',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.SizedBox(height: 5),
          pw.Text(terms, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}
