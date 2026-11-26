import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/services/tenant.dart';

void main() {
  test('legacy inherited chief mode is preserved when supervisors change', () {
    expect(
        TenantService.pointageModeChanges(
          current: {'pointageMode': 'photo'},
          pointageMode: 'geo',
        ),
        {'pointageMode': 'geo', 'zoneChiefPointageMode': 'photo'});
    expect(
        TenantService.pointageModeChanges(
          current: {'pointageMode': 'photo', 'zonePointageMode': 'geo'},
          pointageMode: 'geo',
        ),
        {'pointageMode': 'geo', 'zoneChiefPointageMode': 'geo'});
  });
  test('changing one role preserves concurrent changes to the other role', () {
    final supervisor = TenantService.pointageModeChanges(pointageMode: 'geo');
    final chief =
        TenantService.pointageModeChanges(zoneChiefPointageMode: 'photo');
    expect(supervisor, {'pointageMode': 'geo'});
    expect(chief, {'zoneChiefPointageMode': 'photo'});
    final document = {'pointageMode': 'photo', 'zoneChiefPointageMode': 'geo'};
    document.addAll(supervisor.cast<String, String>());
    document.addAll(chief.cast<String, String>());
    expect(document, {'pointageMode': 'geo', 'zoneChiefPointageMode': 'photo'});
    expect(TenantService.pointageModeChanges(), isEmpty);
  });
}
