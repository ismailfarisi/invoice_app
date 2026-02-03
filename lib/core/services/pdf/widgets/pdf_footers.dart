import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'pdf_styles.dart';

class PdfFooters {
  static pw.Widget buildCommonPageFooter(
    BusinessProfile? profile,
    String footerText,
  ) {
    return pw.Column(
      children: [
        PdfStyles.buildCustomDivider(),
        pw.Center(
          child: pw.Text(
            '${profile?.companyName ?? ""}, ${profile?.address ?? ""} | ${profile?.phone ?? ""} ${profile?.mobile != null ? "| " + profile!.mobile! : ""} ${profile?.email != null ? "| " + profile!.email! : ""} ${profile?.website != null ? "| " + profile!.website! : ""}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue900),
          ),
        ),
        pw.Center(
          child: pw.Text(footerText, style: const pw.TextStyle(fontSize: 8)),
        ),
      ],
    );
  }

  static pw.Widget buildDetailedPageFooter(BusinessProfile? profile) {
    return pw.Column(
      children: [
        PdfStyles.buildCustomDivider(),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                '${profile?.companyName ?? ""},',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                '${profile?.address ?? ""} | Contact & WhatsApp : ${profile?.mobile ?? profile?.phone ?? ""}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'For enquiries, kindly mail to : ${profile?.email ?? ""} | web : ${profile?.website ?? ""}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget buildLetterHeadFooter(BusinessProfile? profile) {
    return pw.Column(
      children: [
        PdfStyles.buildCustomDivider(),
        pw.SizedBox(height: 5),
        pw.Center(
          child: pw.Text(
            '${profile?.companyName ?? ""}, ${profile?.address ?? ""} | ${profile?.phone ?? ""} ${profile?.mobile != null ? "| " + profile!.mobile! : ""} ${profile?.email != null ? "| " + profile!.email! : ""} ${profile?.website != null ? "| " + profile!.website! : ""}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue900),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }
}
