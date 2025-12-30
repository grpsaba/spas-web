/// Statistics model for pointage dashboard
class PointageStats {
  final int totalPointages;
  final int uniqueSites;
  final int uniqueSupervisors;
  final double averagePointagesPerDay;
  final Map<String, int> pointagesBySupervisor;
  final Map<String, int> pointagesBySite;

  PointageStats({
    required this.totalPointages,
    required this.uniqueSites,
    required this.uniqueSupervisors,
    required this.averagePointagesPerDay,
    required this.pointagesBySupervisor,
    required this.pointagesBySite,
  });

  /// Create empty statistics
  factory PointageStats.empty() {
    return PointageStats(
      totalPointages: 0,
      uniqueSites: 0,
      uniqueSupervisors: 0,
      averagePointagesPerDay: 0.0,
      pointagesBySupervisor: {},
      pointagesBySite: {},
    );
  }

  /// Get top N supervisors by pointage count
  List<MapEntry<String, int>> getTopSupervisors(int n) {
    final sorted = pointagesBySupervisor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }

  /// Get top N sites by pointage count
  List<MapEntry<String, int>> getTopSites(int n) {
    final sorted = pointagesBySite.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }

  /// Get supervisor with most pointages
  MapEntry<String, int>? get topSupervisor {
    if (pointagesBySupervisor.isEmpty) return null;
    return pointagesBySupervisor.entries
        .reduce((a, b) => a.value > b.value ? a : b);
  }

  /// Get site with most pointages
  MapEntry<String, int>? get topSite {
    if (pointagesBySite.isEmpty) return null;
    return pointagesBySite.entries
        .reduce((a, b) => a.value > b.value ? a : b);
  }

  /// Calculate average pointages per supervisor
  double get averagePointagesPerSupervisor {
    if (uniqueSupervisors == 0) return 0.0;
    return totalPointages / uniqueSupervisors;
  }

  /// Calculate average pointages per site
  double get averagePointagesPerSite {
    if (uniqueSites == 0) return 0.0;
    return totalPointages / uniqueSites;
  }

  /// Get pointage count for a specific supervisor
  int getPointagesForSupervisor(String supervisorId) {
    return pointagesBySupervisor[supervisorId] ?? 0;
  }

  /// Get pointage count for a specific site
  int getPointagesForSite(String siteId) {
    return pointagesBySite[siteId] ?? 0;
  }

  /// Calculate performance percentage for a supervisor
  /// (actual pointages / expected pointages * 100)
  double calculateSupervisorPerformance(
      String supervisorId, int expectedPointages) {
    if (expectedPointages == 0) return 0.0;
    final actual = getPointagesForSupervisor(supervisorId);
    return (actual / expectedPointages) * 100;
  }

  /// Merge with another stats object (useful for combining periods)
  PointageStats merge(PointageStats other) {
    final mergedBySupervisor = Map<String, int>.from(pointagesBySupervisor);
    other.pointagesBySupervisor.forEach((key, value) {
      mergedBySupervisor[key] = (mergedBySupervisor[key] ?? 0) + value;
    });

    final mergedBySite = Map<String, int>.from(pointagesBySite);
    other.pointagesBySite.forEach((key, value) {
      mergedBySite[key] = (mergedBySite[key] ?? 0) + value;
    });

    return PointageStats(
      totalPointages: totalPointages + other.totalPointages,
      uniqueSites: mergedBySite.keys.length,
      uniqueSupervisors: mergedBySupervisor.keys.length,
      averagePointagesPerDay:
          (averagePointagesPerDay + other.averagePointagesPerDay) / 2,
      pointagesBySupervisor: mergedBySupervisor,
      pointagesBySite: mergedBySite,
    );
  }

  /// Create a copy with updated values
  PointageStats copyWith({
    int? totalPointages,
    int? uniqueSites,
    int? uniqueSupervisors,
    double? averagePointagesPerDay,
    Map<String, int>? pointagesBySupervisor,
    Map<String, int>? pointagesBySite,
  }) {
    return PointageStats(
      totalPointages: totalPointages ?? this.totalPointages,
      uniqueSites: uniqueSites ?? this.uniqueSites,
      uniqueSupervisors: uniqueSupervisors ?? this.uniqueSupervisors,
      averagePointagesPerDay:
          averagePointagesPerDay ?? this.averagePointagesPerDay,
      pointagesBySupervisor:
          pointagesBySupervisor ?? this.pointagesBySupervisor,
      pointagesBySite: pointagesBySite ?? this.pointagesBySite,
    );
  }

  @override
  String toString() {
    return 'PointageStats(totalPointages: $totalPointages, uniqueSites: $uniqueSites, uniqueSupervisors: $uniqueSupervisors, averagePerDay: $averagePointagesPerDay)';
  }
}
