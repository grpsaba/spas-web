import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/pointage_control/models/monthly_pointing_sheet.dart';
import 'package:spas_web/pointage_control/services/monthly_pointing_calculator.dart';

void main() {
  const calculator = MonthlyPointingCalculator();

  test('sépare jour et nuit à 18h et déduplique les sites par période', () {
    final supervisor = _supervisor('supervisor-a');
    final site = _site('site-a');
    final sheet = _sheet(supervisorId: supervisor.UID);

    final summary = calculator.calculate(
      sheet: sheet,
      now: DateTime(2026, 1, 2, 12),
      pointings: [
        _pointing(supervisor, site, DateTime(2026, 1, 1, 9)),
        _pointing(supervisor, site, DateTime(2026, 1, 1, 17, 59)),
        _pointing(supervisor, site, DateTime(2026, 1, 1, 18)),
        _pointing(supervisor, site, DateTime(2026, 1, 1, 22)),
      ],
    );

    final firstDay = summary.days.first;
    expect(firstDay.actualDay, 1);
    expect(firstDay.actualNight, 1);
    expect(firstDay.dayPointings, hasLength(2));
    expect(firstDay.nightPointings, hasLength(2));
    expect(firstDay.state, DailyPointingState.compliant);
  });

  test('ignore les pointages hors mois et ceux des autres superviseurs', () {
    final supervisor = _supervisor('supervisor-a');
    final otherSupervisor = _supervisor('supervisor-b');
    final site = _site('site-a');
    final sheet = _sheet(supervisorId: supervisor.UID);

    final summary = calculator.calculate(
      sheet: sheet,
      now: DateTime(2026, 1, 2, 12),
      pointings: [
        _pointing(otherSupervisor, site, DateTime(2026, 1, 1, 9)),
        _pointing(supervisor, site, DateTime(2025, 12, 31, 23)),
        _pointing(supervisor, site, DateTime(2026, 2, 1)),
      ],
    );

    expect(summary.days.first.actualDay, 0);
    expect(summary.days.first.actualNight, 0);
    expect(summary.days.first.state, DailyPointingState.missing);
  });

  test('évalue seulement les journées terminées dans le résumé', () {
    final supervisor = _supervisor('supervisor-a');
    final site = _site('site-a');
    final sheet = _sheet(supervisorId: supervisor.UID);

    final summary = calculator.calculate(
      sheet: sheet,
      now: DateTime(2026, 1, 3, 10),
      pointings: [
        _pointing(supervisor, site, DateTime(2026, 1, 1, 10)),
        _pointing(supervisor, site, DateTime(2026, 1, 1, 19)),
        _pointing(supervisor, site, DateTime(2026, 1, 3, 9)),
      ],
    );

    expect(summary.evaluatedDays, 2);
    expect(summary.compliantDays, 1);
    expect(summary.daysToExplain, 1);
    expect(summary.missingReasons, 1);
    expect(summary.expectedDayToDate, 2);
    expect(summary.expectedNightToDate, 2);
    expect(summary.days[2].state, DailyPointingState.inProgress);
    expect(summary.days[3].state, DailyPointingState.future);
  });
}

MonthlyPointingSheet _sheet({required String supervisorId}) {
  const actor = PointingSheetActor(
    uid: 'manager-a',
    name: 'Responsable Test',
    email: 'responsable@example.com',
  );
  return MonthlyPointingSheet(
    id: 'sheet-a',
    monthKey: '2026-01',
    month: DateTime(2026, 1),
    supervisorId: supervisorId,
    supervisorFirstName: 'Aminata',
    supervisorLastName: 'Diallo',
    supervisorPhone: '',
    expectedDay: 1,
    expectedNight: 1,
    tenantId: 'tenant-a',
    notes: const {},
    createdBy: actor,
    updatedBy: actor,
  );
}

Supervisor _supervisor(String id) {
  return Supervisor(
    UID: id,
    code: id,
    firstName: 'Aminata',
    lastName: 'Diallo',
    phone: '',
    email: '',
    token: '',
    tracking: true,
    latlng: null,
    actif: true,
    department: null,
  );
}

Site _site(String id) {
  return Site(
    UID: id,
    codeSite: id,
    name: 'Site $id',
    adresse: '',
    email: '',
    phone: '',
    latLng: LatLngModel(lat: 0, lng: 0),
    token: '',
    nbAgent: 0,
    supervisor: null,
    supervisor_2: null,
    actif: true,
    zone: null,
    dateContrat: DateTime(2025),
    nbRonde: 1,
  );
}

PointingSite _pointing(
  Supervisor supervisor,
  Site site,
  DateTime date,
) {
  return PointingSite(
    site: site,
    latlng: null,
    date: date,
    distance: 20,
    supervisor: supervisor,
  );
}
