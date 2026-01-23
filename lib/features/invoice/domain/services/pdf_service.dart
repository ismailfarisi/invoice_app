import 'dart:typed_data';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart'; // Add import
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_invoice_app/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class PdfService {
  Future<Uint8List> generateInvoice(
    Invoice invoice, {
    BusinessProfile? profile,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(invoice, profile),
            pw.SizedBox(height: 20),
            _buildTable(invoice),
            pw.Divider(),
            _buildTotal(invoice),
            pw.SizedBox(height: 20),
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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildQuotationHeader(quotation, profile),
            pw.SizedBox(height: 20),
            _buildQuotationTable(quotation),
            pw.Divider(),
            _buildQuotationTotal(quotation),
            pw.SizedBox(height: 20),
            _buildQuotationFooter(quotation, profile),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildQuotationHeader(
    Quotation quotation,
    BusinessProfile? profile,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              profile?.companyName ?? 'QUOTATION',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal,
              ),
            ),
            if (profile != null) ...[
              pw.Text(profile.email ?? ''),
              pw.Text(profile.phone ?? ''),
              if (profile.address != null)
                pw.SizedBox(width: 150, child: pw.Text(profile.address!)),
            ],
            pw.SizedBox(height: 20),
            pw.Text(
              'QUOTATION # ${quotation.quotationNumber}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Date: ${DateFormat.yMMMd().format(quotation.date)}'),
            if (quotation.validUntil != null)
              pw.Text(
                'Valid Until: ${DateFormat.yMMMd().format(quotation.validUntil!)}',
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildQuotationTable(Quotation quotation) {
    return pw.TableHelper.fromTextArray(
      headers: ['Description', 'Qty', 'Unit Price', 'Total'],
      data: quotation.items.map((item) {
        return [
          item.description,
          item.quantity.toString(),
          CurrencyFormatter.format(item.unitPrice),
          CurrencyFormatter.format(item.total),
        ];
      }).toList(),
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _buildQuotationTotal(Quotation quotation) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Subtotal: ${CurrencyFormatter.format(quotation.subtotal)}',
            ),
            pw.Text('Tax: ${CurrencyFormatter.format(quotation.taxAmount)}'),
            pw.Text(
              'Total: ${CurrencyFormatter.format(quotation.total)}',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildQuotationFooter(
    Quotation quotation,
    BusinessProfile? profile,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (quotation.notes != null) ...[
          pw.Text(
            'Notes:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(quotation.notes!),
          pw.SizedBox(height: 10),
        ],
        if (quotation.terms != null) ...[
          pw.Text(
            'Terms & Conditions:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(quotation.terms!),
          pw.SizedBox(height: 10),
        ],
        pw.Center(
          child: pw.Text(
            'Valid for 30 days unless otherwise specified.',
            style: pw.TextStyle(font: pw.Font.helveticaOblique(), fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildHeader(Invoice invoice, BusinessProfile? profile) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              profile?.companyName ?? 'INVOICE',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal,
              ),
            ),
            if (profile != null) ...[
              pw.Text(profile.email ?? ''),
              pw.Text(profile.phone ?? ''),
              if (profile.address != null)
                pw.SizedBox(width: 150, child: pw.Text(profile.address!)),
            ],
            pw.SizedBox(height: 20),
            pw.Text(
              'INVOICE # ${invoice.invoiceNumber}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Date: ${DateFormat.yMMMd().format(invoice.date)}'),
            if (invoice.dueDate != null)
              pw.Text('Due: ${DateFormat.yMMMd().format(invoice.dueDate!)}'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Bill To:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(invoice.client.name),
            if (invoice.client.address != null)
              pw.Text(invoice.client.address!),
            pw.Text(invoice.client.email),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTable(Invoice invoice) {
    return pw.TableHelper.fromTextArray(
      headers: ['Description', 'Qty', 'Unit Price', 'Total'],
      data: invoice.items.map((item) {
        return [
          item.description,
          item.quantity.toString(),
          CurrencyFormatter.format(item.unitPrice),
          CurrencyFormatter.format(item.total),
        ];
      }).toList(),
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _buildTotal(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(
          height: 70,
          width: 70,
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data:
                'Invoice ${invoice.invoiceNumber} Total: ${CurrencyFormatter.format(invoice.total)}',
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Subtotal: ${CurrencyFormatter.format(invoice.subtotal)}'),
            pw.Text('Tax: ${CurrencyFormatter.format(invoice.taxAmount)}'),
            pw.Text(
              'Total: ${CurrencyFormatter.format(invoice.total)}',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFooter(Invoice invoice, BusinessProfile? profile) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (profile?.bankDetails != null) ...[
          pw.Text(
            'Payment Information:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(profile!.bankDetails!),
          pw.SizedBox(height: 10),
        ],
        if (invoice.notes != null) ...[
          pw.Text(
            'Notes:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(invoice.notes!),
          pw.SizedBox(height: 10),
        ],
        pw.Center(
          child: pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(font: pw.Font.helveticaOblique()),
          ),
        ),
      ],
    );
  }
}
