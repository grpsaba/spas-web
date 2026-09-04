import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:universal_html/html.dart' as html;

import '../../model.dart';
import '../../pdf/api/pdf_api.dart';
import '../models/monthly_pointing_sheet.dart';
import 'monthly_pointing_calculator.dart';

class MonthlyPointingSheetExporter {
  const MonthlyPointingSheetExporter();

  Future<void> exportPdf({
    required MonthlyPointingSheet sheet,
    required MonthlyPointingSummary summary,
  }) async {
    final document = pw.Document();
    final rows = summary.days
        .map(
          (day) => <String>[
            _shortDate(day.date),
            '${day.actualDay}/${day.expectedDay}',
            '${day.actualNight}/${day.expectedNight}',
            day.needsReason ? '-${day.totalDeficit}' : '-',
            _stateLabel(day),
            day.note?.displayText ?? '',
          ],
        )
        .toList(growable: false);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Fiche mensuelle de pointage',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${_monthLabel(sheet.month)} - page ${context.pageNumber}/${context.pagesCount}',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _pdfInfo('Superviseur', sheet.supervisorName),
                _pdfInfo('Zone', sheet.zoneName ?? 'Non renseignée'),
                _pdfInfo('Objectif jour', sheet.expectedDay.toString()),
                _pdfInfo('Objectif nuit', sheet.expectedNight.toString()),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const <String>[
              'Date',
              'Jour',
              'Nuit',
              'Écart',
              'État',
              'Motif',
            ],
            data: rows,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.indigo700),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: const <int, pw.Alignment>{
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
            columnWidths: const <int, pw.TableColumnWidth>{
              0: pw.FixedColumnWidth(52),
              1: pw.FixedColumnWidth(42),
              2: pw.FixedColumnWidth(42),
              3: pw.FixedColumnWidth(38),
              4: pw.FixedColumnWidth(68),
              5: pw.FlexColumnWidth(),
            },
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Effectués : ${summary.actualDayTotal} jour, ${summary.actualNightTotal} nuit. '
            '${summary.compliantDays}/${summary.evaluatedDays} journée(s) conforme(s). '
            '${summary.missingReasons} motif(s) restant à renseigner.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
          ),
        ],
      ),
    );

    final bytes = await document.save();
    await PdfApi.openFile(bytes);
  }

  Future<void> exportExcel({
    required MonthlyPointingSheet sheet,
    required MonthlyPointingSummary summary,
  }) async {
    final workbook = Workbook();
    final worksheet = workbook.worksheets[0];
    worksheet.name = 'Contrôle mensuel';
    worksheet.showGridlines = false;

    final titleStyle = workbook.styles.add('pointingSheetTitle');
    titleStyle.bold = true;
    titleStyle.fontSize = 18;
    titleStyle.fontColor = '#26336B';

    final headerStyle = workbook.styles.add('pointingSheetHeader');
    headerStyle.bold = true;
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.backColor = '#3F51B5';
    headerStyle.borders.all.lineStyle = LineStyle.thin;
    headerStyle.borders.all.color = '#D8DDEA';

    final bodyStyle = workbook.styles.add('pointingSheetBody');
    bodyStyle.borders.all.lineStyle = LineStyle.thin;
    bodyStyle.borders.all.color = '#E2E5EC';

    worksheet.getRangeByName('A1:H1').merge();
    worksheet.getRangeByName('A1').setText('Fiche mensuelle de pointage');
    worksheet.getRangeByName('A1').cellStyle = titleStyle;
    worksheet.getRangeByName('A3').setText('Superviseur');
    worksheet.getRangeByName('B3').setText(sheet.supervisorName);
    worksheet.getRangeByName('D3').setText('Mois');
    worksheet.getRangeByName('E3').setText(_monthLabel(sheet.month));
    worksheet.getRangeByName('G3').setText('Zone');
    worksheet.getRangeByName('H3').setText(sheet.zoneName ?? 'Non renseignée');
    worksheet.getRangeByName('A4').setText('Objectif jour');
    worksheet.getRangeByName('B4').setNumber(sheet.expectedDay.toDouble());
    worksheet.getRangeByName('D4').setText('Objectif nuit');
    worksheet.getRangeByName('E4').setNumber(sheet.expectedNight.toDouble());

    const headers = <String>[
      'Date',
      'Jour attendu',
      'Jour effectué',
      'Nuit attendue',
      'Nuit effectuée',
      'Écart',
      'État',
      'Motif',
      'Sites jour',
      'Sites nuit',
    ];
    for (var column = 0; column < headers.length; column++) {
      final cell = worksheet.getRangeByIndex(6, column + 1);
      cell.setText(headers[column]);
      cell.cellStyle = headerStyle;
    }

    for (var index = 0; index < summary.days.length; index++) {
      final day = summary.days[index];
      final row = index + 7;
      final values = <Object?>[
        _shortDate(day.date),
        day.expectedDay,
        day.actualDay,
        day.expectedNight,
        day.actualNight,
        day.needsReason ? -day.totalDeficit : 0,
        _stateLabel(day),
        day.note?.displayText ?? '',
        _siteNames(day.dayPointings),
        _siteNames(day.nightPointings),
      ];

      for (var column = 0; column < values.length; column++) {
        final cell = worksheet.getRangeByIndex(row, column + 1);
        final value = values[column];
        if (value is int) {
          cell.setNumber(value.toDouble());
        } else {
          cell.setText(value?.toString() ?? '');
        }
        cell.cellStyle = bodyStyle;
      }
    }

    worksheet.getRangeByIndex(1, 1).columnWidth = 12;
    for (var column = 2; column <= 7; column++) {
      worksheet.getRangeByIndex(1, column).columnWidth = 15;
    }
    worksheet.getRangeByIndex(1, 8).columnWidth = 34;
    worksheet.getRangeByIndex(1, 9).columnWidth = 42;
    worksheet.getRangeByIndex(1, 10).columnWidth = 42;

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    _download(
      Uint8List.fromList(bytes),
      'fiche_pointage_${_filePart(sheet.supervisorName)}_${sheet.monthKey}.xlsx',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  pw.Widget _pdfInfo(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  String _stateLabel(DailyPointingResult day) {
    switch (day.state) {
      case DailyPointingState.future:
        return 'À venir';
      case DailyPointingState.inProgress:
        return 'En cours';
      case DailyPointingState.noTarget:
        return 'Non planifié';
      case DailyPointingState.compliant:
        return 'Conforme';
      case DailyPointingState.partial:
      case DailyPointingState.missing:
        return day.hasReason ? 'Justifié' : 'Motif requis';
    }
  }

  String _siteNames(List<PointingSite> pointings) {
    final names = <String>{};
    for (final pointing in pointings) {
      names.add(pointing.site.name.toString());
    }
    return names.join(', ');
  }

  String _shortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _monthLabel(DateTime date) {
    const months = <String>[
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _filePart(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  void _download(Uint8List bytes, String fileName, String mimeType) {
    final blob = html.Blob(<Object>[bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
