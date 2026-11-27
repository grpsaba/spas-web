import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/geo_tracking/models/geo_stats.dart';
import 'package:spas_web/geo_tracking/models/pointing_duration.dart';
import 'package:spas_web/geo_tracking/pointing_duration_tab.dart';
import 'package:spas_web/geo_tracking/services/geo_tracking_service.dart';

import 'duration_fixtures.dart';

DurationSourceDocument _doc(
  String id,
  String person,
  String site,
  int totalMs, {
  bool zone = false,
  String method = 'geo',
  int gpsWaitMs = 30000,
  int relaunches = 0,
  bool estimated = false,
  int day = 26,
}) =>
    DurationSourceDocument(
      id,
      durationPointing(
        personUid: person,
        personName: zone ? 'Chef $person' : 'Superviseur $person',
        siteUid: site,
        siteCode: site.toUpperCase(),
        siteName: 'Site démo $site',
        at: DateTime(2026, 11, day, 9),
        zone: zone,
        method: method,
        visitId: 'visit-$id',
        duration: estimated
            ? null
            : durationMap(totalMs,
                gpsWaitMs: gpsWaitMs,
                relaunches: relaunches,
                decisionMs: method == 'photo_fallback' ? 4000 : null,
                photoMs: method == 'geo' ? null : 8000),
      ),
      role: zone ? GeoRole.zoneChief : GeoRole.supervisor,
    );

/// 5 pointings: medians and averages easy to check by hand.
PointingDurationLoadResult _smallResult() => PointingDurationLoadResult.build(
      [
        _doc('1', 'a', 's1', 40000, gpsWaitMs: 30000, day: 25),
        _doc('2', 'a', 's2', 83000,
            method: 'photo_fallback', gpsWaitMs: 45000, relaunches: 1),
        _doc('3', 'a', 's2', 200000, gpsWaitMs: 150000),
        _doc('4', 'b', 's1', 30000, zone: true, method: 'photo', gpsWaitMs: 0),
        _doc('5', 'b', 's1', 0, zone: true, estimated: true),
        DurationSourceDocument(
          'old',
          durationPointing(
              personUid: 'a',
              personName: 'Superviseur a',
              siteUid: 's1',
              at: DateTime(2026, 11, 26)),
          role: GeoRole.supervisor,
        ),
      ],
      estimates: {
        'visit-5': const PointingDurationBreakdown(
            totalMs: 65000, gpsWaitMs: 50000, relaunches: 1),
      },
      warnings: const ['mobile_events : permission-denied'],
    );

Future<void> _pump(WidgetTester tester, PointingDurationLoadResult result,
    {List<DateTime>? asked}) async {
  tester.view.physicalSize = const Size(1600, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: PointingDurationTab(
        initialRange: DateTimeRange(
            start: DateTime(2026, 11, 20), end: DateTime(2026, 11, 26)),
        loader: (start, end) async {
          asked?.addAll([start, end]);
          return result;
        },
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Roboto (the app's font, see main.dart) so that widths are realistic: the
/// default test font draws every glyph as a 1 em square.
Future<void> _loadRoboto(WidgetTester tester) => tester.runAsync(() async {
      final loader = FontLoader('Roboto');
      for (final file in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']) {
        final bytes = await File('assets/fonts/$file').readAsBytes();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    });

Finder _inTable(String key, Finder finder) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: finder);

void main() {
  testWidgets('KPIs, tables, notes and estimated rows', (tester) async {
    final asked = <DateTime>[];
    await _pump(tester, _smallResult(), asked: asked);
    expect(asked, [DateTime(2026, 11, 20), DateTime(2026, 11, 27)]);

    // 30 40 65 83 200 s → median 65 s, average 83.6 s.
    expect(find.text('Durée médiane'), findsOneWidget);
    expect(find.text('1 min 05 s'), findsWidgets);
    expect(find.text('1 min 24 s'), findsWidgets);
    expect(find.text('Pointages mesurés'), findsOneWidget);
    expect(find.text('5'), findsWidgets);
    expect(find.text('Pointages de plus de 2 min'), findsOneWidget);
    expect(find.text('20 %'), findsWidgets);
    // GPS wait: 30 45 150 50 (photo-mode pointing excluded) → 68,75 s.
    expect(find.text('1 min 09 s'), findsWidgets);
    expect(find.textContaining('1 pointage(s) « estimé (journal) »'),
        findsOneWidget);
    // The old pointing (no duration, no journal) is « non mesuré »: listed
    // apart, never counted as 0.
    expect(
        find.textContaining('1 pointage(s) « non mesuré » (1 d\'une ancienne '
            'version de l\'app, sans journal) : non comptés dans les durées.'),
        findsOneWidget);
    expect(find.text('Non mesurés'), findsWidgets);
    expect(find.text('0 s'), findsNothing);
    expect(find.textContaining('permission-denied'), findsOneWidget);

    expect(find.text('Par superviseur / chef de zone'), findsOneWidget);
    expect(find.text('Par site'), findsOneWidget);
    expect(find.text('Par jour'), findsOneWidget);
    expect(find.text('Par méthode'), findsOneWidget);
    expect(_inTable('duration-by-person', find.text('Superviseur a')),
        findsOneWidget);
    expect(_inTable('duration-by-person', find.text('Chef de zone')),
        findsOneWidget);
    expect(_inTable('duration-by-day', find.text('mer. 25/11')),
        findsOneWidget);
    expect(_inTable('duration-by-method', find.text('Photo après échec GPS')),
        findsOneWidget);
    // Site S2: slowest 200 s.
    expect(_inTable('duration-by-site', find.text('3 min 20 s')),
        findsOneWidget);
  });

  testWidgets('role and method filters recompute everything', (tester) async {
    await _pump(tester, _smallResult());
    await tester.tap(find.byKey(const ValueKey('duration-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chefs de zone').last);
    await tester.pumpAndSettle();
    expect(_inTable('duration-by-person', find.text('Superviseur a')),
        findsNothing);
    expect(_inTable('duration-by-person', find.text('Chef b')), findsOneWidget);
    // 30 s and 65 s → median 47,5 s.
    expect(find.text('48 s'), findsWidgets);
    expect(find.textContaining('non mesuré'), findsNothing);
    expect(find.text('Non mesurés'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('duration-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tous').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('duration-method')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo après échec GPS').last);
    await tester.pumpAndSettle();
    expect(_inTable('duration-by-method', find.text('GPS')), findsNothing);
    expect(_inTable('duration-by-person', find.text('Superviseur a')),
        findsOneWidget);
    expect(_inTable('duration-by-person', find.text('Chef b')), findsNothing);
  });

  testWidgets('a row opens its pointings with the breakdown', (tester) async {
    await _pump(tester, _smallResult());
    await tester.tap(_inTable('duration-by-person', find.text('Chef b')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Par superviseur / chef de zone · Chef b'),
        findsOneWidget);
    expect(find.text('Durée totale'), findsOneWidget);
    expect(find.text('Attente GPS'), findsOneWidget);
    expect(find.text('Décision'), findsOneWidget);
    expect(find.text('Enreg.'), findsOneWidget);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('estimé (journal)'), findsOneWidget);
    expect(find.text('mesuré'), findsOneWidget);
    expect(find.textContaining('2 pointage(s) · médiane 48 s'), findsOneWidget);
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    expect(find.text('Durée totale'), findsNothing);
  });

  testWidgets('« non mesuré » pointing in the details, never 0',
      (tester) async {
    await _pump(tester, _smallResult());
    await tester
        .tap(_inTable('duration-by-person', find.text('Superviseur a')));
    await tester.pumpAndSettle();
    final dialog = find.byType(Dialog);
    // 40, 83 and 200 s measured; the old pointing is listed apart.
    expect(
        find.descendant(
            of: dialog,
            matching: find.textContaining(
                '3 pointage(s) + 1 non mesuré · médiane 1 min 23 s')),
        findsOneWidget);
    // Durée totale and Source of the old pointing, breakdown « — ».
    expect(find.descendant(of: dialog, matching: find.text('non mesuré')),
        findsNWidgets(2));
    expect(find.descendant(of: dialog, matching: find.text('0 s')),
        findsNothing);
    expect(find.descendant(of: dialog, matching: find.text('—')),
        findsWidgets);
  });

  testWidgets('details: Source visible on a laptop screen, rounded seconds',
      (tester) async {
    final result = PointingDurationLoadResult.build([
      DurationSourceDocument(
        'r1',
        durationPointing(
          personUid: 'sup-x',
          personName: 'Superviseur Exemple',
          siteUid: 'site-x',
          siteCode: 'S-999',
          siteName: 'Résidence démo au nom très long pour la largeur',
          at: DateTime(2026, 11, 26, 9),
          method: 'photo_fallback',
          visitId: 'visit-r1',
          duration: durationMap(61990,
              gpsWaitMs: 45000,
              firstFixMs: 9950,
              decisionMs: 4200,
              photoMs: 9000,
              saveMs: 1990),
        ),
        role: GeoRole.supervisor,
      ),
      DurationSourceDocument(
        'r2',
        durationPointing(
          personUid: 'sup-x',
          personName: 'Superviseur Exemple',
          siteUid: 'site-x',
          at: DateTime(2026, 11, 26, 10),
          visitId: 'visit-r2',
        ),
        role: GeoRole.supervisor,
      ),
    ], estimates: {
      'visit-r2': const PointingDurationBreakdown(totalMs: 50000),
    });
    await _loadRoboto(tester);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Scaffold(
        body: PointingDurationTab(
          initialRange: DateTimeRange(
              start: DateTime(2026, 11, 20), end: DateTime(2026, 11, 26)),
          loader: (start, end) async => result,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // The by-day table opens the most columns (person and site shown).
    final day = _inTable('duration-by-day', find.text('jeu. 26/11'));
    await tester.ensureVisible(day);
    await tester.pumpAndSettle();
    await tester.tap(day);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    Finder inDialog(String text) =>
        find.descendant(of: find.byType(Dialog), matching: find.text(text));
    final dialog = tester.getRect(find.byType(Dialog));
    for (final text in [
      'Personne',
      'Site',
      'Méthode',
      'Durée totale',
      'Source',
      'estimé (journal)',
      'mesuré',
    ]) {
      final rect = tester.getRect(inDialog(text));
      expect(rect.right, lessThanOrEqualTo(dialog.right),
          reason: '« $text » cut off');
    }

    // 1 990 ms → « 2 s », 9 950 ms → « 10 s », 4 200 ms → « 4,2 s ».
    expect(inDialog('2 s'), findsOneWidget);
    expect(inDialog('2,0 s'), findsNothing);
    expect(inDialog('10 s'), findsOneWidget);
    expect(inDialog('4,2 s'), findsOneWidget);
    expect(inDialog('1 min 02 s'), findsOneWidget);
  });

  testWidgets('tables are sortable', (tester) async {
    await _pump(tester, _smallResult());
    List<String> siteOrder() => tester
        .widgetList<Text>(_inTable('duration-by-site', find.byType(Text)))
        .map((t) => t.data ?? '')
        .where((t) => t.startsWith('S1') || t.startsWith('S2'))
        .toList();
    // Slowest median first by default: S2 (141,5 s) before S1 (40 s).
    expect(siteOrder(), ['S2 · Site démo s2', 'S1 · Site démo s1']);
    await tester.tap(_inTable('duration-by-site', find.text('Pointages')));
    await tester.pumpAndSettle();
    // S1 has 3 pointings, S2 has 2: ascending after the first tap.
    expect(siteOrder(), ['S2 · Site démo s2', 'S1 · Site démo s1']);
    await tester.tap(_inTable('duration-by-site', find.text('Pointages')));
    await tester.pumpAndSettle();
    expect(siteOrder(), ['S1 · Site démo s1', 'S2 · Site démo s2']);
  });

  testWidgets('synthetic week renders without overflow', (tester) async {
    await _pump(tester, syntheticDurationResult());
    final report =
        PointingDurationReport.aggregate(syntheticDurationResult().records);
    expect(find.text(formatDuration(report.summary.medianMs)), findsWidgets);
    expect(_inTable('duration-by-day', find.text('ven. 20/11')),
        findsOneWidget);
    expect(_inTable('duration-by-person', find.text('Superviseur Charlie')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
