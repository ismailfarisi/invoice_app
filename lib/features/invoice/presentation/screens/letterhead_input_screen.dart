import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/core/services/pdf/pdf_service.dart';
import 'package:flutter_invoice_app/features/invoice/presentation/screens/generic_pdf_preview_screen.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';

class LetterHeadInputScreen extends ConsumerStatefulWidget {
  const LetterHeadInputScreen({super.key});

  @override
  ConsumerState<LetterHeadInputScreen> createState() =>
      _LetterHeadInputScreenState();
}

class _LetterHeadInputScreenState extends ConsumerState<LetterHeadInputScreen> {
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _generatePdf() {
    final profile = ref.read(businessProfileRepositoryProvider).getProfile();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenericPdfPreviewScreen(
          title: 'Letter Head Preview',
          pdfFileName: 'Letterhead.pdf',
          buildEvent: (format) => PdfService().generateLetterHead(
            profile: profile,
            content: _contentController.text,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Letter Head Content')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Letter content',
                    alignLabelWithHint: true,
                    hintText:
                        'Type the letter to print under your business header',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Leave empty to get a blank page with just your letter head.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _generatePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generate PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
