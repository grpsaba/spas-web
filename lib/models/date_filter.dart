enum DateFilter {
  today('Aujourd\'hui'),
  yesterday('Hier'),
  dayBeforeYesterday('Avant-hier'),
  custom('Date personnalisée');

  const DateFilter(this.label);
  final String label;

  DateTime get startDate {
    final now = DateTime.now();
    switch (this) {
      case DateFilter.today:
        return DateTime(now.year, now.month, now.day);
      case DateFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return DateTime(yesterday.year, yesterday.month, yesterday.day);
      case DateFilter.dayBeforeYesterday:
        final dayBefore = now.subtract(const Duration(days: 2));
        return DateTime(dayBefore.year, dayBefore.month, dayBefore.day);
      case DateFilter.custom:
        return DateTime(now.year, now.month, now.day);
    }
  }

  DateTime get endDate {
    switch (this) {
      case DateFilter.today:
      case DateFilter.yesterday:
      case DateFilter.dayBeforeYesterday:
        return startDate.add(const Duration(days: 1));
      case DateFilter.custom:
        return startDate.add(const Duration(days: 1));
    }
  }
}