class UtilsClass {
  List<DateTime> jourDuMois(DateTime date) {
    final List<DateTime> dates = [];
    final start = DateTime(date.year, date.month, 1);
    DateTime cur = start;
    while (cur.month == start.month) {
      dates.add(cur);
      cur = cur.add(const Duration(days: 1));
    }
    return dates;
  }
}
