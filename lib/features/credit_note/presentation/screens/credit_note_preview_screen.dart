import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/core/services/excel/excel_service.dart';
import 'package:flutter_invoice_app/core/services/pdf/pdf_service.dart';
import 'package:flutter_invoice_app/core/utils/file_utils.dart';
import 'package:flutter_invoice_app/features/credit_note/data/credit_note_repository.dart';
import 'package:flutter_invoice_app/features/credit_note/domain/models/credit_note.dart';
import 'package:flutter_invoice_app/features/invoice/presentation/screens/generic_pdf_preview_screen.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';

class CreditNotePreviewScreen extends ConsumerWidget {
  final CreditNote note;

  const CreditNotePreviewScreen({super.key, required this.note});

  Future<void> _confirmVoid(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Void ${note.creditNoteNumber}?'),
        content: const Text(
          'It stays on record under this number but no longer reduces the customer\'s balance. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Void Credit Note'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(creditNoteRepositoryProvider).voidNote(note);
    } catch (e) {
      debugPrint('Failed to void credit note: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not void the credit note. Please try again.'),
          ),
        );
      }
      return;
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(businessProfileRepositoryProvider).getProfile();
    final safeNumber = note.creditNoteNumber.replaceAll(
      RegExp(r'[^\w\.-]'),
      '_',
    );

    return GenericPdfPreviewScreen(
      title: 'Credit Note ${note.creditNoteNumber}',
      pdfFileName: 'CreditNote_$safeNumber.pdf',
      buildEvent: (format) =>
          PdfService().generateCreditNote(note, profile: profile),
      onExportExcel: () async {
        try {
          final bytes = await ExcelService().generateCreditNote(
            note,
            profile: profile,
          );
          if (bytes != null) {
            await FileUtils.shareFile(bytes, 'CreditNote_$safeNumber.xlsx');
          }
        } catch (e) {
          debugPrint('Failed to export credit note to Excel: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not export the credit note to Excel.'),
              ),
            );
          }
        }
      },
      actions: [
        if (!note.isVoided)
          IconButton(
            icon: const Icon(Icons.block),
            tooltip: 'Void Credit Note',
            onPressed: () => _confirmVoid(context, ref),
          ),
      ],
    );
  }
}
