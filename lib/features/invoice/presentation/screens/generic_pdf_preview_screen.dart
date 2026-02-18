import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

class GenericPdfPreviewScreen extends ConsumerWidget {
  final String title;
  final LayoutCallback buildEvent;
  final VoidCallback? onExportExcel;

  final String? pdfFileName;

  const GenericPdfPreviewScreen({
    super.key,
    required this.title,
    required this.buildEvent,
    this.onExportExcel,
    this.pdfFileName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onExportExcel != null)
            IconButton(
              icon: const Icon(Icons.table_view_outlined),
              tooltip: 'Export to Excel',
              onPressed: onExportExcel,
            ),
        ],
      ),
      body: SafeArea(
        child: PdfPreview(
          build: buildEvent,
          canChangeOrientation: false,
          canDebug: false,
          pdfFileName: pdfFileName,
        ),
      ),
    );
  }
}
