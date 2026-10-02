import '../../model.dart';
import '../models/monthly_pointing_sheet.dart';

enum DailyPointingState {
  future,
  inProgress,
  noTarget,
  compliant,
  partial,
  missing,
}

class DailyPointingResult {
  const DailyPointingResult({
    required this.date,
    required this.expectedDay,
    required this.expectedNight,
    required this.dayPointings,
    required this.nightPointings,
    required this.countedDaySiteIds,
    required this.countedNightSiteIds,
    required this.state,
    this.note,
  });

  final DateTime date;
  final int expectedDay;
  final int expectedNight;
  final List<PointingSite> dayPointings;
  final List<PointingSite> nightPointings;
  final Set<String> countedDaySiteIds;
  final Set<String> countedNightSiteIds;
  final DailyPointingState state;
  final PointingDayNote? note;

  int get actualDay => countedDaySiteIds.length;
  int get actualNight => countedNightSiteIds.length;
  int get dayDeficit => _positiveDifference(expectedDay, actualDay);
  int get nightDeficit => _positiveDifference(expectedNight, actualNight);
  int get totalDeficit => dayDeficit + nightDeficit;
  bool get needsReason =>
      state == DailyPointingState.partial ||
      state == DailyPointingState.missing;
  bool get hasReason => note != null && note!.displayText.isNotEmpty;

  static int _positiveDifference(int expected, int actual) {
    final difference = expected - actual;
    return difference > 0 ? difference : 0;
  }
}

class MonthlyPointingSummary {
  const MonthlyPointingSummary({
    required this.days,
    required this.actualDayTotal,
    required this.actualNightTotal,
    required this.expectedDayToDate,
    required this.expectedNightToDate,
    required this.evaluatedDays,
    required this.compliantDays,
    required this.daysToExplain,
    required this.missingReasons,
  });

  final List<DailyPointingResult> days;
  final int actualDayTotal;
  final int actualNightTotal;
  final int expectedDayToDate;
  final int expectedNightToDate;
  final int evaluatedDays;
  final int compliantDays;
  final int daysToExplain;
  final int missingReasons;

  double get complianceRate {
    if (evaluatedDays == 0) return 0;
    return compliantDays * 100 / evaluatedDays;
  }
}

class MonthlyPointingCalculator {
  const MonthlyPointingCalculator();

  static const int nightStartHour = 18;

  MonthlyPointingSummary calculate({
    required MonthlyPointingSheet sheet,
    required List<PointingSite> pointings,
    DateTime? now,
  }) {
    final referenceNow = now ?? DateTime.now();
    final monthStart = DateTime(sheet.month.year, sheet.month.month);
    final monthEnd = DateTime(sheet.month.year, sheet.month.month + 1);
    final numberOfDays = monthEnd.subtract(const Duration(days: 1)).day;

    final matchingPointings = pointings.where((pointing) {
      final date = pointing.date;
      return date.isBefore(monthEnd) &&
          !date.isBefore(monthStart) &&
          pointing.supervisor?.UID == sheet.supervisorId;
    }).toList();

    final days = <DailyPointingResult>[];
    var actualDayTotal = 0;
    var actualNightTotal = 0;
    var expectedDayToDate = 0;
    var expectedNightToDate = 0;
    var evaluatedDays = 0;
    var compliantDays = 0;
    var daysToExplain = 0;
    var missingReasons = 0;

    for (var dayNumber = 1; dayNumber <= numberOfDays; dayNumber++) {
      final date = DateTime(sheet.month.year, sheet.month.month, dayNumber);
      final nextDate = date.add(const Duration(days: 1));
      final dayPointings = matchingPointings
          .where((pointing) =>
              !pointing.date.isBefore(date) && pointing.date.isBefore(nextDate))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final daytime = dayPointings
          .where((pointing) => pointing.date.hour < nightStartHour)
          .toList();
      final nighttime = dayPointings
          .where((pointing) => pointing.date.hour >= nightStartHour)
          .toList();
      final daytimeSites = daytime.map(_siteIdentity).toSet();
      final nighttimeSites = nighttime.map(_siteIdentity).toSet();

      final state = _stateFor(
        date: date,
        now: referenceNow,
        expectedDay: sheet.expectedDay,
        expectedNight: sheet.expectedNight,
        actualDay: daytimeSites.length,
        actualNight: nighttimeSites.length,
      );
      final note = sheet.notes[dayKey(date)];

      final result = DailyPointingResult(
        date: date,
        expectedDay: sheet.expectedDay,
        expectedNight: sheet.expectedNight,
        dayPointings: daytime,
        nightPointings: nighttime,
        countedDaySiteIds: daytimeSites,
        countedNightSiteIds: nighttimeSites,
        state: state,
        note: note,
      );
      days.add(result);

      actualDayTotal += result.actualDay;
      actualNightTotal += result.actualNight;

      if (_isEvaluated(state)) {
        evaluatedDays++;
        expectedDayToDate += sheet.expectedDay;
        expectedNightToDate += sheet.expectedNight;
        if (state == DailyPointingState.compliant) compliantDays++;
        if (result.needsReason) {
          daysToExplain++;
          if (!result.hasReason) missingReasons++;
        }
      }
    }

    return MonthlyPointingSummary(
      days: days,
      actualDayTotal: actualDayTotal,
      actualNightTotal: actualNightTotal,
      expectedDayToDate: expectedDayToDate,
      expectedNightToDate: expectedNightToDate,
      evaluatedDays: evaluatedDays,
      compliantDays: compliantDays,
      daysToExplain: daysToExplain,
      missingReasons: missingReasons,
    );
  }

  DailyPointingState _stateFor({
    required DateTime date,
    required DateTime now,
    required int expectedDay,
    required int expectedNight,
    required int actualDay,
    required int actualNight,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    if (date.isAfter(today)) return DailyPointingState.future;
    if (date.isAtSameMomentAs(today)) return DailyPointingState.inProgress;
    if (expectedDay == 0 && expectedNight == 0) {
      return DailyPointingState.noTarget;
    }

    final dayReached = actualDay >= expectedDay;
    final nightReached = actualNight >= expectedNight;
    if (dayReached && nightReached) return DailyPointingState.compliant;
    if (actualDay == 0 && actualNight == 0) return DailyPointingState.missing;
    return DailyPointingState.partial;
  }

  bool _isEvaluated(DailyPointingState state) {
    return state == DailyPointingState.compliant ||
        state == DailyPointingState.partial ||
        state == DailyPointingState.missing;
  }

  String _siteIdentity(PointingSite pointing) {
    final uid = pointing.site.UID.trim();
    if (uid.isNotEmpty) return 'uid:$uid';

    final code = pointing.site.codeSite.trim().toLowerCase();
    if (code.isNotEmpty) return 'code:$code';

    return 'name:${pointing.site.name.trim().toLowerCase()}';
  }

  static String dayKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
