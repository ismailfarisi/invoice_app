import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/proforma/domain/models/proforma.dart';
import 'package:flutter_invoice_app/core/services/pdf/pdf_service.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';
import 'package:printing/printing.dart';

class ProformaPdfPreviewScreen extends ConsumerWidget {
  final ProformaInvoice proforma;
  const ProformaPdfPreviewScreen({super.key, required this.proforma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(businessProfileRepositoryProvider).getProfile();

    return Scaffold(
      appBar: AppBar(title: const Text('Proforma Invoice Preview')),
      body: PdfPreview(
        build: (format) =>
            PdfService().generateProforma(proforma, profile: profile),
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}
