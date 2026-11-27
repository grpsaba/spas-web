import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/error_logs/models/geo_diagnostic.dart';
import 'package:spas_web/error_logs/models/visit_timeline.dart';
import 'package:spas_web/geo_tracking/geo_tracking_page.dart';
import 'package:spas_web/geo_tracking/models/mobile_event.dart';

// Synthetic events shaped like the mobile contract.
MobileEvent _event(String name, Map<String, dynamic> data) =>
    MobileEvent.fromMap('id-$name', {
      'event': name,
      'clientTimestamp': '2026-11-27T08:00:00.000',
      'role': 'supervisor',
      'userName': 'Superviseur Test',
      'siteCode': 'S-101',
      'data': data,
    });

void main() {
  test('new events have French labels', () {
    expect(MobileEventLabels.label('gps_health'), 'État du GPS');
    expect(MobileEventLabels.label('gps_first_fix'), 'Première position');
    expect(MobileEventLabels.label('gps_stream_restarted'), 'GPS relancé');
    expect(AttemptOutcome.label('photo_chosen'),
        'Photo choisie pendant la recherche');
    expect(AttemptOutcome.all, contains('photo_chosen'));
  });

  test('gps_health details are readable, missing values are skipped', () {
    final event = _event('gps_health', {
      'trigger': 'pointing_started',
      'permission': 'whileInUse',
      'locationServiceEnabled': true,
      'gpsProviderEnabled': true,
      'networkProviderEnabled': false,
      'powerSaveMode': true,
      'batteryPercent': 23,
      'trackerActive': true,
      'backgroundRequested': false,
      'lastFixAgeMs': 12000,
      'lastFixAccuracyM': 8.6,
      'fixesLast5Min': 41,
      'streamRestarts': 1,
      'lastStreamError': null,
      'satellitesInView': 15,
      'satellitesUsed': 7,
      'bestCn0DbHz': 31.8,
    });
    expect(event.title, 'État du GPS');
    expect(
      event.dataSummary,
      'Déclencheur : pointing_started · Permission : pendant l\'utilisation · '
      'Localisation : activé · GPS : activé · Réseau : désactivé · '
      'Économie d\'énergie : oui · Batterie : 23 % · Suivi continu : actif · '
      'Arrière-plan demandé : non · Dernière position : il y a 12 s (± 9 m) · '
      'Positions sur 5 min : 41 · Satellites : 7 utilisés / 15 vus · '
      'Meilleur signal : 32 dB-Hz · Relances du GPS : 1',
    );
    final empty = _event('gps_health', {
      'permission': 'deniedForever',
      'lastFixAgeMs': null,
      'satellitesInView': null,
    });
    expect(empty.dataSummary,
        'Permission : refusée définitivement · Dernière position : aucune');
  });

  test('first fix, restart, photo chosen and saved duration', () {
    final fix = _event('gps_first_fix', {'ms': 14200, 'accuracyM': 18.2});
    expect(fix.title, 'Première position');
    expect(fix.dataSummary, 'après 14 s · précision ± 18 m');

    final restart = _event('gps_stream_restarted', {'reason': 'stream_error'});
    expect(restart.title, 'GPS relancé');
    expect(restart.dataSummary, 'Raison : stream_error');

    final chosen = _event('geo_attempt_finished',
        {'outcome': 'photo_chosen', 'durationMs': 52000, 'attempt': 1});
    expect(chosen.title,
        'Essai GPS terminé · Photo choisie pendant la recherche');
    expect(chosen.dataSummary,
        'Résultat : Photo choisie pendant la recherche · durée 52 s · attempt: 1');
    expect(_event('geo_attempt_finished', {'outcome': 'timeout'}).title,
        'Essai GPS terminé');

    final saved = _event('pointing_saved', {
      'durationMs': 65000,
      'gpsWaitMs': 45000,
      'firstFixMs': null,
      'decisionMs': 6000,
      'photoMs': 9000,
      'saveMs': 2000,
      'relaunches': 0,
      'startedAt': '2026-11-27T07:58:55.000Z',
      'pointingMethod': 'photo_fallback',
    });
    expect(saved.title, 'Pointage enregistré · 1 min 05 s');
    expect(
        saved.dataSummary,
        'Durée 1 min 05 s · Méthode : Photo après échec GPS · Attente GPS '
        '45 s · Décision 6 s · Photo 9 s · Enregistrement 2 s');
    // Older builds: no duration in the event.
    final old = _event('pointing_saved', {'method': 'geo'});
    expect(old.title, 'Pointage enregistré');
    expect(old.dataSummary, 'method: geo');

    // The visit timeline shows the same title.
    expect(VisitTimelineEntry.fromMobileEvent(saved).title,
        'Pointage enregistré · 1 min 05 s');
  });

  testWidgets('journal table shows titles and details', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MobileEventsTable(events: [
          _event('pointing_saved', {'durationMs': 65000, 'gpsWaitMs': 45000}),
          _event('gps_stream_restarted', {'reason': 'timeout'}),
          _event('gps_health', {
            'permission': 'always',
            'gpsProviderEnabled': true,
            'powerSaveMode': false,
            'batteryPercent': 80,
            'lastFixAgeMs': 3000,
            'lastFixAccuracyM': 5,
            'fixesLast5Min': 60,
            'satellitesInView': 20,
            'satellitesUsed': 11,
            'streamRestarts': 0,
          }),
        ]),
      ),
    ));
    expect(find.text('Pointage enregistré · 1 min 05 s'), findsOneWidget);
    expect(find.text('GPS relancé'), findsOneWidget);
    expect(find.text('Raison : timeout'), findsOneWidget);
    expect(find.text('État du GPS'), findsOneWidget);
    expect(find.textContaining('Satellites : 11 utilisés / 20 vus'),
        findsOneWidget);
  });
}
