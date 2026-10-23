import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/zone_member/zone_member_site_scope_fields.dart';

void main() {
  testWidgets('selecting global scope removes zone selection and validation',
      (tester) async {
    var scope = ZoneMemberScope.assigned;
    Zone? selected;
    final formKey = GlobalKey<FormState>();
    final zones = Stream.value([
      Zone(codeZone: 'A', name: 'Bamako', tenantId: 'ml'),
      Zone(codeZone: 'B', name: 'Ouagadougou', tenantId: 'bf'),
    ]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: Form(
        key: formKey,
        child: StatefulBuilder(builder: (context, setState) {
          return ZoneMemberSiteScopeFields(
            tenantId: 'ml',
            departmentId: 'security',
            scope: scope,
            selectedZone: selected,
            zones: zones,
            onScopeChanged: (value) => setState(() {
              scope = value;
              if (value == ZoneMemberScope.global) selected = null;
            }),
            onZoneChanged: (value) => setState(() => selected = value),
          );
        }),
      )),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Zone>));
    await tester.pumpAndSettle();
    expect(find.text('Ouagadougou'), findsNothing);
    await tester.tap(find.text('Bamako').last);
    await tester.pumpAndSettle();
    expect(selected?.codeZone, 'A');
    expect(formKey.currentState!.validate(), isTrue);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toutes les zones · Sécurité').last);
    await tester.pumpAndSettle();
    expect(scope, ZoneMemberScope.global);
    expect(selected, isNull);
    expect(find.byType(DropdownButtonFormField<Zone>), findsNothing);
    expect(formKey.currentState!.validate(), isTrue);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zone assignée').last);
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<Zone>), findsOneWidget);
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Zone>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bamako').last);
    await tester.pumpAndSettle();
    expect(formKey.currentState!.validate(), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'missing country, loading, empty and failed queries are explained',
      (tester) async {
    final controller = StreamController<List<Zone>>();
    addTearDown(controller.close);
    final formKey = GlobalKey<FormState>();
    Widget screen(String? country) => MaterialApp(
          home: Scaffold(
              body: Form(
            key: formKey,
            child: ZoneMemberSiteScopeFields(
              tenantId: country,
              departmentId: 'security',
              scope: ZoneMemberScope.assigned,
              selectedZone: null,
              zones: controller.stream,
              onScopeChanged: (_) {},
              onZoneChanged: (_) {},
            ),
          )),
        );
    await tester.pumpWidget(screen(null));
    expect(find.text('Sélectionnez d’abord un pays.'), findsOneWidget);
    await tester.pumpWidget(screen('ml'));
    expect(find.text('Chargement des zones…'), findsOneWidget);
    controller.add([]);
    await tester.pumpAndSettle();
    expect(find.text('Aucune zone disponible pour ce pays.'), findsOneWidget);
    expect(
        tester
            .widget<DropdownButtonFormField<Zone>>(
                find.byType(DropdownButtonFormField<Zone>))
            .onChanged,
        isNull);
    expect(formKey.currentState!.validate(), isFalse);

    controller.addError(StateError('query failed'));
    await tester.pumpAndSettle();
    expect(find.text('Impossible de charger les zones. Rechargez la page.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'changing country rejects a zone belonging to the previous country',
      (tester) async {
    final mali = Zone(codeZone: 'A', name: 'Bamako', tenantId: 'ml');
    final burkina = Zone(codeZone: 'B', name: 'Ouagadougou', tenantId: 'bf');
    final zones = Stream.value([mali, burkina]);
    final formKey = GlobalKey<FormState>();
    Widget screen(String country) => MaterialApp(
          home: Scaffold(
              body: Form(
            key: formKey,
            child: ZoneMemberSiteScopeFields(
              tenantId: country,
              departmentId: 'security',
              scope: ZoneMemberScope.assigned,
              selectedZone: mali,
              zones: zones,
              onScopeChanged: (_) {},
              onZoneChanged: (_) {},
            ),
          )),
        );
    await tester.pumpWidget(screen('ml'));
    await tester.pumpAndSettle();
    expect(formKey.currentState!.validate(), isTrue);
    await tester.pumpWidget(screen('bf'));
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Zone>));
    await tester.pumpAndSettle();
    expect(find.text('Bamako'), findsNothing);
    expect(find.text('Ouagadougou').last, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
