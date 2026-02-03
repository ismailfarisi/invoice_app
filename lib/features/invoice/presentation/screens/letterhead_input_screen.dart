import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/invoice/domain/services/pdf_service.dart';
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
                  decoration: const InputDecoration(
                    hintText: 'Enter your letter content here...',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
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
