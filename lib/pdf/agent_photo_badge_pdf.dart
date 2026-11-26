import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Printable data only: this renderer needs neither Firebase nor a browser.
class AgentPhotoBadgeData {
  const AgentPhotoBadgeData({
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.site,
    this.photo,
  });

  final String code;
  final String firstName;
  final String lastName;
  final String role;
  final String site;
  final pw.ImageProvider? photo;
}

class AgentPhotoBadgePdf {
  static const double width = 85.6 * PdfPageFormat.mm;
  static const double height = 54 * PdfPageFormat.mm;
  static const int badgesPerPage = 8;
  static const _ink = PdfColor.fromInt(0xFF143D65);
  static const _accent = PdfColor.fromInt(0xFF2865A5);
  static const _soft = PdfColor.fromInt(0xFFEDF3FA);
  static const _muted = PdfColor.fromInt(0xFF57687A);

  static Future<Uint8List> build({
    required List<AgentPhotoBadgeData> agents,
    required Uint8List logoBytes,
    required ByteData regularFont,
    required ByteData boldFont,
  }) async {
    if (agents.isEmpty) throw ArgumentError('Aucun agent sélectionné.');
    final logo = pw.MemoryImage(logoBytes);
    final document = pw.Document(
      title: 'Badges agents avec photo - Groupe SABA',
      author: 'Groupe SABA',
      // Bundled fonts preserve names and accents without a font CDN.
      theme: pw.ThemeData.withFont(
          base: pw.Font.ttf(regularFont), bold: pw.Font.ttf(boldFont)),
    );
    final pages = (agents.length / badgesPerPage).ceil();
    for (var start = 0; start < agents.length; start += badgesPerPage) {
      final batch =
          agents.sublist(start, math.min(start + badgesPerPage, agents.length));
      final page = start ~/ badgesPerPage + 1;
      document.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12 * PdfPageFormat.mm),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text('Badges agents - 85,6 x 54 mm - Imprimer à 100 %',
                  style: const pw.TextStyle(fontSize: 8, color: _muted)),
            ),
            for (var row = 0; row < batch.length; row += 2)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6 * PdfPageFormat.mm),
                child: pw.Row(children: [
                  _badge(batch[row], logo),
                  pw.SizedBox(width: 8 * PdfPageFormat.mm),
                  if (row + 1 < batch.length) _badge(batch[row + 1], logo),
                ]),
              ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('$page / $pages',
                  style: const pw.TextStyle(fontSize: 8, color: _muted)),
            ),
          ],
        ),
      ));
    }
    return document.save();
  }

  static pw.Widget _badge(AgentPhotoBadgeData agent, pw.ImageProvider logo) {
    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border:
            pw.Border.all(color: const PdfColor.fromInt(0xFFCCD7E3), width: .5),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(children: [
        pw.Container(
          height: 36,
          padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: const pw.BoxDecoration(
            color: _ink,
            borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5)),
          ),
          child: pw.Row(children: [
            pw.Container(
                width: 27,
                height: 27,
                color: PdfColors.white,
                child: pw.Image(logo, fit: pw.BoxFit.contain)),
            pw.SizedBox(width: 7),
            pw.Expanded(
                child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('GROUPE SABA',
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.SizedBox(height: 3),
                pw.Text('SPAS - CARTE PROFESSIONNELLE',
                    style: const pw.TextStyle(
                        fontSize: 4.8, color: PdfColors.white)),
              ],
            )),
            pw.Text('BADGE\nAGENT',
                textAlign: pw.TextAlign.center,
                style:
                    const pw.TextStyle(fontSize: 5.5, color: PdfColors.white)),
          ]),
        ),
        pw.Container(height: 2, color: _accent),
        pw.Expanded(
            child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: pw
              .Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            pw.ClipRRect(
              horizontalRadius: 3,
              verticalRadius: 3,
              child: pw.Container(
                width: 49,
                height: 60,
                color: _soft,
                child: agent.photo != null
                    ? pw.Image(agent.photo!, fit: pw.BoxFit.cover)
                    : pw.Center(
                        child: pw.Text('PHOTO\nNON FOURNIE',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                                fontSize: 5.5, color: _muted))),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _fit(agent.firstName, 13, 10.5, bold: true),
                _fit(agent.lastName.toUpperCase(), 13, 10.5, bold: true),
                pw.SizedBox(height: 3),
                _fit(agent.role, 10, 7.4),
                pw.SizedBox(height: 5),
                pw.Text('MATRICULE',
                    style: const pw.TextStyle(fontSize: 4.8, color: _muted)),
                _fit(agent.code, 10, 7.5, bold: true),
              ],
            )),
            pw.SizedBox(width: 5),
            pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // Quiet zone is explicit and remains white for reliable scanning.
                  pw.Container(
                    width: 57,
                    height: 57,
                    padding: const pw.EdgeInsets.all(6),
                    color: PdfColors.white,
                    child: pw.BarcodeWidget(
                        data: agent.code,
                        barcode: pw.Barcode.qrCode(),
                        drawText: false),
                  ),
                  pw.Text('POINTAGE',
                      style: const pw.TextStyle(fontSize: 4.5, color: _muted)),
                ]),
          ]),
        )),
        pw.Container(
          height: 29,
          margin: const pw.EdgeInsets.fromLTRB(9, 0, 9, 7),
          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: const pw.BoxDecoration(
              color: _soft,
              border: pw.Border(left: pw.BorderSide(color: _accent, width: 2))),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("SITE D'AFFECTATION",
                    style: const pw.TextStyle(fontSize: 4.8, color: _muted)),
                pw.SizedBox(height: 2),
                _fit(agent.site, 12, 9, bold: true),
              ]),
        ),
      ]),
    );
  }

  /// Preserve all text, including unusually long names, within the physical card.
  static pw.Widget _fit(String value, double height, double fontSize,
      {bool bold = false}) {
    return pw.SizedBox(
      width: double.infinity,
      height: height,
      child: pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        alignment: pw.Alignment.centerLeft,
        child: pw.Text(value.replaceAll(RegExp(r'\s+'), ' ').trim(),
            style: pw.TextStyle(
                fontSize: fontSize,
                color: _ink,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ),
    );
  }
}
