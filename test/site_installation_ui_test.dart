import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/site_installation/installation_form.dart';
import 'package:spas_web/site_installation/installation_order.dart';
import 'package:spas_web/site_installation/installation_ui.dart';

InstallationOrder sample(
        String id, InstallationStatus status, String site, String client,
        {String author = 'Mamadou Traoré'}) =>
    InstallationOrder(
      id: id,
      tenantId: 'ml',
      departmentId: 'security',
      createdBy: {'uid': id == 'one' ? 'me' : 'other', 'name': author},
      status: status,
      siteName: site,
      clientName: client,
      address: 'Sotuba, Bamako',
      updatedAt: DateTime(2026, 11, 12),
      bonNumber: [InstallationStatus.draft, InstallationStatus.submitted]
              .contains(status)
          ? ''
          : '31503',
      agents: [InstallationAgent(name: 'Oumar Diarra', type: 'ADS')],
      equipment: [
        InstallationEquipment(
            catalogId: 'Lampe', designation: 'Lampe torche', quantity: 2)
      ],
    );
final samples = [
  sample(
      'one', InstallationStatus.submitted, 'Résidence Sotuba', 'Groupe TONINO'),
  sample('two', InstallationStatus.awaitingSignature,
      'Entrepôt de Magnambougou', 'Mali Distribution',
      author: 'Aïssata Koné'),
  sample('three', InstallationStatus.signedReturned, 'Agence ACI 2000',
      'Banque du Sahel'),
  sample('four', InstallationStatus.draft, 'Villa Badalabougou', 'SCI Horizon',
      author: 'Aïssata Koné'),
  sample('five', InstallationStatus.finalized, 'Immeuble Hamdallaye',
      'Cabinet Horizon'),
];
Widget shell(Widget child, {bool mobile = false}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Builder(
        builder: (context) => Theme(
            data: InstallationStyle.theme(context).copyWith(
                textTheme:
                    Theme.of(context).textTheme.apply(fontFamily: 'Roboto'),
                filledButtonTheme: FilledButtonThemeData(
                    style: InstallationStyle.theme(context)
                        .filledButtonTheme
                        .style!
                        .copyWith(
                            textStyle: const WidgetStatePropertyAll(TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.w600))))),
            child: Scaffold(
              appBar: AppBar(
                  title: Text(
                      mobile
                          ? 'Mes mises en place'
                          : 'Groupe SABA · Bons de mise en place',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700))),
              body: child,
            ))));
Future<void> size(WidgetTester tester, double width, double height) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> preview(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['INSTALLATION_PREVIEWS'] != '1') return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/installation-ui-preview').create(recursive: true);
    await File('build/installation-ui-preview/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets(
      'bureau filters distinguish action queue, own requests and search',
      (tester) async {
    await size(tester, 1440, 1080);
    final key = GlobalKey();
    var created = false;
    InstallationOrder? opened;
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: shell(InstallationWorkspace(
            orders: samples,
            ownerUid: 'me',
            reviewer: true,
            onCreate: () => created = true,
            onOpen: (o) => opened = o))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await preview(tester, key, 'bureau');
    await tester.tap(find.text('À traiter  2'));
    await tester.pumpAndSettle();
    expect(find.text('Résidence Sotuba'), findsOneWidget);
    expect(find.text('Villa Badalabougou'), findsNothing);
    await tester.tap(find.text('Mes demandes  1'));
    await tester.pumpAndSettle();
    expect(find.text('Agence ACI 2000'), findsNothing);
    await tester.tap(find.text('Résidence Sotuba'));
    expect(opened?.id, 'one');
    await tester.tap(find.text('Initier une demande'));
    expect(created, true);
    await tester.tap(find.text('Tous les dossiers  5'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mali Distribution');
    await tester.pumpAndSettle();
    expect(find.text('Entrepôt de Magnambougou'), findsOneWidget);
    expect(find.text('Résidence Sotuba'), findsNothing);
    await tester.tap(find.text('Réinitialiser les filtres'));
    await tester.pumpAndSettle();
    expect(find.text('Résidence Sotuba'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
  });
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('guided form retains edits across sections at $width',
        (tester) async {
      await size(tester, width, width > 500 ? 1000 : 950);
      final order = sample(
          'one', InstallationStatus.draft, 'Résidence Sotuba', 'Groupe TONINO');
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: shell(
              SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: InstallationForm(
                      order: order,
                      enabled: true,
                      guided: true,
                      departments: const [
                        'security'
                      ],
                      zones: const [],
                      supervisors: const [],
                      catalog: const [
                        InstallationOption('Lampe', 'Lampe torche',
                            {'departmentId': 'security'})
                      ])),
              mobile: width < 500)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await preview(tester, key,
          width > 500 ? 'fiche-bureau' : 'saisie-${width.toInt()}');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom du site'), 'Site corrigé');
      await tester.tap(find.text('2. Agents'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom et prénoms'), 'Agent libre');
      await tester.ensureVisible(find.text('3. Équipements'));
      await tester.tap(find.text('3. Équipements'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Quantité'), '7');
      await tester.ensureVisible(find.text('1. Site & client'));
      await tester.tap(find.text('1. Site & client'));
      await tester.pumpAndSettle();
      expect(find.text('Site corrigé'), findsOneWidget);
      expect(order.agents.single.name, 'Agent libre');
      expect(order.equipment.single.quantity, 7);
      await tester.ensureVisible(find.text('4. Organisation'));
      await tester.tap(find.text('4. Organisation'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Date du contrat'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('mobile cards and empty states fit a narrow viewport',
      (tester) async {
    await size(tester, 390, 844);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: shell(
            InstallationWorkspace(
                orders: samples.take(3).toList(),
                ownerUid: 'me',
                mobile: true,
                onCreate: () {},
                onOpen: (_) {},
                syncLabels: const {
                  'one': 'Synchronisé',
                  'two': 'Transmission en attente de connexion'
                },
                attentionIds: const {
                  'two'
                }),
            mobile: true)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await preview(tester, key, 'mobile-suivi');
    await tester.pumpWidget(shell(
        InstallationWorkspace(
            orders: const [],
            ownerUid: 'me',
            mobile: true,
            onCreate: () {},
            onOpen: (_) {}),
        mobile: true));
    await tester.pumpAndSettle();
    expect(find.text('Le prochain site commence ici'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'submitted request reads clearly at 320 without disabled form controls',
      (tester) async {
    await size(tester, 320, 900);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: shell(
            SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InstallationStatusBadge(samples.first.status),
                      const SizedBox(height: 16),
                      InstallationProgress(samples.first.status),
                      const SizedBox(height: 20),
                      InstallationNotice(
                          message: installationNextStep(samples.first.status,
                              mobile: true)),
                      const SizedBox(height: 20),
                      InstallationReadOnly(samples.first),
                    ])),
            mobile: true)));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Groupe TONINO'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await preview(tester, key, 'mobile-demande-transmise');
  });
}
