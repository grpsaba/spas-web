import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/error_logs/models/error_log_model.dart';
import 'package:spas_web/error_logs/models/geo_diagnostic.dart';
import 'package:spas_web/error_logs/models/visit_timeline.dart';
import 'package:spas_web/error_logs/widgets/geo_attempt_sections.dart';
import 'package:spas_web/error_logs/services/visit_timeline_service.dart';
import 'package:spas_web/geo_tracking/models/mobile_event.dart';

// Synthetic documents shaped like the contract (no real data).
Map<String, dynamic> _attemptLog({
  String visitId = 'visit-1',
  int attempt = 1,
  String outcome = 'timeout',
  DateTime? at,
}) =>
    {
      'type': 'pointing_site',
      'errorType': 'gpsTimeoutError',
      'timestamp': Timestamp.fromDate(at ?? DateTime(2026, 11, 26, 8, 0, 30)),
      'supervisor': {'UID': 'sup1', 'firstName': 'Awa', 'lastName': 'Test'},
      'site': {'UID': 'site1', 'name': 'Site A', 'codeSite': 'A1'},
      'isResolved': false,
      'appVersion': '1.8.0+17',
      'deviceInfo': {
        'brand': 'tecno',
        'model': 'KG5',
        'androidVersion': '11',
        'apiLevel': 30,
        'hardware': 'mt6765',
      },
      'visitId': visitId,
      'attemptNumber': attempt,
      'attemptOutcome': outcome,
      'attemptDurationMs': 25012,
      'geoSettings': {
        'attemptTimeoutSeconds': 25,
        'attemptsBeforePhoto': 2,
        'photoFallbackEnabled': true,
        'accuracyRule': 'normal',
      },
      'geoRuleVersion': 2,
      'geoDiagnostic': {
        'result': 'timeout',
        'elapsedSeconds': 25,
        'timeoutSeconds': 25,
        'distanceMeters': 140.4,
        'siteRadiusMeters': 500,
        'latestAccuracyMeters': 62.3,
        'targetAccuracyMeters': 20,
        'receivedCount': 2,
        'recentReadings': [
          {
            'tMs': 4200,
            'latitude': 1.0,
            'longitude': 2.0,
            'accuracy': 80.2,
            'speed': 0,
            'ageMs': 900,
            'isMocked': false,
          },
          {
            'receivedElapsedMillis': 9100,
            'accuracyMeters': 62.3,
            'speedMps': 0.4,
            'ageMillisAtReceipt': 1200,
            'isMocked': true,
            'qualityCode': 'poor_accuracy',
          },
          'not a map',
        ],
      },
    };

void main() {
  group('ErrorLog new fields', () {
    test('are read from the contract shape', () {
      final log = ErrorLog.fromMap('log1', _attemptLog());
      expect(log.appVersion, '1.8.0+17');
      expect(log.visitId, 'visit-1');
      expect(log.attemptNumber, 1);
      expect(log.attemptOutcome, 'timeout');
      expect(log.attemptDurationMs, 25012);
      expect(log.geoRuleVersion, 2);
      expect(log.deviceModel, 'KG5');
      expect(log.device!.modelLabel, 'Tecno KG5');
      expect(log.device!.os, 'Android 11 (API 30)');
      expect(log.attemptLabel, 'Essai 1 · GPS trop lent · 25 s');
      expect(log.appAndDeviceLabel, 'v1.8.0+17 · Tecno KG5');
      expect(geoSettingsLabel(log.geoSettings),
          '25 s × 2 essais · photo de secours : oui · précision normale');
    });

    test('old logs without the fields still parse', () {
      final log = ErrorLog.fromMap('old', {
        'type': 'pointing_site',
        'errorType': 'distanceError',
        'timestamp': Timestamp.fromDate(DateTime(2026, 11, 12)),
        'deviceInfo': 'broken',
        'geoDiagnostic': 42,
      });
      expect(log.hasAttemptInfo, isFalse);
      expect(log.attemptLabel, isNull);
      expect(log.device, isNull);
      expect(log.geoDiagnosticSummary, isNull);
      expect(ErrorLogPhoneAttemptCard.hasContent(log), isFalse);
    });

    test('resolution keeps the new fields', () {
      final log = ErrorLog.fromMap('log1', _attemptLog())
          .copyWithResolved(resolvedBy: 'X', resolvedAt: DateTime(2026));
      expect(log.isResolved, isTrue);
      expect(log.visitId, 'visit-1');
      expect(log.geoDiagnostic, isNotNull);
    });
  });

  test('geoDiagnostic summary reads both reading shapes', () {
    final summary =
        GeoDiagnosticSummary.fromMap(_attemptLog()['geoDiagnostic'])!;
    final facts = Map.fromEntries(summary.facts);
    expect(facts['Résultat'], 'timeout');
    expect(facts['Durée'], '25 s / limite 25 s');
    expect(facts['Distance au site'], '140 m / rayon 500 m');
    expect(facts['Précision'], contains('dernière 62 m'));
    expect(summary.readings, hasLength(2));
    expect(summary.readings[0].summary, contains('± 80 m'));
    expect(summary.readings[1].accuracy, 62.3);
    expect(summary.readings[1].summary, contains('SIMULÉE'));
    expect(summary.shortLabel, contains('2 lecture(s)'));
  });

  test('new error types have French badges', () {
    expect(ErrorTypeConfig.getLabel('geoAttemptCancelled'), 'Essai GPS annulé');
    expect(ErrorTypeConfig.getLabel('sitePositionReported'),
        'Position de site signalée');
    expect(ErrorTypeConfig.allErrorTypes,
        containsAll(['geoAttemptCancelled', 'sitePositionReported']));
    expect(AttemptOutcome.label('out_of_zone'), 'Hors du site');
    expect(AttemptOutcome.label('new_outcome'), 'new_outcome');
  });

  test('filters and filter choices', () {
    const filters = ErrorLogFilters();
    final active = filters.copyWith(
        attemptOutcome: 'timeout', appVersion: '1.8.0+17', deviceModel: 'KG5');
    expect(active.hasActiveFilters, isTrue);
    final cleared = active.copyWith(
        clearAttemptOutcome: true,
        clearAppVersion: true,
        clearDeviceModel: true);
    expect(cleared.hasActiveFilters, isFalse);

    final counts = ErrorLogStats.countRecent([
      _attemptLog(),
      _attemptLog(outcome: 'no_signal'),
      {'errorType': 'distanceError', 'appVersion': '1.7.0+16'},
    ]);
    expect(counts['attemptOutcome'], {'timeout': 1, 'no_signal': 1});
    expect(counts['appVersion'], {'1.8.0+17': 2, '1.7.0+16': 1});
    expect(counts['deviceModel'], {'KG5': 2});
    expect(counts['errorType'], {'gpsTimeoutError': 2, 'distanceError': 1});
  });

  test('visit timeline merges and sorts every source', () {
    final first = ErrorLog.fromMap(
        'log1', _attemptLog(at: DateTime(2026, 11, 26, 8, 0, 30)));
    final second = ErrorLog.fromMap(
        'log2', _attemptLog(attempt: 2, at: DateTime(2026, 11, 26, 8, 1, 0)));
    final events = [
      MobileEvent.fromMap('e2', {
        'event': 'photo_fallback_offered',
        'clientTimestamp': '2026-11-26T08:01:01.000',
      }),
      MobileEvent.fromMap('e1', {
        'event': 'pointing_started',
        'clientTimestamp': '2026-11-26T08:00:00.000',
        'data': {
          'siteCode': 'A1',
          'nested': {'x': 1}
        },
      }),
      MobileEvent.fromMap('e3', {'event': 'brand_new_event'}),
    ];
    final entries = VisitTimeline.build(
      errorLogs: [second, first],
      events: events,
      pointings: [
        MapEntry('p1', {
          'datetimestamp': Timestamp.fromDate(DateTime(2026, 11, 26, 8, 1, 20)),
          'pointingMethod': 'photo_fallback',
          'geoAttempts': {'fallbackReason': 'timeout'},
          'distance': 40,
        }),
      ],
      currentErrorLogId: 'log2',
    );
    expect(entries.map((e) => e.sourceId).toList(),
        ['e1', 'log1', 'log2', 'e2', 'p1', 'e3']);
    expect(entries.first.title, 'Pointage commencé');
    expect(entries.first.detail, 'siteCode: A1');
    expect(entries[2].isCurrent, isTrue);
    expect(entries[4].title, 'Pointage enregistré (Photo (GPS indisponible))');
    expect(entries.last.title, 'brand_new_event');
  });

  testWidgets('timeline card shows entries and partial load warnings',
      (tester) async {
    final log = ErrorLog.fromMap('log1', _attemptLog());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: VisitTimelineCard(
            visitId: 'visit-1',
            currentLogId: 'log1',
            loader: () async => VisitTimelineResult(
              entries: VisitTimeline.build(
                  errorLogs: [log], currentErrorLogId: 'log1'),
              warnings: const ['mobile_events : permission-denied'],
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Parcours de la visite'), findsOneWidget);
    expect(find.textContaining('(cette erreur)'), findsOneWidget);
    expect(find.textContaining('permission-denied'), findsOneWidget);
  });
}
