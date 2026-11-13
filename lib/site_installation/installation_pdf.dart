import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'installation_order.dart';

class InstallationPdf {
  static Future<Uint8List> build(InstallationOrder order) async {
    if (![
      InstallationStatus.approved,
      InstallationStatus.awaitingSignature,
      InstallationStatus.signedReturned,
      InstallationStatus.finalized
    ].contains(order.status)) {
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
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      header: (context) => pw.Column(children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Image(logo, width: 100, height: 62, fit: pw.BoxFit.contain),
          pw.Text('GROUPE SABA',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ]),
        pw.SizedBox(height: 16),
        pw.Text(
            'BON DE MISE EN PLACE ${order.isSecurity ? 'SÉCURITÉ' : 'NETTOYAGE'}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.Divider(color: PdfColors.indigo),
        pw.SizedBox(height: 12),
      ]),
      footer: (context) => pw.Column(children: [
        pw.Divider(color: PdfColors.grey400),
        pw.Text('RCCM/ MA-BKO-2014-B-549 - NIF : 086133271L',
            style: const pw.TextStyle(fontSize: 8)),
        pw.Text(
            'Bon ${order.bonNumber} · ${order.siteName} · ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8)),
      ]),
      build: (context) => [
        pw.Text('N° DE BON : ${order.bonNumber}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text(
            'DATE : ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'),
        pw.Text('CLIENT : ${order.clientName}'),
        pw.Text('SITE : ${order.siteName}'),
        pw.Text('ADRESSE : ${order.address}'),
        if (order.phone.isNotEmpty) pw.Text('CONTACT : ${order.phone}'),
        pw.SizedBox(height: 24),
        pw.Text('AGENTS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['NOM ET PRÉNOMS', 'TYPE D’AGENT', 'CONTACT'],
          data: staff
              .map((agent) => [agent.name, agent.type, agent.phone])
              .toList(),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo50),
          headerStyle:
              pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellPadding: const pw.EdgeInsets.all(8),
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        ),
        pw.SizedBox(height: 24),
        pw.Text('ÉQUIPEMENTS',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['DÉSIGNATION', 'QUANTITÉ'],
          data: equipment
              .map((item) => [
                    item.designation,
                    item.designation.isEmpty ? '' : '${item.quantity}'
                  ])
              .toList(),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo50),
          headerStyle:
              pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellPadding: const pw.EdgeInsets.all(8),
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        ),
        pw.SizedBox(height: 32),
        pw.Container(
            height: 140,
            child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('SIGNATURE ET CACHET DU CLIENT',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('SIGNATURE ET CACHET SABA',
                      style: const pw.TextStyle(fontSize: 9)),
                ])),
      ],
    ));
    return document.save();
  }

  static Future<void> printOrder(InstallationOrder order) async {
    final bytes = await build(order);
    await Printing.layoutPdf(
        name: 'Bon-${order.bonNumber}.pdf', onLayout: (_) async => bytes);
  }
}
