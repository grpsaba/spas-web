import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/site_installation/installation_form.dart';
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
      'submission accepts preliminary data; approval requires bon and operational fields',
      () {
    final order = fixture();
    expect(order.validate(), isEmpty);
    expect(order.validate(forSite: true), isNotEmpty);
    order.bonNumber = '31503';
    order.zone = {'codeZone': 'z1'};
    order.supervisor = {'UID': 's1'};
    order.contractDate = DateTime(2026, 11, 12);
    order.agentCount = 2;
    order.latitude = 12.6;
    order.longitude = -8;
    expect(order.validate(forSite: true), isEmpty);
    order.equipment.single.quantity = 0;
    expect(order.validate(), isNotEmpty);
    order.latitude = double.nan;
    expect(order.validate(forSite: true), isNotEmpty);
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
      await tester.ensureVisible(find.text('Ajouter un équipement'));
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
