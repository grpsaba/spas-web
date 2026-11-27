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

String _value(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('geo-photo-offer-value')))
    .data!;

void main() {
  testWidgets('one photo button delay control, header and explanation',
      (tester) async {
    await _pump(tester);
    expect(find.text('Pointage par géolocalisation'), findsOneWidget);
    expect(find.text('Bouton photo après (secondes)'), findsOneWidget);
    expect(find.textContaining('Le GPS continue de chercher'), findsWidgets);
    expect(find.textContaining('« GPS introuvable »'), findsWidgets);
    expect(find.textContaining('Recommandé : 45 s (entre 15 et 120 s)'),
        findsOneWidget);
    // The two former controls are gone.
    expect(find.text('Temps d\'attente du GPS par essai'), findsNothing);
    expect(find.text('Nombre d\'essais GPS avant la photo'), findsNothing);
    expect(
        find.text('Proposer la photo si le GPS ne répond pas'), findsOneWidget);
    expect(find.text('Exigence de précision GPS'), findsOneWidget);
    expect(find.textContaining('Jamais modifié'), findsOneWidget);
    expect(_value(tester), '45 s');
    expect(_summary(tester), const GeoPointingConfig.recommended().summary);
    expect(find.byKey(const ValueKey('geo-legacy')), findsNothing);
  });

  testWidgets('stepper moves by 5 s and stops at the bounds', (tester) async {
    await _pump(tester);
    for (var i = 0; i < 20; i++) {
      await tester.tap(find.byKey(const ValueKey('geo-photo-offer-plus')));
      await tester.pump();
    }
    expect(_value(tester), '120 s');
    expect(
        tester
            .widget<IconButton>(
                find.byKey(const ValueKey('geo-photo-offer-plus')))
            .onPressed,
        isNull);
    expect(_summary(tester), contains('après 120 s'));
    for (var i = 0; i < 30; i++) {
      await tester.tap(find.byKey(const ValueKey('geo-photo-offer-minus')));
      await tester.pump();
    }
    expect(_value(tester), '15 s');
    final slider =
        tester.widget<Slider>(find.byKey(const ValueKey('geo-photo-offer-slider')));
    expect(slider.min, 15);
    expect(slider.max, 120);
    expect(slider.divisions, 21);

    await tester.tap(find.text('Non'));
    await tester.pump();
    expect(_summary(tester), contains('Aucune photo n\'est proposée'));
    expect(find.text('Sans effet tant que la photo de secours est désactivée.'),
        findsOneWidget);
    expect(
        find.textContaining('Modifications non enregistrées'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('geo-recommended')));
    await tester.pump();
    expect(_summary(tester), const GeoPointingConfig.recommended().summary);
  });

  testWidgets('save asks for confirmation and sends the draft', (tester) async {
    final saved = await _pump(
      tester,
      initial: GeoPointingConfig.fromJson(
          {'attemptTimeoutSeconds': 25, 'attemptsBeforePhoto': 2}),
    );
    expect(find.byKey(const ValueKey('geo-legacy')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('geo-photo-offer-plus')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('geo-save')));
    await tester.pumpAndSettle();
    expect(find.text('Appliquer ce réglage aux téléphones ?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('geo-confirm-save')));
    await tester.pumpAndSettle();
    expect(saved, hasLength(1));
    expect(saved.single.photoOfferAfterSeconds, 50);
    // Legacy values are only displayed: the save never writes them, so
    // Firestore keeps them for phones still running app 1.8.0+18.
    expect(saved.single.settingsToJson(), {
      'photoOfferAfterSeconds': 50,
      'photoFallbackEnabled': true,
      'accuracyRule': 'normal',
    });
    expect(saved.single.legacyAttemptTimeoutSeconds, 25);
    expect(saved.single.legacyAttemptsBeforePhoto, 2);
  });

  testWidgets('read-only profiles cannot change anything', (tester) async {
    final saved = await _pump(tester, canEdit: false);
    expect(find.text('lecture seule'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('geo-photo-offer-plus')));
    await tester.tap(find.text('Stricte'));
    await tester.pump();
    expect(_value(tester), '45 s');
    expect(_summary(tester), const GeoPointingConfig.recommended().summary);
    expect(
        tester
            .widget<ElevatedButton>(find.byKey(const ValueKey('geo-save')))
            .onPressed,
        isNull);
    expect(saved, isEmpty);
  });
}
