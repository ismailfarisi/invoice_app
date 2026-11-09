import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/core/services/pdf/pdf_service.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';
import 'package:printing/printing.dart';

import 'package:flutter_invoice_app/core/services/excel/excel_service.dart';
import 'package:flutter_invoice_app/core/utils/file_utils.dart';

class PdfPreviewScreen extends ConsumerStatefulWidget {
  final Invoice invoice;
  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  ConsumerState<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends ConsumerState<PdfPreviewScreen> {
  bool _exporting = false;

  String get _safeNumber =>
      widget.invoice.invoiceNumber.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');

  Future<void> _exportExcel() async {
    if (_exporting) return;
    final profile = ref.read(businessProfileRepositoryProvider).getProfile();
    setState(() => _exporting = true);
    try {
      final bytes = await ExcelService().generateInvoice(
        widget.invoice,
        profile: profile,
      );
      if (bytes == null) {
        throw StateError('No data produced');
      }
      await FileUtils.shareFile(bytes, 'Invoice_$_safeNumber.xlsx');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not export to Excel. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(businessProfileRepositoryProvider).getProfile();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        actions: [
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.table_view_outlined),
            tooltip: 'Export to Excel',
            onPressed: _exporting ? null : _exportExcel,
          ),
        ],
      ),
      body: SafeArea(
        child: PdfPreview(
          build: (format) =>
              PdfService().generateInvoice(widget.invoice, profile: profile),
          canChangeOrientation: false,
          canDebug: false,
          pdfFileName: 'Invoice_$_safeNumber.pdf',
        ),
      ),
    );
  }
}
