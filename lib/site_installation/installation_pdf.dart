import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'installation_order.dart';

class InstallationPdf {
  static bool isPrintable(InstallationOrder order) =>
      [
        InstallationStatus.approved,
        InstallationStatus.awaitingSignature,
        InstallationStatus.signedReturned,
        InstallationStatus.finalized
      ].contains(order.status) &&
      order.bonNumber.trim().isNotEmpty;

  static Future<Uint8List> build(InstallationOrder order,
      {bool preview = false}) async {
    final official = isPrintable(order);
    if (!official && !preview) {
      throw StateError('Valider les informations avant d’imprimer le bon.');
    }
    final regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    final logo = pw.MemoryImage(
        (await rootBundle.load('assets/logo.png')).buffer.asUint8List());
    final document =
        pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));
    final date = order.contractDate ?? order.createdAt ?? DateTime.now();
    final staff = order.agents.isEmpty ? [InstallationAgent()] : order.agents;
    final equipment =
        order.equipment.isEmpty ? [InstallationEquipment()] : order.equipment;
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    const line = PdfColors.grey400;
    const headerFill = PdfColors.indigo50;
    final labelStyle = pw.TextStyle(
        fontSize: 8, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold);
    const valueStyle = pw.TextStyle(fontSize: 10);
    final headStyle = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);
    pw.Widget cell(String text, {pw.TextStyle? style, bool center = false}) =>
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: pw.Text(text,
                style: style ?? valueStyle,
                textAlign: center ? pw.TextAlign.center : pw.TextAlign.left));
    pw.Widget info(String label, String value, {bool strong = false}) =>
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                      width: 118, child: pw.Text(label, style: labelStyle)),
                  pw.Expanded(
                      child: pw.Text(value,
                          style: strong
                              ? pw.TextStyle(
                                  fontSize: 11, fontWeight: pw.FontWeight.bold)
                              : valueStyle)),
                ]));
    // Two items per row: the page holds twice as many lines before breaking.
    List<List<T?>> pairs<T>(List<T> items) => [
          for (var i = 0; i < items.length; i += 2)
            [items[i], i + 1 < items.length ? items[i + 1] : null]
        ];
    final equipmentTable = pw.Table(
        border: pw.TableBorder.all(color: line, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(4),
          1: pw.FixedColumnWidth(42),
          2: pw.FlexColumnWidth(4),
          3: pw.FixedColumnWidth(42),
        },
        children: [
          pw.TableRow(
              decoration: const pw.BoxDecoration(color: headerFill),
              children: [
                cell('DÉSIGNATION', style: headStyle),
                cell('QTÉ', style: headStyle, center: true),
                cell('DÉSIGNATION', style: headStyle),
                cell('QTÉ', style: headStyle, center: true),
              ]),
          for (final pair in pairs(equipment))
            pw.TableRow(children: [
              for (final item in pair) ...[
                cell(item?.designation ?? ''),
                cell(
                    item == null || item.designation.isEmpty
                        ? ''
                        : '${item.quantity}',
                    center: true),
              ]
            ]),
        ]);
    // Up to four agents: one per line. Beyond: two per line, the type and the
    // phone under the name.
    final wideStaff = staff.length > 4;
    pw.Widget agentCell(InstallationAgent? agent) => agent == null
        ? pw.SizedBox()
        : pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(agent.name,
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      [agent.type, agent.phone]
                          .where((value) => value.isNotEmpty)
                          .join('  ·  '),
                      style: const pw.TextStyle(fontSize: 8.5)),
                ]));
    final agentTable = wideStaff
        ? pw.Table(
            border: pw.TableBorder.all(color: line, width: 0.5),
            children: [
                pw.TableRow(
                    decoration: const pw.BoxDecoration(color: headerFill),
                    children: [
                      cell('NOM  ·  TYPE  ·  CONTACT', style: headStyle),
                      cell('NOM  ·  TYPE  ·  CONTACT', style: headStyle),
                    ]),
                for (final pair in pairs(staff))
                  pw.TableRow(
                      children: [agentCell(pair[0]), agentCell(pair[1])]),
              ])
        : pw.Table(
            border: pw.TableBorder.all(color: line, width: 0.5),
            columnWidths: const {
                0: pw.FlexColumnWidth(5),
                1: pw.FlexColumnWidth(3),
                2: pw.FlexColumnWidth(3),
              },
            children: [
                pw.TableRow(
                    decoration: const pw.BoxDecoration(color: headerFill),
                    children: [
                      cell('NOM ET PRÉNOMS', style: headStyle),
                      cell('TYPE D’AGENT', style: headStyle),
                      cell('CONTACT', style: headStyle),
                    ]),
                for (final agent in staff)
                  pw.TableRow(children: [
                    cell(agent.name),
                    cell(agent.type),
                    cell(agent.phone),
                  ]),
              ]);
    pw.Widget section(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
        child: pw.Text(title,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)));
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 22, 32, 22),
      header: (context) => pw.Column(children: [
        pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logo, width: 70, height: 40, fit: pw.BoxFit.contain),
              pw.Text(
                  'BON DE MISE EN PLACE ${order.isSecurity ? 'SÉCURITÉ' : 'NETTOYAGE'}',
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.Text('GROUPE SABA',
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold)),
            ]),
        pw.Divider(color: PdfColors.indigo, height: 10),
        pw.SizedBox(height: 4),
      ]),
      footer: (context) => pw.Column(children: [
        pw.Divider(color: line, height: 8),
        pw.Text(
            'RCCM/ MA-BKO-2014-B-549 - NIF : 086133271L  ·  Bon ${installationBonLabel(order.bonNumber)} · ${order.siteName} · ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7)),
      ]),
      build: (context) => [
        if (!official) ...[
          pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(6),
              color: PdfColors.amber50,
              child: pw.Text('BROUILLON - Document non valide pour signature',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 6),
        ],
        pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: line, width: 0.6),
                borderRadius: pw.BorderRadius.circular(3)),
            child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                      child: pw.Column(children: [
                    info(
                        'N° DE BON',
                        order.bonNumber.isEmpty
                            ? 'Attribué à la validation'
                            : installationBonLabel(order.bonNumber),
                        strong: true),
                    info('CLIENT', order.clientName),
                    info('ADRESSE', order.address),
                  ])),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                      child: pw.Column(children: [
                    info('DATE DE MISE EN PLACE', dateLabel),
                    info('SITE', order.siteName),
                    if (order.phone.isNotEmpty) info('CONTACT', order.phone),
                  ])),
                ])),
        section('AGENTS (${order.agents.length})'),
        agentTable,
        section('ÉQUIPEMENTS (${order.equipment.length})'),
        equipmentTable,
        // Kept on one page: never separated from the signatures.
        pw.Container(
            padding: const pw.EdgeInsets.only(top: 18),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                      'Fait à Bamako, le ......................................',
                      style: const pw.TextStyle(fontSize: 10.5)),
                  pw.SizedBox(height: 10),
                  pw.SizedBox(
                      height: 95,
                      child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('SIGNATURE ET CACHET DU CLIENT',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text('SIGNATURE ET CACHET GROUPE SABA',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold)),
                          ])),
                ])),
      ],
    ));
    return document.save();
  }

  static Future<void> printOrder(InstallationOrder order) async {
    final bytes = await build(order);
    await Printing.layoutPdf(
        name: 'Bon-${installationBonLabel(order.bonNumber)}.pdf',
        onLayout: (_) async => bytes);
  }
}
