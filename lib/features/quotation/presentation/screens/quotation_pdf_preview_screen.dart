import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/features/invoice/domain/services/pdf_service.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';
import 'package:printing/printing.dart';

class QuotationPdfPreviewScreen extends ConsumerWidget {
  final Quotation quotation;
  const QuotationPdfPreviewScreen({super.key, required this.quotation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(businessProfileRepositoryProvider).getProfile();

    return Scaffold(
      appBar: AppBar(title: const Text('Quotation Preview')),
      body: PdfPreview(
        build: (format) =>
            PdfService().generateQuotation(quotation, profile: profile),
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}
