import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';
import 'package:flutter_invoice_app/features/invoice/domain/services/pdf_service.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';
import 'package:printing/printing.dart';

class LpoPdfPreviewScreen extends ConsumerWidget {
  final Lpo lpo;
  const LpoPdfPreviewScreen({super.key, required this.lpo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(businessProfileRepositoryProvider).getProfile();

    return Scaffold(
      appBar: AppBar(title: const Text('LPO Preview')),
      body: PdfPreview(
        build: (format) => PdfService().generateLpo(lpo, profile: profile),
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}
