import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/agent/widgets/agent_department_field.dart';
import 'package:spas_web/model.dart';

void main() {
  for (final reversed in [false, true]) {
    testWidgets(
        'Editing duplicate cleaning departments selects and saves canonical document (reversed: $reversed)',
        (tester) async {
      final legacy = Department(label: 'NETTOYAGE', documentId: 'Nettoyage');
      final canonical = Department(
          id: 'cleaning', label: 'Nettoyage', documentId: 'cleaning');
      final security = Department(label: 'Sécurité', documentId: 'security');
      final options = [legacy, canonical, security];
      final form = GlobalKey<FormState>();
      Department? saved;
      Department? changed;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Form(
        key: form,
        child: AgentDepartmentField(
          departments: reversed ? options.reversed : options,
          departmentId: ' NETTOYAGE ',
          onChanged: (value) => changed = value,
          onSaved: (value) => saved = value,
        ),
      ))));
      expect(tester.takeException(), isNull);
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>));
      expect(dropdown.initialValue, 'cleaning');
      expect(form.currentState!.validate(), isTrue);
      form.currentState!.save();
      expect(saved, same(canonical));

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sécurité').last);
      await tester.pumpAndSettle();
      expect(changed, same(security));
      form.currentState!.save();
      expect(saved, same(security));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'Unknown or removed department clears selection and requires a choice',
      (tester) async {
    final form = GlobalKey<FormState>();
    Department? saved;
    Widget screen(List<Department> options, String? id) => MaterialApp(
          home: Scaffold(
              body: Form(
                  key: form,
                  child: AgentDepartmentField(
                    departments: options,
                    departmentId: id,
                    onChanged: (_) {},
                    onSaved: (value) => saved = value,
                  ))),
        );
    await tester
        .pumpWidget(screen([Department(label: 'Nettoyage')], 'cleaning'));
    expect(form.currentState!.validate(), isTrue);
    await tester
        .pumpWidget(screen([Department(label: 'Sécurité')], 'cleaning'));
    expect(tester.takeException(), isNull);
    expect(form.currentState!.validate(), isFalse);
    form.currentState!.save();
    expect(saved, isNull);
    await tester.pumpWidget(screen([], null));
    expect(tester.takeException(), isNull);
    expect(form.currentState!.validate(), isFalse);
  });

  testWidgets('Distinct IDs with the same label remain separate choices',
      (tester) async {
    final first = Department(id: 'service-a', label: 'Service');
    final second = Department(id: 'service-b', label: 'Service');
    final form = GlobalKey<FormState>();
    Department? saved;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Form(
      key: form,
      child: AgentDepartmentField(
        departments: [first, second],
        departmentId: 'service-b',
        onChanged: (_) {},
        onSaved: (value) => saved = value,
      ),
    ))));
    expect(tester.takeException(), isNull);
    form.currentState!.save();
    expect(saved, same(second));
  });
}
