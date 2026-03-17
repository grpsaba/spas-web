import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/pointage_exception.dart';

/// Service for optimized aggregation queries on pointage data
///
/// Uses Firebase aggregation queries to minimize reads and improve performance
/// Requirements: 1.2, 1.5
class AggregationService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("sitePointings");

  /// Aggregate pointages by supervisor and day
  ///
  /// Returns a map of supervisor UID -> (date -> count)
  /// Optimized to minimize Firebase reads
  /// Requirements: 1.2, 1.5
  Future<Map<String, Map<DateTime, int>>> aggregateBySupervisorAndDay({
    required List<String> supervisorIds,
    required List<DateTime> days,
  }) async {
    try {
      if (supervisorIds.isEmpty || days.isEmpty) {
        return {};
      }

      // Sort days to get date range
      final sortedDays = List<DateTime>.from(days)..sort();
      final startDate = DateTime(
        sortedDays.first.year,
        sortedDays.first.month,
        sortedDays.first.day,
      );
      final endDate = DateTime(
        sortedDays.last.year,
        sortedDays.last.month,
        sortedDays.last.day,
      ).add(const Duration(days: 1));

      // Initialize result map
      final Map<String, Map<DateTime, int>> result = {};
      for (var supervisorId in supervisorIds) {
        result[supervisorId] = {};
        for (var day in days) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          result[supervisorId]![normalizedDay] = 0;
        }
      }

      // Build query for all supervisors and date range
      Query query = _collectionReference
          .where('datetimestamp', isGreaterThanOrEqualTo: startDate)
          .where('datetimestamp', isLessThan: endDate);

      // If we have 10 or fewer supervisors, use whereIn for efficiency
      if (supervisorIds.length <= 10) {
        query = query.where('supervisor.UID', whereIn: supervisorIds);
      }

      // Execute query
      final snapshot = await query.get();

      // Process results and group by supervisor and day
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Extract supervisor UID
          final supervisorData = data['supervisor'] as Map<String, dynamic>?;
          if (supervisorData == null) continue;

          final supervisorUID = supervisorData['UID'] as String?;
          if (supervisorUID == null || !supervisorIds.contains(supervisorUID)) {
            continue;
          }

          // Extract and normalize date
          final timestamp = data['datetimestamp'];
          DateTime? pointageDate;

          if (timestamp is Timestamp) {
            pointageDate = timestamp.toDate();
          } else if (timestamp is DateTime) {
            pointageDate = timestamp;
          } else if (timestamp is String) {
            pointageDate = DateTime.tryParse(timestamp);
          }

          if (pointageDate == null) continue;

          final normalizedDate = DateTime(
            pointageDate.year,
            pointageDate.month,
            pointageDate.day,
          );

          // Increment count if this day is in our requested days
          if (result[supervisorUID]?.containsKey(normalizedDate) ?? false) {
            result[supervisorUID]![normalizedDate] =
                (result[supervisorUID]![normalizedDate] ?? 0) + 1;
          }
        } catch (e) {
          debugPrint(
              'Error processing document in aggregateBySupervisorAndDay: $e');
        }
      }

      return result;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Firebase error in aggregateBySupervisorAndDay: ${e.code}');
      throw PointageException.query(
        message: 'Erreur lors de l\'agrégation par superviseur et jour',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in aggregateBySupervisorAndDay: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Aggregate unique sites by supervisor and day
  ///
  /// Business rule for supervisor/HR reports:
  /// For a given supervisor and day, a site is counted at most once,
  /// even if multiple pointages exist (e.g. morning + evening).
  ///
  /// Returns a map of supervisor UID -> (date -> unique site count)
  Future<Map<String, Map<DateTime, int>>>
      aggregateUniqueSitesBySupervisorAndDay({
    required List<String> supervisorIds,
    required List<DateTime> days,
  }) async {
    try {
      if (supervisorIds.isEmpty || days.isEmpty) {
        return {};
      }

      // Sort days to get date range
      final sortedDays = List<DateTime>.from(days)..sort();
      final startDate = DateTime(
        sortedDays.first.year,
        sortedDays.first.month,
        sortedDays.first.day,
      );
      final endDate = DateTime(
        sortedDays.last.year,
        sortedDays.last.month,
        sortedDays.last.day,
      ).add(const Duration(days: 1));

      // Initialize intermediate structure:
      // supervisor UID -> day -> set of unique site UIDs
      final Map<String, Map<DateTime, Set<String>>>
          uniqueSitesBySupervisorAndDay = {};
      for (var supervisorId in supervisorIds) {
        uniqueSitesBySupervisorAndDay[supervisorId] = {};
        for (var day in days) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          uniqueSitesBySupervisorAndDay[supervisorId]![normalizedDay] =
              <String>{};
        }
      }

      // Build query for all supervisors and date range
      Query query = _collectionReference
          .where('datetimestamp', isGreaterThanOrEqualTo: startDate)
          .where('datetimestamp', isLessThan: endDate);

      // If we have 10 or fewer supervisors, use whereIn for efficiency
      if (supervisorIds.length <= 10) {
        query = query.where('supervisor.UID', whereIn: supervisorIds);
      }

      // Execute query
      final snapshot = await query.get();

      // Process results and deduplicate by site per supervisor/day
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Extract supervisor UID
          final supervisorData = data['supervisor'] as Map<String, dynamic>?;
          if (supervisorData == null) continue;

          final supervisorUID = supervisorData['UID'] as String?;
          if (supervisorUID == null || !supervisorIds.contains(supervisorUID)) {
            continue;
          }

          // Extract site UID
          final siteData = data['site'] as Map<String, dynamic>?;
          if (siteData == null) continue;

          final siteUID = siteData['UID'] as String?;
          if (siteUID == null || siteUID.isEmpty) continue;

          // Extract and normalize date
          final timestamp = data['datetimestamp'];
          DateTime? pointageDate;

          if (timestamp is Timestamp) {
            pointageDate = timestamp.toDate();
          } else if (timestamp is DateTime) {
            pointageDate = timestamp;
          } else if (timestamp is String) {
            pointageDate = DateTime.tryParse(timestamp);
          }

          if (pointageDate == null) continue;

          final normalizedDate = DateTime(
            pointageDate.year,
            pointageDate.month,
            pointageDate.day,
          );

          // Add site UID once for this supervisor/day
          if (uniqueSitesBySupervisorAndDay[supervisorUID]
                  ?.containsKey(normalizedDate) ??
              false) {
            uniqueSitesBySupervisorAndDay[supervisorUID]![normalizedDate]!
                .add(siteUID);
          }
        } catch (e) {
          debugPrint(
              'Error processing document in aggregateUniqueSitesBySupervisorAndDay: $e');
        }
      }

      // Convert sets to counts
      final Map<String, Map<DateTime, int>> result = {};
      for (var supervisorId in supervisorIds) {
        result[supervisorId] = {};
        for (var day in days) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          final uniqueCount = uniqueSitesBySupervisorAndDay[supervisorId]
                      ?[normalizedDay]
                  ?.length ??
              0;
          result[supervisorId]![normalizedDay] = uniqueCount;
        }
      }

      return result;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
          'Firebase error in aggregateUniqueSitesBySupervisorAndDay: ${e.code}');
      throw PointageException.query(
        message:
            'Erreur lors de l\'agrégation dédupliquée par superviseur et jour',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in aggregateUniqueSitesBySupervisorAndDay: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Aggregate pointages by site for a period
  ///
  /// Returns a map of site UID -> total count
  /// Requirements: 1.2, 1.5
  Future<Map<String, int>> aggregateBySiteAndPeriod({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? siteIds,
  }) async {
    try {
      // Build query
      Query query = _collectionReference
          .where('datetimestamp', isGreaterThanOrEqualTo: startDate)
          .where('datetimestamp', isLessThan: endDate);

      // Filter by specific sites if provided
      if (siteIds != null && siteIds.isNotEmpty && siteIds.length <= 10) {
        query = query.where('site.UID', whereIn: siteIds);
      }

      // Execute query
      final snapshot = await query.get();

      // Aggregate by site
      final Map<String, int> result = {};

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Extract site UID
          final siteData = data['site'] as Map<String, dynamic>?;
          if (siteData == null) continue;

          final siteUID = siteData['UID'] as String?;
          if (siteUID == null) continue;

          // Filter by siteIds if provided and query didn't use whereIn
          if (siteIds != null &&
              siteIds.isNotEmpty &&
              siteIds.length > 10 &&
              !siteIds.contains(siteUID)) {
            continue;
          }

          // Increment count
          result[siteUID] = (result[siteUID] ?? 0) + 1;
        } catch (e) {
          debugPrint(
              'Error processing document in aggregateBySiteAndPeriod: $e');
        }
      }

      return result;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Firebase error in aggregateBySiteAndPeriod: ${e.code}');
      throw PointageException.query(
        message: 'Erreur lors de l\'agrégation par site',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in aggregateBySiteAndPeriod: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get global statistics for a period
  ///
  /// Returns comprehensive statistics including totals and breakdowns
  /// Requirements: 1.2, 7.1
  Future<GlobalStats> getGlobalStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Build query
      final query = _collectionReference
          .where('datetimestamp', isGreaterThanOrEqualTo: startDate)
          .where('datetimestamp', isLessThan: endDate);

      // Execute query
      final snapshot = await query.get();

      // Calculate statistics
      final Set<String> uniqueSites = {};
      final Set<String> uniqueSupervisors = {};
      final Map<String, int> pointagesBySupervisor = {};
      final Map<String, int> pointagesBySite = {};
      final Map<DateTime, int> pointagesByDay = {};

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Extract supervisor info
          final supervisorData = data['supervisor'] as Map<String, dynamic>?;
          if (supervisorData != null) {
            final supervisorUID = supervisorData['UID'] as String?;
            if (supervisorUID != null) {
              uniqueSupervisors.add(supervisorUID);
              pointagesBySupervisor[supervisorUID] =
                  (pointagesBySupervisor[supervisorUID] ?? 0) + 1;
            }
          }

          // Extract site info
          final siteData = data['site'] as Map<String, dynamic>?;
          if (siteData != null) {
            final siteUID = siteData['UID'] as String?;
            if (siteUID != null) {
              uniqueSites.add(siteUID);
              pointagesBySite[siteUID] = (pointagesBySite[siteUID] ?? 0) + 1;
            }
          }

          // Extract date for daily breakdown
          final timestamp = data['datetimestamp'];
          DateTime? pointageDate;

          if (timestamp is Timestamp) {
            pointageDate = timestamp.toDate();
          } else if (timestamp is DateTime) {
            pointageDate = timestamp;
          } else if (timestamp is String) {
            pointageDate = DateTime.tryParse(timestamp);
          }

          if (pointageDate != null) {
            final normalizedDate = DateTime(
              pointageDate.year,
              pointageDate.month,
              pointageDate.day,
            );
            pointagesByDay[normalizedDate] =
                (pointagesByDay[normalizedDate] ?? 0) + 1;
          }
        } catch (e) {
          debugPrint('Error processing document in getGlobalStats: $e');
        }
      }

      // Calculate averages
      final totalPointages = snapshot.docs.length;
      final daysDifference = endDate.difference(startDate).inDays;
      final averagePerDay = daysDifference > 0
          ? totalPointages / daysDifference
          : totalPointages.toDouble();

      final averagePerSupervisor = uniqueSupervisors.isNotEmpty
          ? totalPointages / uniqueSupervisors.length
          : 0.0;

      final averagePerSite =
          uniqueSites.isNotEmpty ? totalPointages / uniqueSites.length : 0.0;

      return GlobalStats(
        totalPointages: totalPointages,
        uniqueSites: uniqueSites.length,
        uniqueSupervisors: uniqueSupervisors.length,
        averagePointagesPerDay: averagePerDay,
        averagePointagesPerSupervisor: averagePerSupervisor,
        averagePointagesPerSite: averagePerSite,
        pointagesBySupervisor: pointagesBySupervisor,
        pointagesBySite: pointagesBySite,
        pointagesByDay: pointagesByDay,
        startDate: startDate,
        endDate: endDate,
      );
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Firebase error in getGlobalStats: ${e.code}');
      throw PointageException.query(
        message: 'Erreur lors du calcul des statistiques globales',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in getGlobalStats: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Batch count pointages for multiple supervisors on a single date
  ///
  /// More efficient than calling countForSupervisorOnDate multiple times
  Future<Map<String, int>> batchCountBySupervisorOnDate({
    required List<String> supervisorIds,
    required DateTime date,
  }) async {
    try {
      if (supervisorIds.isEmpty) return {};

      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));

      // Build query
      Query query = _collectionReference
          .where('datetimestamp', isGreaterThanOrEqualTo: start)
          .where('datetimestamp', isLessThan: end);

      // Use whereIn if we have 10 or fewer supervisors
      if (supervisorIds.length <= 10) {
        query = query.where('supervisor.UID', whereIn: supervisorIds);
      }

      // Execute query
      final snapshot = await query.get();

      // Count by supervisor
      final Map<String, int> counts = {};
      for (var supervisorId in supervisorIds) {
        counts[supervisorId] = 0;
      }

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final supervisorData = data['supervisor'] as Map<String, dynamic>?;
          if (supervisorData != null) {
            final supervisorUID = supervisorData['UID'] as String?;
            if (supervisorUID != null &&
                supervisorIds.contains(supervisorUID)) {
              counts[supervisorUID] = (counts[supervisorUID] ?? 0) + 1;
            }
          }
        } catch (e) {
          debugPrint(
              'Error processing document in batchCountBySupervisorOnDate: $e');
        }
      }

      return counts;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Firebase error in batchCountBySupervisorOnDate: ${e.code}');
      throw PointageException.query(
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in batchCountBySupervisorOnDate: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Aggregate pointages by zone member and day
  ///
  /// Returns a map of zone member UID -> (date -> count)
  /// Optimized to minimize Firebase reads
  /// Requirements: 2.1, 2.2
  Future<Map<String, Map<DateTime, int>>> aggregateByZoneMemberAndDay({
    required List<String> zoneMemberIds,
    required List<DateTime> days,
  }) async {
    try {
      if (zoneMemberIds.isEmpty || days.isEmpty) {
        return {};
      }

      // Sort days to get date range
      final sortedDays = List<DateTime>.from(days)..sort();
      final startDate = DateTime(
        sortedDays.first.year,
        sortedDays.first.month,
        sortedDays.first.day,
      );
      final endDate = DateTime(
        sortedDays.last.year,
        sortedDays.last.month,
        sortedDays.last.day,
      ).add(const Duration(days: 1));

      // Initialize result map
      final Map<String, Map<DateTime, int>> result = {};
      for (var zoneMemberId in zoneMemberIds) {
        result[zoneMemberId] = {};
        for (var day in days) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          result[zoneMemberId]![normalizedDay] = 0;
        }
      }

      // Query zone pointings collection
      final zonePointingsRef =
          FirebaseFirestore.instance.collection("zonePointings");

      Query query = zonePointingsRef
          .where('datetimestamp', isGreaterThanOrEqualTo: startDate)
          .where('datetimestamp', isLessThan: endDate);

      // If we have 10 or fewer zone members, use whereIn for efficiency
      if (zoneMemberIds.length <= 10) {
        query = query.where('zoneMember.UID', whereIn: zoneMemberIds);
      }

      // Execute query
      final snapshot = await query.get();

      // Process results and group by zone member and day
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Extract zone member UID
          final zoneMemberData = data['zoneMember'] as Map<String, dynamic>?;
          if (zoneMemberData == null) continue;

          final zoneMemberUID = zoneMemberData['UID'] as String?;
          if (zoneMemberUID == null || !zoneMemberIds.contains(zoneMemberUID)) {
            continue;
          }

          // Extract and normalize date
          final timestamp = data['datetimestamp'];
          DateTime? pointageDate;

          if (timestamp is Timestamp) {
            pointageDate = timestamp.toDate();
          } else if (timestamp is DateTime) {
            pointageDate = timestamp;
          } else if (timestamp is String) {
            pointageDate = DateTime.tryParse(timestamp);
          }

          if (pointageDate == null) continue;

          final normalizedDate = DateTime(
            pointageDate.year,
            pointageDate.month,
            pointageDate.day,
          );

          // Increment count if this day is in our requested days
          if (result[zoneMemberUID]?.containsKey(normalizedDate) ?? false) {
            result[zoneMemberUID]![normalizedDate] =
                (result[zoneMemberUID]![normalizedDate] ?? 0) + 1;
          }
        } catch (e) {
          debugPrint(
              'Error processing document in aggregateByZoneMemberAndDay: $e');
        }
      }

      return result;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Firebase error in aggregateByZoneMemberAndDay: ${e.code}');
      debugPrint('Firebase error in aggregateByZoneMemberAndDay: ${e}');
      throw PointageException.query(
        message: 'Erreur lors de l\'agrégation par chef de zone et jour',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in aggregateByZoneMemberAndDay: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Global statistics model
class GlobalStats {
  final int totalPointages;
  final int uniqueSites;
  final int uniqueSupervisors;
  final double averagePointagesPerDay;
  final double averagePointagesPerSupervisor;
  final double averagePointagesPerSite;
  final Map<String, int> pointagesBySupervisor;
  final Map<String, int> pointagesBySite;
  final Map<DateTime, int> pointagesByDay;
  final DateTime startDate;
  final DateTime endDate;

  GlobalStats({
    required this.totalPointages,
    required this.uniqueSites,
    required this.uniqueSupervisors,
    required this.averagePointagesPerDay,
    required this.averagePointagesPerSupervisor,
    required this.averagePointagesPerSite,
    required this.pointagesBySupervisor,
    required this.pointagesBySite,
    required this.pointagesByDay,
    required this.startDate,
    required this.endDate,
  });

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

  /// Get the busiest day
  MapEntry<DateTime, int>? get busiestDay {
    if (pointagesByDay.isEmpty) return null;
    return pointagesByDay.entries.reduce((a, b) => a.value > b.value ? a : b);
  }

  /// Get the slowest day
  MapEntry<DateTime, int>? get slowestDay {
    if (pointagesByDay.isEmpty) return null;
    return pointagesByDay.entries.reduce((a, b) => a.value < b.value ? a : b);
  }

  @override
  String toString() {
    return 'GlobalStats(total: $totalPointages, sites: $uniqueSites, supervisors: $uniqueSupervisors, avgPerDay: $averagePointagesPerDay)';
  }
}
