import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/core/services/pdf/pdf_service.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart'; // Add import
import 'package:printing/printing.dart';

import 'package:flutter_invoice_app/core/services/excel/excel_service.dart';
import 'package:flutter_invoice_app/core/utils/file_utils.dart';

class PdfPreviewScreen extends ConsumerWidget {
  final Invoice invoice;
  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(businessProfileRepositoryProvider).getProfile();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_view_outlined),
            tooltip: 'Export to Excel',
            onPressed: () async {
              final bytes = await ExcelService().generateInvoice(
                invoice,
                profile: profile,
              );
              if (bytes != null) {
                await FileUtils.shareFile(
                  bytes,
                  'Invoice_${invoice.invoiceNumber}.xlsx',
                );
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) =>
            PdfService().generateInvoice(invoice, profile: profile),
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: 'Invoice_${invoice.invoiceNumber}.pdf',
      ),
    );
  }
}
