import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
// The platform interface lets this test check exports without a real printer.
// ignore: implementation_imports
import 'package:printing/src/interface.dart';
import 'package:spas_web/site_installation/installation_order.dart';
import 'package:spas_web/site_installation/installation_pdf_preview.dart';

class _Printing extends PrintingPlatform {
  Uint8List? downloaded;
  Uint8List? printed;
  @override
  Future<PrintingInfo> info() async =>
      const PrintingInfo(canPrint: true, canRaster: false, canShare: true);
  @override
  Stream<PdfRaster> raster(
      Uint8List document, List<int>? pages, double dpi) async* {
    yield PdfRaster(1, 1, Uint8List.fromList([255, 255, 255, 255]));
  }

  @override
  Future<bool> sharePdf(Uint8List bytes, String filename, Rect bounds,
      String? subject, String? body, List<String>? emails) async {
    downloaded = bytes;
    return true;
  }

  @override
  Future<bool> layoutPdf(Printer? printer, LayoutCallback onLayout, String name,
      PdfPageFormat format, bool dynamicLayout, bool usePrinterSettings) async {
    printed = await onLayout(format);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late PrintingPlatform original;
  late _Printing printing;
  setUp(() {
    original = PrintingPlatform.instance;
    PrintingPlatform.instance = printing = _Printing();
  });
  tearDown(() => PrintingPlatform.instance = original);

  InstallationOrder order() => InstallationOrder(
      id: 'preview',
      tenantId: 'ml',
      departmentId: 'security',
      createdBy: {'uid': 'supervisor'},
      status: InstallationStatus.approved,
      bonNumber: '31503',
      siteName: 'Sotuba',
      clientName: 'TONINO',
      supervisor: {
        'UID': 'supervisor',
        'date': Timestamp.fromDate(DateTime(2026))
      });

  testWidgets('preview, download and print use the exact same PDF bytes',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child:
                    InstallationPdfPreview(order: order(), canPrint: true)))));
    final pending = tester
        .widget<FutureBuilder<Uint8List>>(find
            .byWidgetPredicate((widget) => widget is FutureBuilder<Uint8List>))
        .future!;
    await tester.runAsync(() => pending);
    await tester.pumpAndSettle();
    final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
    final bytes = await preview.build(PdfPageFormat.a4);
    await tester.tap(find.text('Télécharger le PDF'));
    await tester.pumpAndSettle();
    expect(printing.downloaded, same(bytes));
    await tester.tap(find.text('Imprimer'));
    await tester.pumpAndSettle();
    expect(printing.printed, same(bytes));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'PDF is cached through metadata updates and refreshed on reopening',
      (tester) async {
    final document = order();
    Future<void> display({bool active = true}) => tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: InstallationPdfPreview(
                    order: document, canPrint: false, active: active)))));
    Future<Uint8List> pending() => tester
        .widget<FutureBuilder<Uint8List>>(find
            .byWidgetPredicate((widget) => widget is FutureBuilder<Uint8List>))
        .future!;
    await display();
    final original = pending();
    await tester.runAsync(() => original);
    await tester.pumpAndSettle();
    final cachedLayout =
        tester.widget<PdfPreview>(find.byType(PdfPreview)).build;
    document.revision++;
    document.updatedAt = DateTime.now();
    await display();
    expect(pending(), same(original));
    expect(tester.widget<PdfPreview>(find.byType(PdfPreview)).build,
        same(cachedLayout));
    document.clientName = 'Client corrigé';
    await display(active: false);
    expect(pending(), same(original));
    await display();
    final refreshed = pending();
    expect(refreshed, isNot(same(original)));
    await tester.runAsync(() => refreshed);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'draft previews and view-only users cannot export an official bon',
      (tester) async {
    for (final draft in [true, false]) {
      final document = order();
      if (draft) {
        document.status = InstallationStatus.draft;
        document.bonNumber = '';
      }
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: InstallationPdfPreview(
                      order: document, canPrint: draft)))));
      final pending = tester
          .widget<FutureBuilder<Uint8List>>(find.byWidgetPredicate(
              (widget) => widget is FutureBuilder<Uint8List>))
          .future!;
      await tester.runAsync(() => pending);
      await tester.pumpAndSettle();
      expect(find.byType(PdfPreview), findsOneWidget);
      expect(find.text('Télécharger le PDF'), findsNothing);
      expect(find.text('Imprimer'), findsNothing);
      if (draft) {
        expect(find.textContaining('Aperçu du brouillon.'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
  });
}
