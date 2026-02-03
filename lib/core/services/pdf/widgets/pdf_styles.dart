import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vector_math/vector_math_64.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';

class PdfStyles {
  static pw.PageTheme buildPageTheme(
    BusinessProfile? profile,
    pw.ImageProvider? image,
  ) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      buildBackground: (context) {
        if (image != null) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Opacity(
              opacity: 0.08,
              child: pw.Center(child: pw.Image(image, width: 400)),
            ),
          );
        }
        return pw.Container();
      },
    );
  }

  static pw.Widget buildCustomDivider() {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 12,
          child: pw.Container(height: 4, color: PdfColors.blue900),
        ),
        pw.SizedBox(width: 5),
        pw.Expanded(
          flex: 3,
          child: pw.Transform(
            transform: Matrix4.skewX(-0.3),
            child: pw.Container(height: 4, color: PdfColors.blue),
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Expanded(
          flex: 6,
          child: pw.Transform(
            transform: Matrix4.skewX(-0.3),
            child: pw.Container(height: 4, color: PdfColors.cyan),
          ),
        ),
      ],
    );
  }
}
