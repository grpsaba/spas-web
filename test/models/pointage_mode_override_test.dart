import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/models/pointage_mode_override.dart';

Map<String, dynamic> _supervisorJson([Map<String, dynamic> extra = const {}]) =>
    {
      'UID': 'sup1',
      'code': 'S1',
      'firstName': 'A',
      'lastName': 'B',
      'phone': '1',
      'email': 'a@b.c',
      'token': '',
      'tracking': true,
      'tenantId': 'ml',
      ...extra,
    };

Map<String, dynamic> _zoneMemberJson([Map<String, dynamic> extra = const {}]) =>
    {
      'UID': 'zm1',
      'code': 'Z1',
      'firstName': 'C',
      'lastName': 'D',
      'phone': '2',
      'email': 'c@d.e',
      'token': '',
      'tenantId': 'ml',
      ...extra,
    };

void main() {
  test('normalize only accepts explicit modes', () {
    expect(PointageModeOverride.normalize(null), isNull);
    expect(PointageModeOverride.normalize(''), isNull);
    expect(PointageModeOverride.normalize('country'), isNull);
    expect(PointageModeOverride.normalize('n_importe'), isNull);
    expect(PointageModeOverride.normalize('photo'), 'photo');
    expect(PointageModeOverride.normalize(' GEO '), 'geo');
    expect(PointageModeOverride.normalize('Géolocalisation'), 'geo');
  });

  test('read mapping on supervisors and zone chiefs', () {
    expect(Supervisor.fromJson(_supervisorJson()).pointageModeOverride, isNull);
    expect(
        Supervisor.fromJson(_supervisorJson({'pointageModeOverride': null}))
            .pointageModeOverride,
        isNull);
    expect(
        Supervisor.fromJson(_supervisorJson({'pointageModeOverride': 'geo'}))
            .pointageModeOverride,
        'geo');
    expect(
        ZoneMember.fromJson(_zoneMemberJson({'pointageModeOverride': 'photo'}))
            .pointageModeOverride,
        'photo');
  });

  test('toJson never carries the override (embedded copies stay clean)', () {
    final supervisor =
        Supervisor.fromJson(_supervisorJson({'pointageModeOverride': 'geo'}));
    expect(supervisor.toJson(), isNot(contains('pointageModeOverride')));
    final member =
        ZoneMember.fromJson(_zoneMemberJson({'pointageModeOverride': 'geo'}));
    expect(member.toJson(), isNot(contains('pointageModeOverride')));
  });

  test('write mapping: default deletes the field on update', () {
    expect(PointageModeOverride.updateFields('photo'),
        {'pointageModeOverride': 'photo'});
    expect(PointageModeOverride.updateFields('geo'),
        {'pointageModeOverride': 'geo'});
    expect(PointageModeOverride.updateFields(null)['pointageModeOverride'],
        isA<FieldValue>());
    expect(PointageModeOverride.createFields(null), isEmpty);
    expect(PointageModeOverride.createFields('geo'),
        {'pointageModeOverride': 'geo'});
  });

  test('effective mode and labels', () {
    expect(PointageModeOverride.effectiveMode(null, 'geo'), 'geo');
    expect(PointageModeOverride.effectiveMode(null, 'photo'), 'photo');
    expect(PointageModeOverride.effectiveMode('photo', 'geo'), 'photo');
    expect(PointageModeOverride.optionLabel(null, countryMode: 'geo'),
        'Selon le pays (Géolocalisation)');
    expect(PointageModeOverride.optionLabel(null, countryMode: 'photo'),
        'Selon le pays (Photo)');
    expect(PointageModeOverride.optionLabel('photo'), 'Toujours Photo');
    expect(PointageModeOverride.optionLabel('geo'), 'Toujours Géolocalisation');
    expect(PointageModeOverride.badgeLabel(null), isNull);
    expect(PointageModeOverride.badgeLabel('geo'), 'Toujours Géo');
  });
}
