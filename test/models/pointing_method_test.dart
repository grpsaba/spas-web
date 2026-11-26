import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/models/pointing_method.dart';

Map<String, dynamic> _site() => {
      'UID': 's1',
      'codeSite': 'GN01',
      'name': 'Site test',
      'adresse': '',
      'email': '',
      'phone': '',
      'token': '',
      'latLng': {'lat': 12.6, 'lng': -8.0},
    };

Map<String, dynamic> _supervisor() => {
      'UID': 'sup1',
      'code': 'S1',
      'firstName': 'A',
      'lastName': 'B',
      'phone': '1',
      'email': 'a@b.c',
      'token': '',
      'tracking': true,
    };

Map<String, dynamic> _sitePointing([Map<String, dynamic> extra = const {}]) => {
      'date': '2026-11-20T08:00:00.000',
      'datetimestamp': '2026-11-20T08:00:00.000',
      'distance': 12.0,
      'latlng': null,
      'site': _site(),
      'supervisor': _supervisor(),
      'tenantId': 'ml',
      ...extra,
    };

void main() {
  group('explicit pointingMethod', () {
    test('geo / photo / photo_fallback labels', () {
      expect(PointingMethodInfo.resolve(pointingMethod: 'geo')!.label, 'Géo');
      expect(
          PointingMethodInfo.resolve(pointingMethod: 'photo')!.label, 'Photo');
      final fallback = PointingMethodInfo.resolve(
        pointingMethod: 'photo_fallback',
        photoUrl: 'https://x/photo.jpg',
        geoAttempts: {
          'count': 2,
          'totalWaitMs': 50200,
          'fallbackReason': 'timeout',
        },
      )!;
      expect(fallback.method, PointingMethod.photoFallback);
      expect(fallback.label, 'Photo (GPS indisponible)');
      expect(fallback.inferred, isFalse);
      expect(fallback.tooltip, contains('GPS trop lent'));
      expect(
          fallback.tooltip, contains('Essais GPS : 2 · attente totale 50 s'));
    });

    test('explicit value wins over the old heuristics', () {
      final info = PointingMethodInfo.resolve(
        pointingMethod: 'geo',
        photoUrl: 'https://x/photo.jpg',
      )!;
      expect(info.method, PointingMethod.geo);
    });

    test('unknown fallback reasons are shown as-is, missing ones explained',
        () {
      expect(GeoFallbackReason.label('weird_reason'), 'weird_reason');
      expect(GeoFallbackReason.label(null), 'Raison non précisée');
      final info = PointingMethodInfo.resolve(
          pointingMethod: 'photo_fallback', geoAttempts: 'not a map')!;
      expect(info.tooltip, contains('Raison non précisée'));
    });
  });

  group('old documents without pointingMethod', () {
    test('geoMetadata without photo is inferred as Géo', () {
      final info = PointingMethodInfo.fromDocument({
        'geoMetadata': {'accuracyMeters': 20},
        'agentPhotoUrl': null
      })!;
      expect(info.method, PointingMethod.geo);
      expect(info.inferred, isTrue);
    });

    test('a photo is inferred as Photo', () {
      final info = PointingMethodInfo.fromDocument(
          {'agentPhotoUrl': 'https://x/p.jpg'})!;
      expect(info.method, PointingMethod.photo);
      expect(info.inferred, isTrue);
    });

    test('nothing to go on shows nothing and never throws', () {
      expect(PointingMethodInfo.fromDocument(null), isNull);
      expect(PointingMethodInfo.fromDocument({}), isNull);
      expect(PointingMethodInfo.fromDocument({'agentPhotoUrl': '  '}), isNull);
      expect(PointingMethodInfo.fromDocument({'pointingMethod': 42}), isNull);
      expect(
          PointingMethodInfo.fromDocument({'geoMetadata': 'broken'}), isNull);
    });
  });

  group('pointing models', () {
    test('PointingSite reads the method and survives the cache round-trip', () {
      final pointing = PointingSite.fromJson(_sitePointing({
        'pointingMethod': 'photo_fallback',
        'agentPhotoUrl': 'https://x/p.jpg',
        'visitId': 'v-1',
        'geoAttempts': {'count': 2, 'fallbackReason': 'no_signal'},
      }));
      expect(pointing.methodInfo!.label, 'Photo (GPS indisponible)');
      expect(pointing.visitId, 'v-1');

      final json = pointing.toJson()
        ..['datetimestamp'] = pointing.date.toIso8601String();
      final restored = PointingSite.fromJson(json);
      expect(restored.methodInfo!.method, PointingMethod.photoFallback);
      expect(restored.methodInfo!.fallbackReason, 'no_signal');
    });

    test('old geo PointingSite stays Géo after the cache round-trip', () {
      final pointing = PointingSite.fromJson(_sitePointing({
        'geoMetadata': {'accuracyMeters': 20}
      }));
      expect(pointing.methodInfo!.label, 'Géo');
      final json = pointing.toJson()
        ..['datetimestamp'] = pointing.date.toIso8601String();
      expect(PointingSite.fromJson(json).methodInfo!.label, 'Géo');
    });

    test('pointings created on the web do not gain new Firestore fields', () {
      final pointing = PointingSite.fromJson(_sitePointing());
      final json = pointing.toJson();
      for (final key in [
        'pointingMethod',
        'geoAttempts',
        'hasGeoMetadata',
        'visitId'
      ]) {
        expect(json, isNot(contains(key)));
      }
      expect(pointing.methodInfo, isNull);
    });
  });
}
