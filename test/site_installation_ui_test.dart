import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/site_installation/installation_form.dart';
import 'package:spas_web/site_installation/installation_order.dart';
import 'package:spas_web/site_installation/installation_ui.dart';
import 'package:spas_web/site_installation/installation_equipment_picker.dart';

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
      phone: '76000000',
      updatedAt: DateTime(2026, 11, 12),
      bonNumber: [InstallationStatus.draft, InstallationStatus.submitted]
              .contains(status)
          ? ''
          : '31503',
      zone: {'codeZone': 'z1', 'name': 'Zone Nord'},
      supervisor: {'UID': 's1', 'firstName': 'Ibrahim', 'lastName': 'Diallo'},
      contractDate: DateTime(2026, 11, 12),
      agentCount: 2,
      agents: [
        InstallationAgent(name: 'Oumar Diarra', type: 'ADS', phone: '76000001')
      ],
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
const catalog = [
  InstallationOption('Lampe', 'Lampe', {'departmentId': 'security'}),
  InstallationOption(
      'Radio', 'Radio de communication', {'departmentId': 'security'}),
];
const zones = [
  InstallationOption('z1', 'Zone Nord', {'codeZone': 'z1', 'name': 'Zone Nord'})
];
const supervisors = [
  InstallationOption('s1', 'Ibrahim Diallo', {
    'UID': 's1',
    'firstName': 'Ibrahim',
    'lastName': 'Diallo',
    'departmentId': 'security'
  })
];

Widget shell(Widget child,
        {bool mobile = false, Widget? bottom, bool scroll = false}) =>
    MaterialApp(
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
                                textStyle: const WidgetStatePropertyAll(
                                    TextStyle(
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
                  body: scroll
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(16), child: child)
                      : child,
                  bottomNavigationBar: bottom,
                ))));

Future<void> size(WidgetTester tester, double width, double height) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Screenshots for the visual review, written outside the repository when
/// INSTALLATION_PREVIEWS=1 (INSTALLATION_PREVIEW_DIR overrides the folder).
Future<void> preview(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['INSTALLATION_PREVIEWS'] != '1') return;
  final directory = Platform.environment['INSTALLATION_PREVIEW_DIR'] ??
      'build/installation-ui-preview';
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Finder step(int index) => find.byKey(ValueKey('installation-step-$index'));

InstallationForm guidedForm(InstallationOrder order,
        {InstallationFormController? controller}) =>
    InstallationForm(
        order: order,
        enabled: true,
        guided: true,
        controller: controller,
        departments: const ['security'],
        zones: zones,
        supervisors: supervisors,
        catalog: catalog);

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

  testWidgets('required fields block Continue and attempts to skip steps',
      (tester) async {
    await size(tester, 390, 1000);
    final order = sample('one', InstallationStatus.draft, 'Sotuba', 'TONINO')
      ..phone = '';
    order.agents.single.phone = '';
    order.equipment.single
      ..catalogId = null
      ..designation = ''
      ..quantity = 0;
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key, child: shell(guidedForm(order), scroll: true, mobile: true)));
    Future<void> go(Finder target) async {
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await go(find.text('Continuer'));
    expect(find.text('ÉTAPE 1 SUR 4'), findsOneWidget);
    expect(find.text('Champ obligatoire.'), findsOneWidget);
    expect(find.text('À compléter avant de continuer'), findsOneWidget);
    expect(find.text('Renseigner le téléphone du contact.'), findsOneWidget);
    await preview(tester, key, 'saisie-390-erreur-etape-1');
    await go(step(3));
    expect(find.text('ÉTAPE 1 SUR 4'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Téléphone du contact *'),
        '76000000');
    await go(step(3));
    expect(find.text('ÉTAPE 2 SUR 4'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Contact *'), '76000001');
    await go(step(3));
    expect(find.text('ÉTAPE 3 SUR 4'), findsOneWidget);
    expect(find.text('Saisir un entier positif.'), findsOneWidget);
    await go(find.byType(InstallationEquipmentPicker));
    await tester.tap(find.text('Lampe').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantité *'), '2');
    await go(find.text('Continuer'));
    expect(find.text('ÉTAPE 4 SUR 4'), findsOneWidget);
    await go(step(0));
    await tester.enterText(find.widgetWithText(TextFormField, 'Client *'), '');
    await go(step(3));
    expect(find.text('ÉTAPE 1 SUR 4'), findsOneWidget);
    // Going back to a previous step is always possible.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Client *'), 'TONINO');
    await go(step(2));
    await go(find.text('Précédent'));
    expect(find.text('ÉTAPE 2 SUR 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'transmission errors open the incomplete step, list what is missing and focus the field',
      (tester) async {
    await size(tester, 390, 900);
    final order = sample('one', InstallationStatus.draft, 'Sotuba', 'TONINO');
    order.agents.single.type = '';
    order.contractDate = null;
    final controller = InstallationFormController();
    await tester.pumpWidget(
        shell(guidedForm(order, controller: controller), scroll: true));
    await tester.pumpAndSettle();
    expect(controller.validate(), false);
    await tester.pumpAndSettle();
    expect(controller.step, 1);
    expect(find.text('ÉTAPE 2 SUR 4'), findsOneWidget);
    expect(find.text('Renseigner le type de chaque agent.'), findsOneWidget);
    final typeField = find.widgetWithText(TextFormField, 'Type d’agent *');
    expect(
        tester
            .widget<EditableText>(find.descendant(
                of: typeField, matching: find.byType(EditableText)))
            .focusNode
            .hasFocus,
        true);
    await tester.enterText(typeField, 'ADS');
    expect(controller.validate(), false);
    await tester.pumpAndSettle();
    expect(controller.step, 3);
    expect(find.text('Renseigner la date du contrat.'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'small phone with the keyboard open keeps the focused field and the step navigation reachable',
      (tester) async {
    await size(tester, 360, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    final order = sample('one', InstallationStatus.draft, 'Sotuba', 'TONINO')
      ..agents.add(InstallationAgent())
      ..agents.add(InstallationAgent());
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: shell(guidedForm(order),
            scroll: true,
            mobile: true,
            bottom: InstallationActionBar(
                status: 'Brouillon conservé sur cet appareil',
                primary: InstallationAction('Transmettre au bureau', () {},
                    icon: Icons.send_outlined)))));
    await tester.pumpAndSettle();
    await tester.tap(step(1));
    await tester.pumpAndSettle();
    final field = find.widgetWithText(TextFormField, 'Nom et prénoms *').last;
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, 'Agent ajouté');
    await tester.pumpAndSettle();
    final rect = tester.getRect(field);
    // The visible area ends where the keyboard starts (640 - 280).
    expect(rect.top, greaterThanOrEqualTo(56));
    expect(rect.bottom, lessThanOrEqualTo(360));
    await preview(tester, key, 'saisie-360x640-clavier-ouvert');
    final next = find.text('Continuer');
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    expect(tester.getRect(next).bottom, lessThanOrEqualTo(360));
    await tester.tap(next);
    await tester.pumpAndSettle();
    // The two empty agents block the step and are reported.
    expect(find.text('ÉTAPE 2 SUR 4'), findsOneWidget);
    expect(find.text('À compléter avant de continuer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 1100.0]) {
    testWidgets(
        'equipment search ignores accents and supports free entry at $width',
        (tester) async {
      await size(tester, width, 850);
      final key = GlobalKey();
      String? selected;
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: shell(Padding(
              padding: const EdgeInsets.all(16),
              child: InstallationEquipmentPicker(
                  value: null,
                  enabled: true,
                  catalog: const [
                    InstallationOption(
                        'light', 'Éclairage portable rechargeable'),
                    InstallationOption('radio', 'Radio de communication'),
                  ],
                  onChanged: (value) => selected = value)))));
      await tester.tap(find.byType(InstallationEquipmentPicker));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await preview(tester, key, 'catalogue-${width.toInt()}');
      await tester.enterText(find.byType(TextField), 'ECLAIRAGE');
      await tester.pumpAndSettle();
      expect(find.text('Radio de communication'), findsNothing);
      expect(find.text('1 résultat'), findsOneWidget);
      await tester.tap(find.text('Éclairage portable rechargeable'));
      await tester.pumpAndSettle();
      expect(selected, 'light');
      await tester.tap(find.byType(InstallationEquipmentPicker));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'introuvable');
      await tester.pumpAndSettle();
      expect(find.textContaining('Aucun équipement trouvé.'), findsOneWidget);
      await tester.tap(find.text('Saisir une désignation'));
      await tester.pumpAndSettle();
      expect(selected, '');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'equipment quantity has steppers and deleted rows can be restored',
      (tester) async {
    await size(tester, 390, 1000);
    final order = sample('one', InstallationStatus.draft, 'Sotuba', 'TONINO');
    var changes = 0;
    await tester.pumpWidget(shell(
        InstallationForm(
            order: order,
            enabled: true,
            guided: true,
            onChanged: () => changes++,
            departments: const ['security'],
            zones: zones,
            supervisors: supervisors,
            catalog: catalog),
        scroll: true));
    await tester.tap(step(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Augmenter la quantité'));
    await tester.tap(find.byTooltip('Augmenter la quantité'));
    await tester.tap(find.byTooltip('Diminuer la quantité'));
    await tester.pump();
    expect(order.equipment.single.quantity, 3);
    expect(find.widgetWithText(TextFormField, '3'), findsOneWidget);
    await tester.tap(find.byTooltip('Supprimer cet équipement'));
    await tester.pumpAndSettle();
    expect(order.equipment, isEmpty);
    expect(find.text('Aucun équipement pour le moment'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(order.equipment.single.designation, 'Lampe torche');
    await tester.tap(step(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Supprimer cet agent'));
    await tester.pumpAndSettle();
    expect(order.agents, isEmpty);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(order.agents.single.name, 'Oumar Diarra');
    expect(changes, greaterThanOrEqualTo(7));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'typing in one field does not rebuild the other fields of the request',
      (tester) async {
    await size(tester, 1200, 1400);
    final order = sample('one', InstallationStatus.draft, 'Sotuba', 'TONINO')
      ..agents.addAll(List.generate(
          8,
          (i) =>
              InstallationAgent(name: 'Agent $i', type: 'ADS', phone: '7600')));
    await tester.pumpWidget(shell(guidedForm(order), scroll: true));
    await tester.pumpAndSettle();
    var rebuilt = 0;
    debugOnRebuildDirtyWidget = (element, _) {
      if (element.widget is TextField) rebuilt++;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom du site *'), 'Nouveau nom');
    await tester.pump();
    debugOnRebuildDirtyWidget = null;
    expect(order.siteName, 'Nouveau nom');
    // Only the edited field is rebuilt (the request has more than 30 fields).
    expect(rebuilt, lessThanOrEqualTo(2));
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
            headerExtra: const Text('Numérotation commune'),
            onCreate: () => created = true,
            onOpen: (o) => opened = o))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await preview(tester, key, 'bureau-1440');
    await tester.tap(find.text('À traiter'));
    await tester.pumpAndSettle();
    expect(find.text('Résidence Sotuba'), findsOneWidget);
    expect(find.text('Villa Badalabougou'), findsNothing);
    await tester.tap(find.text('Mes demandes'));
    await tester.pumpAndSettle();
    expect(find.text('Agence ACI 2000'), findsNothing);
    await tester.tap(find.text('Résidence Sotuba'));
    expect(opened?.id, 'one');
    await tester.tap(find.text('Nouvelle demande'));
    expect(created, true);
    await tester.tap(find.text('Tous les dossiers'));
    await tester.pumpAndSettle();
    // Search ignores accents and case.
    await tester.enterText(find.byType(TextField), 'entrepot');
    await tester.pumpAndSettle();
    expect(find.text('Entrepôt de Magnambougou'), findsOneWidget);
    expect(find.text('Résidence Sotuba'), findsNothing);
    expect(find.text('1 dossier sur 5'), findsOneWidget);
    await tester.tap(find.text('Réinitialiser les filtres'));
    await tester.pumpAndSettle();
    expect(find.text('Résidence Sotuba'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    // Counters filter by status.
    await tester.tap(find.bySemanticsLabel('À finaliser : 1'));
    await tester.pumpAndSettle();
    expect(find.text('Agence ACI 2000'), findsOneWidget);
    expect(find.text('Résidence Sotuba'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow list filters by status from a bottom sheet',
      (tester) async {
    await size(tester, 390, 844);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: shell(
            InstallationWorkspace(
                orders: samples,
                ownerUid: 'me',
                reviewer: true,
                onCreate: () {},
                onOpen: (_) {}),
            mobile: true)));
    await tester.pumpAndSettle();
    await preview(tester, key, 'bureau-390');
    await tester.tap(find.text('Statut'));
    await tester.pumpAndSettle();
    expect(find.text('Filtrer par statut'), findsOneWidget);
    await preview(tester, key, 'filtres-statut-390');
    await tester.tap(find.widgetWithText(ListTile, 'Retour signé reçu'));
    await tester.pumpAndSettle();
    expect(find.text('Agence ACI 2000'), findsOneWidget);
    expect(find.text('Résidence Sotuba'), findsNothing);
    await tester.tap(find.byTooltip('Retirer le filtre de statut'));
    await tester.pumpAndSettle();
    expect(find.text('Résidence Sotuba'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
          child: shell(guidedForm(order), scroll: true, mobile: width < 500)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final name = width > 500 ? '1200' : width.toInt().toString();
      await preview(tester, key, 'saisie-$name-etape-1');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom du site *'), 'Site corrigé');
      await tester.tap(step(1));
      await tester.pumpAndSettle();
      await preview(tester, key, 'saisie-$name-etape-2');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom et prénoms *'),
          'Agent libre');
      await tester.tap(step(2));
      await tester.pumpAndSettle();
      await preview(tester, key, 'saisie-$name-etape-3');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Quantité *'), '7');
      await tester.tap(step(0));
      await tester.pumpAndSettle();
      expect(find.text('Site corrigé'), findsOneWidget);
      expect(order.agents.single.name, 'Agent libre');
      expect(order.equipment.single.quantity, 7);
      await tester.tap(step(3));
      await tester.pumpAndSettle();
      await preview(tester, key, 'saisie-$name-etape-4');
      expect(find.widgetWithText(TextFormField, 'Date du contrat *'),
          findsOneWidget);
      await tester.tap(find.text('Nuit'));
      await tester.pump();
      expect(order.pointageType, 'nuit');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mobile cards, views and empty states fit a narrow viewport',
      (tester) async {
    await size(tester, 390, 844);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: shell(
            InstallationWorkspace(
                orders: [
                  ...samples.take(3),
                  sample('six', InstallationStatus.changesRequested,
                      'Clinique Kalaban', 'Santé Plus')
                ],
                ownerUid: 'me',
                mobile: true,
                onCreate: () {},
                onOpen: (_) {},
                syncLabels: const {
                  'one': 'Synchronisé',
                  'two': 'Transmission en attente de connexion'
                },
                attentionIds: const {'two'}),
            mobile: true)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await preview(tester, key, 'mobile-liste');
    await tester.tap(find.text('À compléter'));
    await tester.pumpAndSettle();
    expect(find.text('Clinique Kalaban'), findsOneWidget);
    expect(find.text('Résidence Sotuba'), findsNothing);
    await tester.ensureVisible(find.text('Au bureau'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Au bureau'));
    await tester.pumpAndSettle();
    expect(find.text('Résidence Sotuba'), findsOneWidget);
    expect(find.text('Clinique Kalaban'), findsNothing);
    await tester.pumpWidget(shell(
        InstallationWorkspace(
            orders: const [],
            ownerUid: 'me',
            mobile: true,
            onCreate: () {},
            onOpen: (_) {}),
        mobile: true));
    await tester.pumpAndSettle();
    expect(find.text('Aucune demande pour le moment'), findsOneWidget);
    expect(find.text('Nouvelle demande'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long lists are built lazily', (tester) async {
    await size(tester, 390, 844);
    final orders = [
      for (var i = 0; i < 300; i++)
        sample('o$i', InstallationStatus.values[i % 7], 'Site $i', 'Client $i')
    ];
    await tester.pumpWidget(shell(InstallationWorkspace(
        orders: orders, ownerUid: 'me', mobile: true, onOpen: (_) {})));
    await tester.pumpAndSettle();
    expect(find.byType(InstallationOrderTile).evaluate().length, lessThan(20));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('every status shows who acts next without overflow at 360',
      (tester) async {
    await size(tester, 360, 2600);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: shell(
            Column(children: [
              for (final status in InstallationStatus.values) ...[
                InstallationNextStepCard(
                    status: status,
                    guidance: installationGuidance(status, mobile: true)),
                const SizedBox(height: 8),
              ]
            ]),
            scroll: true,
            mobile: true)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await preview(tester, key, 'statuts-mobile-360');
    expect(installationGuidance(InstallationStatus.draft, mobile: true).owner,
        'À vous');
    expect(
        installationGuidance(InstallationStatus.submitted, mobile: true).owner,
        'Au bureau');
    expect(
        installationGuidance(InstallationStatus.submitted, reviewer: true)
            .title,
        'Vérifier puis valider');
    expect(
        installationGuidance(InstallationStatus.awaitingSignature, mobile: true)
            .owner,
        'À vous');
    // A web initiator without the validation right is not told to validate.
    expect(installationNextStep(InstallationStatus.submitted, reviewer: false),
        isNot(contains('validez')));
  });

  testWidgets(
      'action bar keeps one primary action and groups the others on phones',
      (tester) async {
    await size(tester, 360, 640);
    final pressed = <String>[];
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: shell(const SizedBox.expand(),
            bottom: InstallationActionBar(
                status: 'Modifications non enregistrées',
                statusWarning: true,
                save: InstallationAction(
                    'Enregistrer', () => pressed.add('save')),
                primary: InstallationAction(
                    'Valider le bon', () => pressed.add('approve'),
                    icon: Icons.check),
                secondary: [
                  InstallationAction(
                      'Demander une correction', () => pressed.add('changes'),
                      icon: Icons.undo),
                  InstallationAction(
                      'Aperçu et impression', () => pressed.add('print'),
                      icon: Icons.print_outlined),
                ]))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Demander une correction'), findsNothing);
    await preview(tester, key, 'barre-actions-360');
    await tester.tap(find.byTooltip('Autres actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demander une correction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider le bon'));
    await tester.tap(find.text('Enregistrer'));
    expect(pressed, ['changes', 'approve', 'save']);
  });

  testWidgets('follow-up sends messages and keeps errors next to the field',
      (tester) async {
    await size(tester, 390, 844);
    final sent = <String>[];
    var fail = true;
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: shell(
            InstallationFollowUp(
                events: [
                  {
                    'id': 'e1',
                    'kind': 'status',
                    'message': 'Fiche transmise pour vérification',
                    'author': const {'name': 'Mamadou Traoré'},
                    'at': DateTime(2026, 11, 12, 9, 30)
                  },
                  {
                    'id': 'e2',
                    'kind': 'comment',
                    'message': 'Merci de préciser le contact du client.',
                    'author': const {'name': 'Bureau Bamako'},
                    'at': DateTime(2026, 11, 12, 10, 5)
                  },
                  const {
                    'id': 'local',
                    'kind': 'comment',
                    'message': 'Contact ajouté.',
                    'author': {'name': 'Mamadou Traoré'},
                  },
                ],
                pendingIds: const {
                  'local'
                },
                onSend: (message) async {
                  if (fail) throw StateError('Connexion requise.');
                  sent.add(message);
                }),
            scroll: true,
            mobile: true)));
    await tester.pumpAndSettle();
    expect(find.text('En attente d’envoi'), findsOneWidget);
    await preview(tester, key, 'suivi-390');
    await tester.enterText(find.byType(TextField), 'Bien reçu');
    await tester.pump();
    await tester.tap(find.byTooltip('Envoyer le message'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion requise.'), findsOneWidget);
    expect(find.text('Bien reçu'), findsOneWidget);
    fail = false;
    await tester.tap(find.byTooltip('Envoyer le message'));
    await tester.pumpAndSettle();
    expect(sent, ['Bien reçu']);
    expect(find.text('Connexion requise.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'submitted request reads clearly at 320 without disabled form controls',
      (tester) async {
    await size(tester, 320, 1500);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: shell(
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              InstallationNextStepCard(
                  status: samples.first.status,
                  guidance:
                      installationGuidance(samples.first.status, mobile: true)),
              const SizedBox(height: 16),
              InstallationTabs(selected: 0, onSelected: (_) {}, tabs: const [
                InstallationTab(0, 'La demande', Icons.description_outlined),
                InstallationTab(3, 'Aperçu PDF', Icons.picture_as_pdf_outlined),
                InstallationTab(1, 'Suivi', Icons.forum_outlined),
                InstallationTab(2, 'Bon signé', Icons.attach_file),
              ]),
              const SizedBox(height: 16),
              InstallationReadOnly(samples.first),
            ]),
            scroll: true,
            mobile: true)));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Groupe TONINO'), findsOneWidget);
    expect(find.text('Vérification au bureau'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await preview(tester, key, 'mobile-demande-transmise');
  });
}
