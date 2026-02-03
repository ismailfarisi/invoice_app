import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

class GenericPdfPreviewScreen extends ConsumerWidget {
  final String title;
  final LayoutCallback buildEvent;

  const GenericPdfPreviewScreen({
    super.key,
    required this.title,
    required this.buildEvent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: PdfPreview(
          build: buildEvent,
          canChangeOrientation: false,
          canDebug: false,
        ),
      ),
    );
  }
}
