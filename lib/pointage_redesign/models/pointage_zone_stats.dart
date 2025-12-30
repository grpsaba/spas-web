/// Statistics model for zone pointages
/// 
/// Contains aggregated data for dashboard display
/// Requirements: 1.3, 1.4
class PointageZoneStats {
  final int totalPointages;
  final int uniqueZones;
  final int uniqueZoneMembers;
  final double averagePointagesPerDay;
  final Map<String, int> pointagesByZoneMember;
  final Map<String, int> pointagesByZone;

  PointageZoneStats({
    required this.totalPointages,
    required this.uniqueZones,
    required this.uniqueZoneMembers,
    required this.averagePointagesPerDay,
    required this.pointagesByZoneMember,
    required this.pointagesByZone,
  });

  /// Create empty stats
  factory PointageZoneStats.empty() {
    return PointageZoneStats(
      totalPointages: 0,
      uniqueZones: 0,
      uniqueZoneMembers: 0,
      averagePointagesPerDay: 0.0,
      pointagesByZoneMember: {},
      pointagesByZone: {},
    );
  }

  /// Check if stats are empty
  bool get isEmpty => totalPointages == 0;

  /// Get top zone members by pointage count
  List<MapEntry<String, int>> getTopZoneMembers({int limit = 5}) {
    final entries = pointagesByZoneMember.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Get top zones by pointage count
  List<MapEntry<String, int>> getTopZones({int limit = 5}) {
    final entries = pointagesByZone.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  @override
  String toString() {
    return 'PointageZoneStats(total: $totalPointages, zones: $uniqueZones, '
        'zoneMembers: $uniqueZoneMembers, avgPerDay: ${averagePointagesPerDay.toStringAsFixed(1)})';
  }
}
