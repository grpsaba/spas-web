import 'dart:convert';
import 'package:universal_html/html.dart' as html;

import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import '../../../model.dart';

/// Excel export service for pointage site data
/// 
/// Supports two export types:
/// 1. Individual Excel per supervisor
/// 2. All supervisors grouped in one Excel with sections
class PointageExcelExport {
  PointageExcelExport._();

  /// Export pointages for a single supervisor to Excel
  /// 
  /// Columns match ModernPointageTable: Superviseur, Site, Zone, Date, Heure, Distance
  static void exportForSupervisor({
    required List<PointingSite> pointages,
    required String supervisorName,
    required String period,
  }) {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Pointages';

    // --- Styles ---
    final titleStyle = workbook.styles.add('titleStyle');
    titleStyle.fontSize = 14;
    titleStyle.bold = true;
    titleStyle.fontColor = '#FFFFFF';
    titleStyle.backColor = '#3F51B5'; // PointageColors.primary (Indigo)
    titleStyle.hAlign = HAlignType.left;
    titleStyle.vAlign = VAlignType.center;

    final headerStyle = workbook.styles.add('headerStyle');
    headerStyle.fontSize = 11;
    headerStyle.bold = true;
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.backColor = '#5C6BC0'; // Lighter indigo
    headerStyle.borders.all.lineStyle = LineStyle.thin;
    headerStyle.borders.all.color = '#3F51B5';
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;

    final dataStyle = workbook.styles.add('dataStyle');
    dataStyle.fontSize = 10;
    dataStyle.borders.all.lineStyle = LineStyle.thin;
    dataStyle.borders.all.color = '#E0E0E0';
    dataStyle.vAlign = VAlignType.center;

    final dataStyleAlt = workbook.styles.add('dataStyleAlt');
    dataStyleAlt.fontSize = 10;
    dataStyleAlt.borders.all.lineStyle = LineStyle.thin;
    dataStyleAlt.borders.all.color = '#E0E0E0';
    dataStyleAlt.backColor = '#F5F5F5';
    dataStyleAlt.vAlign = VAlignType.center;

    // --- Title row ---
    sheet.getRangeByName('A1:F1').merge();
    sheet.getRangeByIndex(1, 1).setText('Pointages - $supervisorName');
    sheet.getRangeByIndex(1, 1).cellStyle = titleStyle;
    sheet.getRangeByIndex(1, 1).rowHeight = 30;

    // --- Period row ---
    sheet.getRangeByName('A2:F2').merge();
    sheet.getRangeByIndex(2, 1).setText('Période: $period');
    sheet.getRangeByIndex(2, 1).cellStyle.fontSize = 10;
    sheet.getRangeByIndex(2, 1).cellStyle.italic = true;
    sheet.getRangeByIndex(2, 1).cellStyle.fontColor = '#757575';
    sheet.getRangeByIndex(2, 1).rowHeight = 20;

    // --- Headers (row 4) ---
    final headers = ['Superviseur', 'Site', 'Zone', 'Date', 'Heure', 'Distance (m)'];
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(4, i + 1).setText(headers[i]);
      sheet.getRangeByIndex(4, i + 1).cellStyle = headerStyle;
    }
    sheet.getRangeByIndex(4, 1).rowHeight = 25;

    // --- Column widths ---
    sheet.getRangeByIndex(1, 1).columnWidth = 25; // Superviseur
    sheet.getRangeByIndex(1, 2).columnWidth = 25; // Site
    sheet.getRangeByIndex(1, 3).columnWidth = 18; // Zone
    sheet.getRangeByIndex(1, 4).columnWidth = 14; // Date
    sheet.getRangeByIndex(1, 5).columnWidth = 10; // Heure
    sheet.getRangeByIndex(1, 6).columnWidth = 14; // Distance

    // --- Data rows ---
    for (int i = 0; i < pointages.length; i++) {
      final p = pointages[i];
      final row = i + 5; // Start after header (row 4)
      final style = i % 2 == 0 ? dataStyle : dataStyleAlt;

      final supName = '${p.supervisor?.firstName ?? ''} ${p.supervisor?.lastName ?? ''}'.trim();
      sheet.getRangeByIndex(row, 1).setText(supName);
      sheet.getRangeByIndex(row, 1).cellStyle = style;

      sheet.getRangeByIndex(row, 2).setText('${p.site.codeSite} - ${p.site.name}');
      sheet.getRangeByIndex(row, 2).cellStyle = style;

      sheet.getRangeByIndex(row, 3).setText(p.site.zone?.name ?? 'N/A');
      sheet.getRangeByIndex(row, 3).cellStyle = style;

      sheet.getRangeByIndex(row, 4).setText(_formatDate(p.date));
      sheet.getRangeByIndex(row, 4).cellStyle = style;

      sheet.getRangeByIndex(row, 5).setText(_formatTime(p.date));
      sheet.getRangeByIndex(row, 5).cellStyle = style;

      sheet.getRangeByIndex(row, 6).setNumber(p.distance);
      sheet.getRangeByIndex(row, 6).cellStyle = style;
    }

    // --- Summary row ---
    final summaryRow = pointages.length + 6;
    sheet.getRangeByIndex(summaryRow, 1).setText('Total: ${pointages.length} pointage(s)');
    sheet.getRangeByIndex(summaryRow, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(summaryRow, 1).cellStyle.fontSize = 10;
    sheet.getRangeByIndex(summaryRow, 1).cellStyle.fontColor = '#3F51B5';

    // --- Download ---
    final fileName = 'pointages_${supervisorName.replaceAll(' ', '_')}.xlsx';
    _downloadExcel(workbook, fileName);
  }

  /// Export all pointages grouped by supervisor into one Excel file
  /// 
  /// Each supervisor gets a section with their name as header,
  /// followed by their pointages in the same table format
  static void exportAllGrouped({
    required List<PointingSite> pointages,
    required String period,
  }) {
    // Group pointages by supervisor UID
    final Map<String, List<PointingSite>> grouped = {};
    final Map<String, String> supervisorNames = {};

    for (final p in pointages) {
      final uid = p.supervisor?.UID ?? 'unknown';
      final name = '${p.supervisor?.firstName ?? ''} ${p.supervisor?.lastName ?? ''}'.trim();
      grouped.putIfAbsent(uid, () => []).add(p);
      supervisorNames[uid] = name.isNotEmpty ? name : 'Inconnu';
    }

    // Sort supervisors alphabetically
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => (supervisorNames[a] ?? '').compareTo(supervisorNames[b] ?? ''));

    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Pointages par superviseur';

    // --- Styles ---
    final mainTitleStyle = workbook.styles.add('mainTitleStyle');
    mainTitleStyle.fontSize = 16;
    mainTitleStyle.bold = true;
    mainTitleStyle.fontColor = '#FFFFFF';
    mainTitleStyle.backColor = '#3F51B5';
    mainTitleStyle.hAlign = HAlignType.left;
    mainTitleStyle.vAlign = VAlignType.center;

    final sectionTitleStyle = workbook.styles.add('sectionTitleStyle');
    sectionTitleStyle.fontSize = 12;
    sectionTitleStyle.bold = true;
    sectionTitleStyle.fontColor = '#FFFFFF';
    sectionTitleStyle.backColor = '#7986CB'; // Light indigo
    sectionTitleStyle.hAlign = HAlignType.left;
    sectionTitleStyle.vAlign = VAlignType.center;
    sectionTitleStyle.borders.bottom.lineStyle = LineStyle.medium;
    sectionTitleStyle.borders.bottom.color = '#3F51B5';

    final headerStyle = workbook.styles.add('headerStyle');
    headerStyle.fontSize = 10;
    headerStyle.bold = true;
    headerStyle.fontColor = '#212121';
    headerStyle.backColor = '#E8EAF6'; // Very light indigo
    headerStyle.borders.all.lineStyle = LineStyle.thin;
    headerStyle.borders.all.color = '#C5CAE9';
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;

    final dataStyle = workbook.styles.add('dataStyle');
    dataStyle.fontSize = 10;
    dataStyle.borders.all.lineStyle = LineStyle.thin;
    dataStyle.borders.all.color = '#E0E0E0';
    dataStyle.vAlign = VAlignType.center;

    final dataStyleAlt = workbook.styles.add('dataStyleAlt');
    dataStyleAlt.fontSize = 10;
    dataStyleAlt.borders.all.lineStyle = LineStyle.thin;
    dataStyleAlt.borders.all.color = '#E0E0E0';
    dataStyleAlt.backColor = '#F5F5F5';
    dataStyleAlt.vAlign = VAlignType.center;

    final countStyle = workbook.styles.add('countStyle');
    countStyle.fontSize = 10;
    countStyle.bold = true;
    countStyle.fontColor = '#3F51B5';
    countStyle.italic = true;

    // --- Column widths ---
    sheet.getRangeByIndex(1, 1).columnWidth = 25;
    sheet.getRangeByIndex(1, 2).columnWidth = 25;
    sheet.getRangeByIndex(1, 3).columnWidth = 18;
    sheet.getRangeByIndex(1, 4).columnWidth = 14;
    sheet.getRangeByIndex(1, 5).columnWidth = 10;
    sheet.getRangeByIndex(1, 6).columnWidth = 14;

    // --- Main title ---
    sheet.getRangeByName('A1:F1').merge();
    sheet.getRangeByIndex(1, 1).setText('Rapport de Pointages par Superviseur');
    sheet.getRangeByIndex(1, 1).cellStyle = mainTitleStyle;
    sheet.getRangeByIndex(1, 1).rowHeight = 35;

    // --- Period row ---
    sheet.getRangeByName('A2:F2').merge();
    sheet.getRangeByIndex(2, 1).setText('Période: $period');
    sheet.getRangeByIndex(2, 1).cellStyle.fontSize = 10;
    sheet.getRangeByIndex(2, 1).cellStyle.italic = true;
    sheet.getRangeByIndex(2, 1).cellStyle.fontColor = '#757575';

    // --- Summary ---
    sheet.getRangeByName('A3:F3').merge();
    sheet.getRangeByIndex(3, 1).setText(
      '${sortedKeys.length} superviseur(s) • ${pointages.length} pointage(s) au total',
    );
    sheet.getRangeByIndex(3, 1).cellStyle.fontSize = 10;
    sheet.getRangeByIndex(3, 1).cellStyle.fontColor = '#3F51B5';
    sheet.getRangeByIndex(3, 1).cellStyle.bold = true;

    int currentRow = 5; // Start data from row 5

    final headers = ['Superviseur', 'Site', 'Zone', 'Date', 'Heure', 'Distance (m)'];

    for (final supervisorUID in sortedKeys) {
      final supervisorPointages = grouped[supervisorUID]!;
      final name = supervisorNames[supervisorUID] ?? 'Inconnu';

      // Sort pointages by date descending
      supervisorPointages.sort((a, b) => b.date.compareTo(a.date));

      // --- Supervisor section header ---
      sheet.getRangeByName('A$currentRow:F$currentRow').merge();
      sheet.getRangeByIndex(currentRow, 1).setText(
        '$name  —  ${supervisorPointages.length} pointage(s)',
      );
      sheet.getRangeByIndex(currentRow, 1).cellStyle = sectionTitleStyle;
      sheet.getRangeByIndex(currentRow, 1).rowHeight = 28;
      currentRow++;

      // --- Column headers ---
      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(currentRow, i + 1).setText(headers[i]);
        sheet.getRangeByIndex(currentRow, i + 1).cellStyle = headerStyle;
      }
      sheet.getRangeByIndex(currentRow, 1).rowHeight = 22;
      currentRow++;

      // --- Data rows for this supervisor ---
      for (int i = 0; i < supervisorPointages.length; i++) {
        final p = supervisorPointages[i];
        final style = i % 2 == 0 ? dataStyle : dataStyleAlt;

        final supName = '${p.supervisor?.firstName ?? ''} ${p.supervisor?.lastName ?? ''}'.trim();
        sheet.getRangeByIndex(currentRow, 1).setText(supName);
        sheet.getRangeByIndex(currentRow, 1).cellStyle = style;

        sheet.getRangeByIndex(currentRow, 2).setText('${p.site.codeSite} - ${p.site.name}');
        sheet.getRangeByIndex(currentRow, 2).cellStyle = style;

        sheet.getRangeByIndex(currentRow, 3).setText(p.site.zone?.name ?? 'N/A');
        sheet.getRangeByIndex(currentRow, 3).cellStyle = style;

        sheet.getRangeByIndex(currentRow, 4).setText(_formatDate(p.date));
        sheet.getRangeByIndex(currentRow, 4).cellStyle = style;

        sheet.getRangeByIndex(currentRow, 5).setText(_formatTime(p.date));
        sheet.getRangeByIndex(currentRow, 5).cellStyle = style;

        sheet.getRangeByIndex(currentRow, 6).setNumber(p.distance);
        sheet.getRangeByIndex(currentRow, 6).cellStyle = style;

        currentRow++;
      }

      // Add spacing between supervisors
      currentRow += 1;
    }

    // --- Download ---
    final now = DateTime.now();
    final fileName = 'pointages_tous_superviseurs_${now.year}-${now.month.toString().padLeft(2, '0')}.xlsx';
    _downloadExcel(workbook, fileName);
  }

  // --- Private helpers ---

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static void _downloadExcel(Workbook workbook, String fileName) {
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final content = base64Encode(bytes);
    html.AnchorElement(
      href: 'data:application/octet-stream;charset=utf-16le;base64,$content',
    )
      ..setAttribute('download', fileName)
      ..click();

    debugPrint('Excel exported: $fileName');
  }
}
