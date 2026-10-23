import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/zone_member/zone_member_scope_field.dart';

void main() {
  testWidgets('Security can select global scope and return to assigned scope',
      (tester) async {
    var scope = ZoneMemberScope.assigned;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
        return ZoneMemberScopeField(
          departmentId: 'security',
          scope: scope,
          onChanged: (value) => setState(() => scope = value),
        );
      })),
    ));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toutes les zones · Sécurité').last);
    await tester.pumpAndSettle();
    expect(scope, ZoneMemberScope.global);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zone assignée').last);
    await tester.pumpAndSettle();
    expect(scope, ZoneMemberScope.assigned);
  });

  testWidgets('Other departments have no global option', (tester) async {
    for (final department in ['cleaning', 'direction', null]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ZoneMemberScopeField(
          departmentId: department,
          scope: ZoneMemberScope.assigned,
          onChanged: (_) {},
        )),
      ));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('Toutes les zones · Sécurité'), findsNothing);
      await tester.tap(find.text('Zone assignée').last);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Invalid global profile requires correction before saving',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: Form(
        key: formKey,
        child: ZoneMemberScopeField(
          departmentId: 'cleaning',
          scope: ZoneMemberScope.global,
          onChanged: (_) {},
        ),
      )),
    ));
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Le périmètre global est réservé à la Sécurité'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
