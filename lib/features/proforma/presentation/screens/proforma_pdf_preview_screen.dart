import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/proforma/domain/models/proforma.dart';
import 'package:flutter_invoice_app/core/services/pdf/pdf_service.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';

import 'package:flutter_invoice_app/features/invoice/presentation/screens/generic_pdf_preview_screen.dart';
import 'package:flutter_invoice_app/core/services/excel/excel_service.dart';
import 'package:flutter_invoice_app/core/utils/file_utils.dart';

class ProformaPdfPreviewScreen extends ConsumerWidget {
  final ProformaInvoice proforma;
  const ProformaPdfPreviewScreen({super.key, required this.proforma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(businessProfileRepositoryProvider).getProfile();

    return GenericPdfPreviewScreen(
      title: 'Proforma Invoice Preview',
      pdfFileName: 'Proforma_${proforma.proformaNumber}.pdf',
      buildEvent: (format) =>
          PdfService().generateProforma(proforma, profile: profile),
      onExportExcel: () async {
        final bytes = await ExcelService().generateProforma(
          proforma,
          profile: profile,
        );
        if (bytes != null) {
          await FileUtils.shareFile(
            bytes,
            'Proforma_${proforma.proformaNumber}.xlsx',
          );
        }
      },
    );
  }
}
