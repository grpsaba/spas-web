import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/error_logs/models/error_log_model.dart';
import 'package:spas_web/geo_tracking/geo_tracking_page.dart';
import 'package:spas_web/geo_tracking/models/geo_stats.dart';
import 'package:spas_web/geo_tracking/models/mobile_event.dart';
import 'package:spas_web/geo_tracking/services/geo_tracking_service.dart';
import 'package:spas_web/models/pointing_method.dart';

// Synthetic documents only.
Map<String, dynamic> _pointing(
  String uid, {
  String? method,
  String? photoUrl,
  bool geoMetadata = false,
  String? model,
  String? version,
  bool zone = false,
}) =>
    {
      zone ? 'zoneMember' : 'supervisor': {
        'UID': uid,
        'firstName': 'P',
        'lastName': uid,
      },
      if (method != null) 'pointingMethod': method,
      if (photoUrl != null) 'agentPhotoUrl': photoUrl,
      if (geoMetadata) 'geoMetadata': {'accuracyMeters': 10},
      if (model != null) 'deviceInfo': {'brand': 'tecno', 'model': model},
      if (version != null) 'appVersion': version,
    };

ErrorLog _attempt(String uid, String outcome, {String? model}) =>
    ErrorLog.fromMap('l-$uid-$outcome', {
      'type': 'pointing_site',
      'errorType': 'gpsTimeoutError',
      'timestamp': Timestamp.fromDate(DateTime(2026, 11, 26)),
      'supervisor': {'UID': uid, 'firstName': 'P', 'lastName': uid},
      'attemptOutcome': outcome,
      'appVersion': '1.8.0',
      if (model != null) 'deviceInfo': {'brand': 'tecno', 'model': model},
    });

GeoStatsReport _report() {
  final pointings = [
    _pointing('a', method: 'geo', model: 'KG5', version: '1.8.0'),
    _pointing('a', method: 'geo', model: 'KG5', version: '1.8.0'),
    _pointing('a', method: 'photo_fallback', model: 'KG5', version: '1.8.0'),
    _pointing('a', method: 'photo', model: 'KG5', version: '1.8.0'),
    _pointing('b', photoUrl: 'https://x/p.jpg'), // old photo doc
    _pointing('b', geoMetadata: true), // old geo doc
    _pointing('b'), // nothing to infer
    _pointing('c', method: 'photo_fallback', zone: true, model: 'A03'),
  ].map((d) => GeoPointingRecord.fromDocument(d,
      role: d.containsKey('zoneMember')
          ? GeoRole.zoneChief
          : GeoRole.supervisor));
  final attempts = [
    _attempt('a', 'timeout', model: 'KG5'),
    _attempt('a', 'timeout', model: 'KG5'),
    _attempt('a', 'no_signal', model: 'KG5'),
  ].map(GeoAttemptRecord.fromErrorLog).whereType<GeoAttemptRecord>();
  return GeoStatsReport.aggregate(pointings: pointings, attempts: attempts);
}

void main() {
  test('records come from pointing documents and attempt logs', () {
    final record = GeoPointingRecord.fromDocument(
        _pointing('z', method: 'geo', zone: true, model: 'KG5'),
        role: GeoRole.zoneChief);
    expect(record.personKey, 'z');
    expect(record.personName, 'P z');
    expect(record.method, PointingMethod.geo);
    expect(record.deviceModel, 'Tecno KG5');
    expect(
        GeoAttemptRecord.fromErrorLog(ErrorLog.fromMap('old', {
          'type': 'pointing_site',
          'errorType': 'distanceError',
          'timestamp': Timestamp.fromDate(DateTime(2026)),
        })),
        isNull);
  });

  test('per person counts and fallback rate', () {
    final report = _report();
    final a = report.byPerson.firstWhere((r) => r.key == 'a');
    expect([a.geo, a.photo, a.photoFallback, a.unknown], [2, 1, 1, 0]);
    // 1 fallback out of 3 geolocation-mode visits; photo mode excluded.
    expect(a.fallbackRate, closeTo(1 / 3, 1e-9));
    expect(a.failedAttempts, 3);
    expect(a.failedSummary, 'GPS trop lent 2 · Aucun signal GPS 1');

    final b = report.byPerson.firstWhere((r) => r.key == 'b');
    expect([b.geo, b.photo, b.photoFallback, b.unknown], [1, 1, 0, 1]);
    expect(b.fallbackRate, 0);

    final c = report.byPerson.firstWhere((r) => r.key == 'c');
    expect(c.role, GeoRole.zoneChief);
    expect(c.fallbackRate, 1);
  });

  test('no geolocation-mode visit gives no rate', () {
    final row = GeoStatsRow(key: 'x', label: 'x')
      ..addPointing(PointingMethod.photo);
    expect(row.fallbackRate, isNull);
    expect(formatRate(row.fallbackRate), '—');
    expect(formatRate(1 / 3), '33 %');
    expect(formatRate(0.05), '5.0 %');
    expect(formatRate(0), '0 %');
  });

  test('grouped by phone model and app version, totals', () {
    final report = _report();
    final kg5 = report.byDeviceModel.firstWhere((r) => r.label == 'Tecno KG5');
    expect(kg5.totalPointings, 4);
    expect(kg5.failedAttempts, 3);
    expect(report.byDeviceModel.map((r) => r.label),
        containsAll(['Tecno A03', unknownDeviceLabel]));
    final unknownVersion =
        report.byAppVersion.firstWhere((r) => r.label == unknownVersionLabel);
    expect(unknownVersion.totalPointings, 4);
    expect(report.totals.totalPointings, 8);
    expect(report.totals.photoFallback, 2);
    expect(report.totals.fallbackRate, closeTo(2 / 5, 1e-9));
    // Most problematic first.
    expect(report.byPerson.first.key, 'a');
  });

  test('mobile event parsing and unknown names', () {
    final event = MobileEvent.fromMap('e', {
      'event': 'geo_retry_tapped',
      'timestamp': Timestamp.fromDate(DateTime(2026, 11, 26, 9)),
      'clientTimestamp': '2026-11-26T08:59:58.000',
      'role': 'zone_chief',
      'userName': 'P z',
      'deviceInfo': {'brand': 'itel', 'model': 'A70', 'os': 'Android 13'},
      'isOnline': false,
      'data': {'attempt': 2},
    });
    expect(event.label, 'Nouvel essai GPS demandé');
    expect(event.time, DateTime(2026, 11, 26, 8, 59, 58));
    expect(event.roleLabel, 'Chef de zone');
    expect(event.device!.fullLabel, 'Itel A70 · Android 13');
    expect(event.dataSummary, 'attempt: 2');
    expect(MobileEvent.fromMap('x', {'event': 'future_event'}).label,
        'future_event');
    expect(defaultGeoRange(DateTime(2026, 11, 26, 15)).start,
        DateTime(2026, 11, 20));
  });

  testWidgets('stats tab renders the report from an injected loader',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    DateTime? askedStart;
    DateTime? askedEnd;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GeoStatsTab(loader: (start, end) async {
          askedStart = start;
          askedEnd = end;
          return GeoStatsLoadResult(
            report: _report(),
            truncatedCollections: const ['error_logs'],
            warnings: const [],
          );
        }),
      ),
    ));
    await tester.pumpAndSettle();
    expect(askedEnd!.difference(askedStart!).inDays, 7);
    expect(find.text('Par personne'), findsOneWidget);
    expect(find.text('Par modèle de téléphone'), findsOneWidget);
    expect(find.text('Par version de l\'app'), findsOneWidget);
    expect(find.text('Taux de secours photo'), findsOneWidget);
    expect(find.text('40 %'), findsOneWidget);
    expect(find.textContaining('Période trop chargée'), findsOneWidget);
  });
}
