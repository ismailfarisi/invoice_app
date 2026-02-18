import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';
import 'package:flutter_invoice_app/core/services/pdf/pdf_service.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';

import 'package:flutter_invoice_app/features/invoice/presentation/screens/generic_pdf_preview_screen.dart';
import 'package:flutter_invoice_app/core/services/excel/excel_service.dart';
import 'package:flutter_invoice_app/core/utils/file_utils.dart';

class LpoPdfPreviewScreen extends ConsumerWidget {
  final Lpo lpo;
  const LpoPdfPreviewScreen({super.key, required this.lpo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(businessProfileRepositoryProvider).getProfile();

    return GenericPdfPreviewScreen(
      title: 'LPO Preview',
      pdfFileName: 'LPO_${lpo.lpoNumber}.pdf',
      buildEvent: (format) => PdfService().generateLpo(lpo, profile: profile),
      onExportExcel: () async {
        final bytes = await ExcelService().generateLpo(lpo, profile: profile);
        if (bytes != null) {
          await FileUtils.shareFile(bytes, 'LPO_${lpo.lpoNumber}.xlsx');
        }
      },
    );
  }
}
