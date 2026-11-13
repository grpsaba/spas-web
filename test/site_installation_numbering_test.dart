import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/site_installation/installation_numbering.dart';
import 'package:spas_web/site_installation/installation_numbering_panel.dart';

void main() {
  test('a plain numeric sequence continues from the last manually used number',
      () {
    expect(InstallationNumbering.parseLastNumber(' 31502 '), 31502);
    expect(InstallationNumbering.fromJson({'lastNumber': 31502}).nextNumber,
        31503);
    expect(const InstallationNumbering(0).nextNumber, 1);
    for (final input in [
      '',
      '-1',
      '1.5',
      '31 502',
      'BMPS-31502',
      '3e4',
      '9007199254740991'
    ]) {
      expect(() => InstallationNumbering.parseLastNumber(input),
          throwsFormatException,
          reason: input);
    }
    for (final number in [null, -1, 1.5, '31502', 9007199254740992]) {
      expect(() => InstallationNumbering.fromJson({'lastNumber': number}),
          throwsFormatException);
    }
    expect(
        () => const InstallationNumbering(InstallationNumbering.maxNumber)
            .nextNumber,
        throwsStateError);
  });

  testWidgets(
      'initialization previews the next number, validates input and saves only the chosen seed',
      (tester) async {
    final stream = StreamController<InstallationNumbering?>();
    addTearDown(stream.close);
    String? saved;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: InstallationNumberingPanel(
                stream: stream.stream,
                canInitialize: true,
                onInitialize: (number) async {
                  saved = number;
                }))));
    stream.add(null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Initialiser le compteur'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'BMPS-55');
    await tester.tap(find.text('Initialiser'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(find.textContaining('numéro entier positif valide'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '31502');
    await tester.pump();
    expect(find.text('Le prochain bon validé recevra le numéro 31503.'),
        findsOneWidget);
    await tester.tap(find.text('Initialiser'));
    await tester.pumpAndSettle();
    expect(saved, '31502');
    stream.add(const InstallationNumbering(31502));
    await tester.pumpAndSettle();
    expect(find.text('Initialiser le compteur'), findsNothing);
    expect(
        find.textContaining('Dernier numéro utilisé : 31502'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'reviewers see the setup requirement without an initialization action',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: InstallationNumberingPanel(
                stream: Stream.value(null),
                canInitialize: false,
                onInitialize: (_) async {
                  fail('Only administrators can initialize');
                }))));
    await tester.pumpAndSettle();
    expect(find.text('Initialiser le compteur'), findsNothing);
    expect(find.textContaining('Un administrateur'), findsOneWidget);
  });
}
