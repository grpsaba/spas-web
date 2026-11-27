import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spas_web/geo_tracking/models/geo_stats.dart';
import 'package:spas_web/geo_tracking/models/mobile_event.dart';
import 'package:spas_web/geo_tracking/models/pointing_duration.dart';
import 'package:spas_web/geo_tracking/services/geo_tracking_service.dart';

// Synthetic data only: no real person, site or phone.

/// A sitePointings / zonePointings document shaped like the contract.
Map<String, dynamic> durationPointing({
  required String personUid,
  required String personName,
  required String siteUid,
  required DateTime at,
  bool zone = false,
  String? method = 'geo',
  Map<String, dynamic>? duration,
  String? visitId,
  String siteCode = 'S-001',
  String siteName = 'Site démo',
}) {
  final parts = personName.split(' ');
  return {
    zone ? 'zoneMember' : 'supervisor': {
      'UID': personUid,
      'firstName': parts.first,
      'lastName': parts.skip(1).join(' '),
    },
    'site': {'UID': siteUid, 'codeSite': siteCode, 'name': siteName},
    'datetimestamp': Timestamp.fromDate(at),
    if (method != null) 'pointingMethod': method,
    if (duration != null) 'pointingDuration': duration,
    if (visitId != null) 'visitId': visitId,
  };
}

Map<String, dynamic> durationMap(
  int totalMs, {
  int? gpsWaitMs,
  int? firstFixMs,
  int? decisionMs,
  int? photoMs,
  int? saveMs,
  int relaunches = 0,
}) =>
    {
      'version': 1,
      'totalMs': totalMs,
      'gpsWaitMs': gpsWaitMs ?? 0,
      'firstFixMs': firstFixMs,
      'decisionMs': decisionMs,
      'photoMs': photoMs,
      'saveMs': saveMs ?? 1200,
      'relaunches': relaunches,
      'startedAt': '2026-11-26T08:00:00.000Z',
    };

/// `mobile_events` document helper (client time as ISO string).
MobileEvent journalEvent(
  String id,
  String event, {
  required String visitId,
  required DateTime at,
  String userId = 'u1',
  String siteId = 's1',
  Map<String, dynamic> data = const {},
  DateTime? serverAt,
}) =>
    MobileEvent.fromMap(id, {
      'event': event,
      'visitId': visitId,
      'userId': userId,
      'siteId': siteId,
      'clientTimestamp': at.toIso8601String(),
      'timestamp': Timestamp.fromDate(serverAt ?? at),
      'data': data,
    });

/// About 150 pointings over 20–26 Nov 2026 for the widget test and the
/// preview image: 4 supervisors, 2 zone chiefs, 8 sites, every method,
/// a few estimated from the journal and a few without duration.
PointingDurationLoadResult syntheticDurationResult() {
  final random = Random(7);
  const persons = [
    ['sup-1', 'Superviseur Alpha', false],
    ['sup-2', 'Superviseur Bravo', false],
    ['sup-3', 'Superviseur Charlie', false],
    ['sup-4', 'Superviseur Delta', false],
    ['zc-1', 'Chef de zone Echo', true],
    ['zc-2', 'Chef de zone Foxtrot', true],
  ];
  const sites = [
    ['site-1', 'S-101', 'Entrepôt démo Nord'],
    ['site-2', 'S-102', 'Résidence démo Sud'],
    ['site-3', 'S-103', 'Agence démo Centre'],
    ['site-4', 'S-104', 'Usine démo Est'],
    ['site-5', 'S-105', 'Dépôt démo Ouest'],
    ['site-6', 'S-106', 'Clinique démo'],
    ['site-7', 'S-107', 'Banque démo'],
    ['site-8', 'S-108', 'Hôtel démo'],
  ];
  final documents = <DurationSourceDocument>[];
  final estimates = <String, PointingDurationBreakdown>{};
  var n = 0;
  for (var day = 0; day < 7; day++) {
    final date = DateTime(2026, 11, 20 + day);
    // GPS slowly improves over the week.
    final dayFactor = 1.25 - day * 0.07;
    for (var i = 0; i < 22; i++) {
      n++;
      final person = persons[(i + day) % persons.length];
      final site = sites[(i * 3 + day) % sites.length];
      final slowPerson = person[0] == 'sup-3';
      final roll = random.nextDouble();
      final method = roll < 0.55
          ? 'geo'
          : roll < 0.8
              ? 'photo_fallback'
              : 'photo';
      int jitter(int base) => (base * (0.6 + random.nextDouble() * 0.9)).round();
      final firstFix = method == 'photo' ? null : jitter(14000);
      int gpsWait;
      int? decision;
      int? photo;
      if (method == 'geo') {
        gpsWait = (jitter(32000) * dayFactor * (slowPerson ? 1.6 : 1)).round();
      } else if (method == 'photo_fallback') {
        gpsWait = 45000 + jitter(6000);
        decision = jitter(6000);
        photo = jitter(9000);
      } else {
        gpsWait = 0;
        photo = jitter(11000);
      }
      final save = jitter(2500);
      final relaunches = random.nextDouble() < 0.08 ? 1 : 0;
      var total = gpsWait +
          (decision ?? 0) +
          (photo ?? 0) +
          save +
          jitter(9000) +
          relaunches * jitter(60000);
      if (random.nextDouble() < 0.04) total += 240000; // screen left open
      final at = date.add(Duration(hours: 7 + i ~/ 3, minutes: (i * 17) % 60));
      final zone = person[2] as bool;
      final estimated = day < 2 && i % 4 == 0;
      final withoutDuration = day == 0 && i % 7 == 3;
      final visitId = withoutDuration && i.isOdd ? null : 'visit-$n';
      final breakdown = durationMap(total,
          gpsWaitMs: gpsWait,
          firstFixMs: firstFix,
          decisionMs: decision,
          photoMs: photo,
          saveMs: save,
          relaunches: relaunches);
      if (estimated && visitId != null) {
        estimates[visitId] = PointingDurationBreakdown.fromMap(
            {...breakdown, 'firstFixMs': null})!;
      }
      documents.add(DurationSourceDocument(
        'p$n',
        durationPointing(
          personUid: person[0] as String,
          personName: person[1] as String,
          siteUid: site[0],
          siteCode: site[1],
          siteName: site[2],
          at: at,
          zone: zone,
          method: method,
          duration: estimated || withoutDuration ? null : breakdown,
          visitId: visitId,
        ),
        role: zone ? GeoRole.zoneChief : GeoRole.supervisor,
      ));
    }
  }
  return PointingDurationLoadResult.build(documents, estimates: estimates);
}
