import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:pdf/widgets.dart' as pw;
import '../widgets/pdf_styles.dart';
import '../widgets/pdf_headers.dart';
import '../widgets/pdf_footers.dart';

class LetterHeadPdfGenerator {
  static Future<Uint8List> generate({
    BusinessProfile? profile,
    String? content,
  }) async {
    final pdf = pw.Document();

    final image = profile?.logoPath != null
        ? pw.MemoryImage(File(profile!.logoPath!).readAsBytesSync())
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: PdfStyles.buildPageTheme(profile, image),
        header: (context) => PdfHeaders.buildLetterHeadHeader(profile, image),
        footer: (context) => PdfFooters.buildLetterHeadFooter(profile),
        build: (pw.Context context) {
          return [
            if (content != null && content.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text(content, style: const pw.TextStyle(fontSize: 10)),
            ],
            pw.Spacer(),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
