import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/site_installation/installation_form.dart';
import 'package:spas_web/site_installation/installation_catalog.dart';
import 'package:spas_web/site_installation/installation_order.dart';
import 'package:spas_web/site_installation/installation_pdf.dart';

InstallationOrder fixture() => InstallationOrder(
    id: 'test-order',
    tenantId: 'ml',
    departmentId: 'security',
    createdBy: {'uid': 'author', 'name': 'Superviseur'},
    siteName: 'TONINO Sotuba',
    clientName: 'TONINO',
    address: 'Sotuba',
    phone: '76000000',
    zone: {'codeZone': 'z1'},
    supervisor: {'UID': 's1'},
    contractDate: DateTime(2026, 11, 12),
    agentCount: 1,
    agents: [InstallationAgent(name: 'Nom libre', type: 'ADS', phone: '123')],
    equipment: [
      InstallationEquipment(
          designation: 'Lampe', quantity: 2, catalogId: 'Lampe')
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('author workflow cannot validate, finalize or skip paper stages', () {
    for (final status in InstallationStatus.values) {
      expect(status.canMoveTo(InstallationStatus.finalized, reviewer: false),
          false);
      expect(status.canMoveTo(InstallationStatus.finalized, reviewer: true),
          false);
    }
    expect(
        InstallationStatus.draft
            .canMoveTo(InstallationStatus.submitted, reviewer: false),
        true);
    expect(
        InstallationStatus.submitted
            .canMoveTo(InstallationStatus.approved, reviewer: false),
        false);
    expect(
        InstallationStatus.approved
            .canMoveTo(InstallationStatus.signedReturned, reviewer: true),
        false);
    expect(
        InstallationStatus.awaitingSignature
            .canMoveTo(InstallationStatus.signedReturned, reviewer: true),
        true);
    expect(
        InstallationStatus.finalized
            .canMoveTo(InstallationStatus.changesRequested, reviewer: true),
        false);
  });
  test(
      'wire data and free text survive offline JSON; unknown statuses fail closed',
      () {
    final order = fixture()..createdAt = DateTime(2026, 11, 12);
    final copy = InstallationOrder.fromJson(order.id,
        jsonDecode(jsonEncode(order.toJson())) as Map<String, dynamic>);
    expect(copy.agents.single.name, 'Nom libre');
    expect(copy.agents.single.toJson().keys, isNot(contains('UID')));
    expect(copy.equipment.single.quantity, 2);
    copy.agents.single.name = 'Autre';
    expect(order.agents.single.name, 'Nom libre');
    expect(
        () => InstallationOrder.fromJson(
            order.id, {...order.toJson(), 'status': 'invalid'}),
        throwsFormatException);
  });
  test(
      'complete submission needs no GPS or second supervisor; approval needs a number',
      () {
    final order = fixture();
    expect(order.validate(), isEmpty);
    expect(order.validate(forSite: true), isNotEmpty);
    order.bonNumber = '31503';
    expect(order.validate(forSite: true), isEmpty);
    order.latitude = 12.6;
    expect(order.validate(), isNotEmpty);
    order.longitude = -8;
    expect(order.validate(forSite: true), isEmpty);
    order.equipment.single.quantity = 0;
    expect(order.validate(), isNotEmpty);
    order.latitude = double.nan;
    expect(order.validate(forSite: true), isNotEmpty);
  });
  test(
      'initial submission requires all contact, agent, equipment and organisation fields',
      () {
    final invalidations = <void Function(InstallationOrder)>[
      (o) => o.siteName = ' ',
      (o) => o.clientName = '',
      (o) => o.address = '',
      (o) => o.phone = '',
      (o) => o.departmentId = '',
      (o) => o.agents.clear(),
      (o) => o.agents.add(InstallationAgent(name: 'Autre', type: 'ADS')),
      (o) => o.agents.single.name = '',
      (o) => o.agents.single.type = '',
      (o) => o.agents.single.phone = '',
      (o) => o.equipment.clear(),
      (o) => o.equipment.add(InstallationEquipment()),
      (o) => o.equipment.single.quantity = 0,
      (o) => o.zone = null,
      (o) => o.supervisor = null,
      (o) => o.supervisor2 = {'UID': 's1'},
      (o) => o.contractDate = null,
      (o) => o.agentCount = 0,
      (o) => o.roundCount = 0,
      (o) => o.pointageType = 'invalid',
      (o) {
        o.latitude = 91;
        o.longitude = 0;
      },
      (o) {
        o.latitude = 0;
        o.longitude = 181;
      },
    ];
    for (var i = 0; i < invalidations.length; i++) {
      final order = fixture();
      invalidations[i](order);
      expect(order.validate(), isNotEmpty, reason: 'Invalid field $i');
    }
  });
  test(
      'shared catalogue accepts legacy fields and other companies, filtered by prestation',
      () {
    final options = installationCatalogOptions({
      'legacy': {
        'label': 'Sifflet',
        'department': {'label': 'Sécurité', 'active': true}
      },
      'legacy-id': {
        'label': 'Radio',
        'department': {'id': 'SECURITE'}
      },
      'other-company': {
        'label': 'Lampe',
        'tenantId': 'ci',
        'departmentId': 'security'
      },
      'cleaning': {'label': 'Balai', 'departmentId': 'cleaning'},
      'inactive': {
        'label': 'Ancien',
        'departmentId': 'security',
        'active': false
      },
      'inactive-dept': {
        'label': 'Ancien 2',
        'department': {'id': 'security', 'active': false}
      },
    }, [
      'security'
    ]);
    expect(options.map((o) => o.label), ['Lampe', 'Radio', 'Sifflet']);
    expect(options.every((o) => o.data['departmentId'] == 'security'), true);
  });
  for (final width in [320.0, 1200.0]) {
    testWidgets('form supports free text and catalog at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final order = fixture();
      var changes = 0;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: InstallationForm(
                      order: order,
                      enabled: true,
                      departments: const ['security', 'cleaning'],
                      zones: const [],
                      supervisors: const [],
                      catalog: const [
                        InstallationOption(
                            'Lampe', 'Lampe', {'departmentId': 'security'})
                      ],
                      onChanged: () => changes++)))));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('attribué automatiquement'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'N° de bon'), findsNothing);
      final name = find.widgetWithText(TextFormField, 'Nom et prénoms');
      await tester.ensureVisible(name);
      await tester.enterText(name, 'Agent non enregistré');
      expect(order.agents.single.name, 'Agent non enregistré');
      final quantity = find.widgetWithText(TextFormField, 'Quantité');
      await tester.ensureVisible(quantity);
      await tester.enterText(quantity, '5');
      expect(order.equipment.single.quantity, 5);
      expect(changes, 2);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ajouter un équipement'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajouter un équipement'));
      await tester.pump();
      expect(order.equipment.length, 2);
      final picker = find
          .widgetWithText(
              DropdownButtonFormField<String>, 'Équipement du catalogue')
          .last;
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Autre équipement (saisie libre)').last);
      await tester.pumpAndSettle();
      expect(
          find.text(
              'Équipement absent du catalogue : pensez à le créer pour les prochains bons.'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final editing in [false, true]) {
    testWidgets(
        'legacy shared equipment can be selected ${editing ? 'during editing' : 'on initiation'}',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final order = fixture();
      order.equipment.clear();
      order.equipment.add(InstallationEquipment(
          catalogId: editing ? 'Radio' : null,
          designation: editing ? 'Radio' : '',
          quantity: 4));
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: InstallationForm(
        order: order,
        enabled: true,
        zones: const [],
        supervisors: const [],
        departments: const ['security'],
        catalog: const [
          InstallationOption('Radio', 'Radio', {
            'department': {'label': 'Sécurité'}
          }),
          InstallationOption('Lampe', 'Lampe commune',
              {'tenantId': 'ci', 'departmentId': 'security'}),
          InstallationOption('Balai', 'Balai', {'departmentId': 'cleaning'}),
        ],
      )))));
      final picker = find.widgetWithText(
          DropdownButtonFormField<String>, 'Équipement du catalogue');
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      expect(find.text('Lampe commune'), findsOneWidget);
      expect(find.text('Radio'), findsWidgets);
      expect(find.text('Balai'), findsNothing);
      await tester.tap(find.text('Lampe commune').last);
      await tester.pumpAndSettle();
      expect(order.equipment.single.catalogId, 'Lampe');
      expect(order.equipment.single.designation, 'Lampe commune');
      expect(order.equipment.single.quantity, 4);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'incomplete drafts show required errors only after transmission and open the failing section',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final order = fixture()..agents.clear();
    final formKey = GlobalKey<FormState>();
    Widget screen(int attempt) => MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: InstallationForm(
          order: order,
          enabled: true,
          guided: true,
          validationAttempt: attempt,
          validationKey: formKey,
          zones: const [],
          supervisors: const [],
          catalog: const [],
          departments: const ['security'],
        ))));
    await tester.pumpWidget(screen(0));
    expect(find.text('Ajouter au moins un agent avant de transmettre.'),
        findsNothing);
    expect(formKey.currentState!.validate(), true);
    await tester.pumpWidget(screen(1));
    await tester.pumpAndSettle();
    expect(find.text('ÉTAPE 2 SUR 4'), findsOneWidget);
    expect(find.text('Ajouter au moins un agent avant de transmettre.'),
        findsOneWidget);
    expect(order.validate(), isNotEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('optional GPS still rejects invalid typed coordinates',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 2500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final order = fixture();
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: InstallationForm(
      order: order,
      enabled: true,
      validationKey: formKey,
      zones: const [],
      supervisors: const [],
      catalog: const [],
      departments: const ['security'],
    )))));
    expect(formKey.currentState!.validate(), true);
    final latitude = find.widgetWithText(TextFormField, 'Latitude');
    await tester.ensureVisible(latitude);
    await tester.enterText(latitude, 'invalide');
    expect(formKey.currentState!.validate(), false);
    await tester.pump();
    expect(find.text('Coordonnée invalide.'), findsOneWidget);
    await tester.enterText(latitude, '');
    expect(formKey.currentState!.validate(), true);
  });
  test(
      'PDF follows both security and cleaning templates and paginates long orders',
      () async {
    for (final department in ['security', 'cleaning']) {
      final order = fixture()
        ..departmentId = department
        ..bonNumber = '31503'
        ..contractDate = DateTime(2026, 11, 12)
        ..status = InstallationStatus.approved;
      final bytes = await InstallationPdf.build(order);
      expect(ascii.decode(bytes.take(4).toList()), '%PDF');
      await Directory('build/installation-preview').create(recursive: true);
      await File('build/installation-preview/$department.pdf')
          .writeAsBytes(bytes);
      order.agents.addAll(List.generate(
          65,
          (i) =>
              InstallationAgent(name: 'Agent $i', type: 'ADS', phone: '123')));
      expect((await InstallationPdf.build(order)).length,
          greaterThan(bytes.length));
    }
    expect(() => InstallationPdf.build(fixture()), throwsStateError);
  });
}
