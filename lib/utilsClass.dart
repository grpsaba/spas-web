class UtilsClass {
  List<DateTime> jourDuMois(DateTime date) {
    List<DateTime> dates = [];
    int mois = date.month;
    int day = date.day;
    while (day != 1) {
      date = date.subtract(const Duration(days: 1));
      day = date.day;
    }
    while (mois == date.month) {
      dates.add(date);
      date = date.add(const Duration(days: 1));
    }
    return dates;
  }
}
