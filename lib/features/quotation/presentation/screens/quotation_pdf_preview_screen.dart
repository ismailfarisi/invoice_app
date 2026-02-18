import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/core/services/pdf/pdf_service.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';

import 'package:flutter_invoice_app/features/invoice/presentation/screens/generic_pdf_preview_screen.dart';
import 'package:flutter_invoice_app/core/services/excel/excel_service.dart';
import 'package:flutter_invoice_app/core/utils/file_utils.dart';

class QuotationPdfPreviewScreen extends ConsumerWidget {
  final Quotation quotation;
  const QuotationPdfPreviewScreen({super.key, required this.quotation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(businessProfileRepositoryProvider).getProfile();

    return GenericPdfPreviewScreen(
      title: 'Quotation Preview',
      pdfFileName: 'Quotation_${quotation.quotationNumber}.pdf',
      buildEvent: (format) =>
          PdfService().generateQuotation(quotation, profile: profile),
      onExportExcel: () async {
        final bytes = await ExcelService().generateQuotation(
          quotation,
          profile: profile,
        );
        if (bytes != null) {
          await FileUtils.shareFile(
            bytes,
            'Quotation_${quotation.quotationNumber}.xlsx',
          );
        }
      },
    );
  }
}
