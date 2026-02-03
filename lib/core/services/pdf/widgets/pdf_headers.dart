import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'pdf_styles.dart';

class PdfHeaders {
  // --- INVOICE STYLE HEADERS ---

  static pw.Widget buildInvoiceHeader(
    BusinessProfile? profile,
    pw.ImageProvider? image,
    String title,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                if (image != null)
                  pw.Container(width: 60, height: 60, child: pw.Image(image)),
                pw.SizedBox(width: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile?.companyName.toUpperCase() ?? '',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    if (profile?.address != null)
                      pw.Container(
                        width: 200,
                        child: pw.Text(
                          profile?.address ?? '',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (profile?.phone != null)
                  pw.Text(
                    profile!.phone!,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.blue),
                  ),
                if (profile?.email != null)
                  pw.Text(
                    profile!.email!,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.blue),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.SizedBox(height: 5),
        PdfStyles.buildCustomDivider(),
        pw.Container(
          width: double.infinity,
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
        ),
        PdfStyles.buildCustomDivider(),
      ],
    );
  }

  static pw.Widget buildDeliveryNoteHeader(
    BusinessProfile? profile,
    pw.ImageProvider? image,
  ) {
    return buildQuotationStyleHeader(profile, image, 'DELIVERY NOTE');
  }

  // Uses the same structure as Invoice Header
  static pw.Widget buildLpoHeader(
    BusinessProfile? profile,
    pw.ImageProvider? image,
  ) {
    return buildQuotationStyleHeader(profile, image, 'LOCAL PURCHASE ORDER');
  }

  // --- LETTERHEAD STYLE HEADER ---

  static pw.Widget buildLetterHeadHeader(
    BusinessProfile? profile,
    pw.ImageProvider? image,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                if (image != null)
                  pw.Container(width: 60, height: 60, child: pw.Image(image)),
                pw.SizedBox(width: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile?.companyName.toUpperCase() ?? '',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    if (profile?.address != null)
                      pw.Container(
                        width: 200,
                        child: pw.Text(
                          profile!.address!,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (profile?.phone != null)
                  pw.Text(
                    profile!.phone!,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.blue),
                  ),
                if (profile?.email != null)
                  pw.Text(
                    profile!.email!,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.blue),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        PdfStyles.buildCustomDivider(),
      ],
    );
  }

  // --- QUOTATION / PROFORMA STYLE HEADER ---

  static pw.Widget buildQuotationStyleHeader(
    BusinessProfile? profile,
    pw.ImageProvider? image,
    String title,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (image != null)
                  pw.Container(
                    width: 70,
                    height: 70,
                    child: pw.Image(image),
                    margin: const pw.EdgeInsets.only(right: 15),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile?.companyName.toUpperCase() ?? '',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Container(
                      height: 3,
                      width: 250,
                      color: PdfColors.blue900,
                      margin: const pw.EdgeInsets.only(top: 2),
                    ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (profile?.phone != null)
                  pw.Text(
                    profile!.phone!,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.blue900),
                  ),
                if (profile?.email != null)
                  pw.Text(
                    profile!.email!,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.blue900),
                  ),
                if (profile?.website != null)
                  pw.Text(
                    profile!.website!,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.blue900),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        PdfStyles.buildCustomDivider(),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
