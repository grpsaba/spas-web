import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model for filtering pointage data with server-side query conversion
class PointageFilters {
  final DateTimeRange? dateRange;
  final List<String>? supervisorIds;
  final List<String>? siteIds;
  final List<String>? zoneIds;
  final String? searchQuery;

  PointageFilters({
    this.dateRange,
    this.supervisorIds,
    this.siteIds,
    this.zoneIds,
    this.searchQuery,
  });

  /// Create a filter for today's pointages only
  static PointageFilters today() {
    final now = DateTime.now();
    return PointageFilters(
      dateRange: DateTimeRange(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
    );
  }

  /// Create a filter for this week's pointages (Monday to today)
  static PointageFilters thisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return PointageFilters(
      dateRange: DateTimeRange(
        start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
    );
  }

  /// Create a filter for this month's pointages (1st to today)
  static PointageFilters thisMonth() {
    final now = DateTime.now();
    return PointageFilters(
      dateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
    );
  }

  /// Check if the current filter matches today's date range
  bool get isTodayFilter {
    if (dateRange == null) return false;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return dateRange!.start.year == todayStart.year &&
        dateRange!.start.month == todayStart.month &&
        dateRange!.start.day == todayStart.day &&
        dateRange!.end.year == todayEnd.year &&
        dateRange!.end.month == todayEnd.month &&
        dateRange!.end.day == todayEnd.day;
  }

  /// Check if the current filter matches this week's date range
  bool get isThisWeekFilter {
    if (dateRange == null) return false;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return dateRange!.start.year == weekStart.year &&
        dateRange!.start.month == weekStart.month &&
        dateRange!.start.day == weekStart.day &&
        dateRange!.end.year == now.year &&
        dateRange!.end.month == now.month &&
        dateRange!.end.day == now.day;
  }

  /// Check if the current filter matches this month's date range
  bool get isThisMonthFilter {
    if (dateRange == null) return false;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return dateRange!.start.year == monthStart.year &&
        dateRange!.start.month == monthStart.month &&
        dateRange!.start.day == monthStart.day &&
        dateRange!.end.year == now.year &&
        dateRange!.end.month == now.month &&
        dateRange!.end.day == now.day;
  }

  /// Check if no filters are applied
  bool get isEmpty =>
      dateRange == null &&
      (supervisorIds == null || supervisorIds!.isEmpty) &&
      (siteIds == null || siteIds!.isEmpty) &&
      (zoneIds == null || zoneIds!.isEmpty) &&
      (searchQuery == null || searchQuery!.isEmpty);

  /// Check if filters are valid
  bool get isValid {
    // Date range validation
    if (dateRange != null) {
      if (dateRange!.start.isAfter(dateRange!.end)) {
        return false;
      }
    }

    // List filters should not be empty if provided
    if (supervisorIds != null && supervisorIds!.isEmpty) return false;
    if (siteIds != null && siteIds!.isEmpty) return false;
    if (zoneIds != null && zoneIds!.isEmpty) return false;

    return true;
  }

  /// Convert filters to Firestore query constraints
  Query<Map<String, dynamic>> applyToQuery(
      Query<Map<String, dynamic>> baseQuery) {
    Query<Map<String, dynamic>> query = baseQuery;

    // Apply date range filter using datetimestamp field
    // Note: We use datetimestamp (DateTime/Timestamp) instead of date (String)
    // to ensure compatibility with orderBy clauses
    if (dateRange != null) {
      query = query
          .where('datetimestamp',
              isGreaterThanOrEqualTo: dateRange!.start)
          .where('datetimestamp', isLessThan: dateRange!.end);
    }

    // Apply supervisor filter
    if (supervisorIds != null && supervisorIds!.isNotEmpty) {
      if (supervisorIds!.length == 1) {
        query = query.where('supervisor.UID', isEqualTo: supervisorIds!.first);
      } else {
        // Firestore 'whereIn' supports up to 10 items
        query = query.where('supervisor.UID', whereIn: supervisorIds);
      }
    }

    // Apply site filter
    if (siteIds != null && siteIds!.isNotEmpty) {
      if (siteIds!.length == 1) {
        query = query.where('site.UID', isEqualTo: siteIds!.first);
      } else {
        query = query.where('site.UID', whereIn: siteIds);
      }
    }

    // Apply zone filter
    if (zoneIds != null && zoneIds!.isNotEmpty) {
      if (zoneIds!.length == 1) {
        query = query.where('site.zone.codeZone', isEqualTo: zoneIds!.first);
      } else {
        query = query.where('site.zone.codeZone', whereIn: zoneIds);
      }
    }

    // Note: Search query filtering should be done client-side or using
    // Firestore full-text search extensions as Firestore doesn't support
    // native text search on fields

    return query;
  }

  /// Convert filters to Firestore query constraints for zone pointages
  /// Uses zoneMember fields instead of supervisor fields
  Query<Map<String, dynamic>> applyToZoneQuery(
      Query<Map<String, dynamic>> baseQuery) {
    Query<Map<String, dynamic>> query = baseQuery;

    // Apply date range filter using datetimestamp field
    // Note: We use datetimestamp (DateTime/Timestamp) instead of date (String)
    // to ensure compatibility with orderBy clauses
    if (dateRange != null) {
      query = query
          .where('datetimestamp',
              isGreaterThanOrEqualTo: dateRange!.start)
          .where('datetimestamp', isLessThan: dateRange!.end);
    }

    // Apply zone member filter (using supervisorIds field for zone member UIDs)
    if (supervisorIds != null && supervisorIds!.isNotEmpty) {
      if (supervisorIds!.length == 1) {
        query = query.where('zoneMember.UID', isEqualTo: supervisorIds!.first);
      } else {
        // Firestore 'whereIn' supports up to 10 items
        query = query.where('zoneMember.UID', whereIn: supervisorIds);
      }
    }

    // Apply site filter
    if (siteIds != null && siteIds!.isNotEmpty) {
      if (siteIds!.length == 1) {
        query = query.where('site.UID', isEqualTo: siteIds!.first);
      } else {
        query = query.where('site.UID', whereIn: siteIds);
      }
    }

    // Apply zone filter (using zone code from zoneMember)
    if (zoneIds != null && zoneIds!.isNotEmpty) {
      if (zoneIds!.length == 1) {
        query = query.where('zoneMember.zone.codeZone', isEqualTo: zoneIds!.first);
      } else {
        query = query.where('zoneMember.zone.codeZone', whereIn: zoneIds);
      }
    }

    // Note: Search query filtering should be done client-side or using
    // Firestore full-text search extensions as Firestore doesn't support
    // native text search on fields

    return query;
  }

  /// Create a copy with updated values
  PointageFilters copyWith({
    DateTimeRange? dateRange,
    List<String>? supervisorIds,
    List<String>? siteIds,
    List<String>? zoneIds,
    String? searchQuery,
    bool clearDateRange = false,
    bool clearSupervisorIds = false,
    bool clearSiteIds = false,
    bool clearZoneIds = false,
    bool clearSearchQuery = false,
  }) {
    return PointageFilters(
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      supervisorIds: clearSupervisorIds
          ? null
          : (supervisorIds ?? this.supervisorIds),
      siteIds: clearSiteIds ? null : (siteIds ?? this.siteIds),
      zoneIds: clearZoneIds ? null : (zoneIds ?? this.zoneIds),
      searchQuery:
          clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  /// Clear all filters
  PointageFilters clear() {
    return PointageFilters();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PointageFilters &&
        other.dateRange == dateRange &&
        _listEquals(other.supervisorIds, supervisorIds) &&
        _listEquals(other.siteIds, siteIds) &&
        _listEquals(other.zoneIds, zoneIds) &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode {
    return dateRange.hashCode ^
        _listHashCode(supervisorIds) ^
        _listHashCode(siteIds) ^
        _listHashCode(zoneIds) ^
        searchQuery.hashCode;
  }

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int _listHashCode(List<String>? list) {
    if (list == null) return 0;
    int hash = 0;
    for (var item in list) {
      hash ^= item.hashCode;
    }
    return hash;
  }

  @override
  String toString() {
    return 'PointageFilters(dateRange: $dateRange, supervisorIds: $supervisorIds, siteIds: $siteIds, zoneIds: $zoneIds, searchQuery: $searchQuery)';
  }
}
