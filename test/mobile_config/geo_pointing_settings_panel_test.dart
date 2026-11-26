import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/mobile_config/geo_pointing_settings_panel.dart';
import 'package:spas_web/services/geo_pointing_config.dart';

Future<List<GeoPointingConfig>> _pump(
  WidgetTester tester, {
  GeoPointingConfig initial = const GeoPointingConfig.recommended(),
  bool canEdit = true,
}) async {
  final saved = <GeoPointingConfig>[];
  tester.view.physicalSize = const Size(1400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: GeoPointingSettingsPanel(
          initial: initial,
          canEdit: canEdit,
          readOnlyReason: 'lecture seule',
          onSave: (config) async => saved.add(config),
        ),
      ),
    ),
  ));
  return saved;
}

String _summary(WidgetTester tester) => tester
    .widgetList<Text>(find.descendant(
        of: find.byKey(const ValueKey('geo-summary')),
        matching: find.byType(Text)))
    .first
    .data!;

void main() {
  testWidgets('shows the 4 settings, header and recommended summary',
      (tester) async {
    await _pump(tester);
    expect(find.text('Pointage par géolocalisation'), findsOneWidget);
    expect(
        find.text(
            'S\'applique seulement aux pays/rôles en mode Géolocalisation'),
        findsOneWidget);
    expect(find.text('Temps d\'attente du GPS par essai'), findsOneWidget);
    expect(find.text('Nombre d\'essais GPS avant la photo'), findsOneWidget);
    expect(
        find.text('Proposer la photo si le GPS ne répond pas'), findsOneWidget);
    expect(find.text('Exigence de précision GPS'), findsOneWidget);
    expect(find.textContaining('Jamais modifié'), findsOneWidget);
    expect(_summary(tester), const GeoPointingConfig.recommended().summary);
  });

  testWidgets('summary updates live and the stepper stops at the bounds',
      (tester) async {
    await _pump(tester);
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const ValueKey('geo-timeout-plus')));
      await tester.pump();
    }
    expect(find.text('45 s'), findsWidgets);
    expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('geo-timeout-plus')))
            .onPressed,
        isNull);
    expect(_summary(tester), contains('au plus 45 s'));

    await tester.tap(find.text('Non'));
    await tester.pump();
    expect(_summary(tester), contains('aucune photo n\'est proposée'));
    expect(
        find.textContaining('Modifications non enregistrées'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('geo-recommended')));
    await tester.pump();
    expect(_summary(tester), const GeoPointingConfig.recommended().summary);
  });

  testWidgets('save asks for confirmation and sends the draft', (tester) async {
    final saved = await _pump(
      tester,
      initial: GeoPointingConfig.fromJson({'attemptTimeoutSeconds': 25}),
    );
    await tester.tap(find.text('3 essais'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('geo-save')));
    await tester.pumpAndSettle();
    expect(find.text('Appliquer ce réglage aux téléphones ?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('geo-confirm-save')));
    await tester.pumpAndSettle();
    expect(saved, hasLength(1));
    expect(saved.single.attemptsBeforePhoto, 3);
    expect(saved.single.attemptTimeoutSeconds, 25);
  });

  testWidgets('read-only profiles cannot change anything', (tester) async {
    final saved = await _pump(tester, canEdit: false);
    expect(find.text('lecture seule'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('geo-timeout-plus')));
    await tester.tap(find.text('Stricte'));
    await tester.pump();
    expect(_summary(tester), const GeoPointingConfig.recommended().summary);
    expect(
        tester
            .widget<ElevatedButton>(find.byKey(const ValueKey('geo-save')))
            .onPressed,
        isNull);
    expect(saved, isEmpty);
  });
}
