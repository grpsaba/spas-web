import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/pointage_filters.dart';
import '../models/pagination_models.dart';
import '../models/pointage_zone_stats.dart';
import '../models/pointage_exception.dart';
import '../../model.dart';

/// Repository for accessing zone pointage data with server-side operations
/// 
/// IMPORTANT: Firebase Composite Indexes Required
/// For optimal query performance, create the following composite indexes in Firebase Console:
/// 
/// 1. Collection: zonePointings
///    Fields: date (Descending), zoneMember.UID (Ascending)
///    
/// 2. Collection: zonePointings
///    Fields: date (Descending), site.UID (Ascending)
///    
/// 3. Collection: zonePointings
///    Fields: date (Descending), zoneMember.zone.codeZone (Ascending)
///    
/// These indexes enable efficient server-side filtering and sorting
/// Requirements: 1.1, 1.2
class PointageZoneRepository {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("zonePointings");
  
  // Cache for pagination cursors
  final Map<String, DocumentSnapshot> _paginationCursors = {};

  /// Get paginated pointages with optional filters and sorting
  /// 
  /// Implements cursor-based server-side pagination for optimal performance
  /// Uses query cursors (startAfter) instead of offset for efficient pagination
  /// Requirements: 1.1, 1.2, 1.3
  Future<PaginatedResult<PointingZone>> getPointages({
    required int page,
    required int pageSize,
    PointageFilters? filters,
    String? sortField,
    bool sortAscending = false,
  }) async {
    try {
      // Build base query
      Query<Map<String, dynamic>> query = _collectionReference
          .withConverter<Map<String, dynamic>>(
        fromFirestore: (snapshot, _) => snapshot.data() ?? {},
        toFirestore: (data, _) => data,
      );

      // Apply filters if provided
      if (filters != null && !filters.isEmpty) {
        query = filters.applyToZoneQuery(query);
      }

      // Apply sorting
      final sort = sortField ?? 'date';
      query = query.orderBy(sort, descending: !sortAscending);

      // Get total count first (for pagination metadata)
      final countSnapshot = await query.count().get();
      final totalCount = countSnapshot.count ?? 0;

      // Generate cursor key for this query configuration
      final cursorKey = _generateCursorKey(page, pageSize, filters, sortField, sortAscending);
      
      // Apply cursor-based pagination
      if (page > 1) {
        // Try to use cached cursor for previous page
        final previousPageKey = _generateCursorKey(page - 1, pageSize, filters, sortField, sortAscending);
        final cursor = _paginationCursors[previousPageKey];
        
        if (cursor != null) {
          // Use cursor for efficient pagination
          query = query.startAfterDocument(cursor);
        } else {
          // Fallback: calculate offset (less efficient but works)
          final offset = (page - 1) * pageSize;
          if (offset > 0) {
            // Fetch documents up to the offset to get the cursor
            final tempQuery = query.limit(offset);
            final tempSnapshot = await tempQuery.get();
            if (tempSnapshot.docs.isNotEmpty) {
              query = query.startAfterDocument(tempSnapshot.docs.last);
            }
          }
        }
      }

      // Limit results to page size
      query = query.limit(pageSize);

      // Execute query
      final snapshot = await query.get();

      // Cache the last document as cursor for next page
      if (snapshot.docs.isNotEmpty) {
        _paginationCursors[cursorKey] = snapshot.docs.last;
      }

      // Parse results
      List<PointingZone> items = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          items.add(PointingZone.fromJson(data));
        } catch (e) {
          debugPrint('Error parsing PointingZone: $e');
          // Continue with other items
        }
      }

      return PaginatedResult<PointingZone>(
        items: items,
        totalCount: totalCount,
        page: page,
        pageSize: pageSize,
      );
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Firebase error in getPointages: ${e.code} - ${e.message}');
      
      if (e.code == 'permission-denied') {
        throw PointageException.permissionDenied(
          originalError: e,
          stackTrace: stackTrace,
        );
      } else if (e.code == 'unavailable') {
        throw PointageException.network(
          originalError: e,
          stackTrace: stackTrace,
        );
      } else if (e.code == 'failed-precondition') {
        throw PointageException.query(
          message: 'Index Firebase manquant. Veuillez créer les index composites requis.',
          originalError: e,
          stackTrace: stackTrace,
        );
      } else {
        throw PointageException.query(
          message: 'Erreur lors de la récupération des pointages',
          originalError: e,
          stackTrace: stackTrace,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Unexpected error in getPointages: $e');
      throw PointageException.unknown(
        message: 'Erreur inattendue lors de la récupération des pointages',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  /// Generate a unique key for pagination cursor caching
  String _generateCursorKey(
    int page,
    int pageSize,
    PointageFilters? filters,
    String? sortField,
    bool sortAscending,
  ) {
    final parts = [
      'page_$page',
      'size_$pageSize',
      'sort_${sortField ?? 'date'}_${sortAscending ? 'asc' : 'desc'}',
    ];
    
    if (filters != null && !filters.isEmpty) {
      parts.add('filters_${filters.hashCode}');
    }
    
    return parts.join('_');
  }
  
  /// Clear pagination cursors (call when filters change)
  void clearPaginationCursors() {
    _paginationCursors.clear();
    debugPrint('Cleared pagination cursors');
  }

  /// Count pointages by zone member for a date range
  /// 
  /// Uses Firebase aggregation for efficient server-side counting
  /// Requirements: 1.2, 1.5
  Future<Map<String, int>> countPointagesByZoneMember({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? zoneMemberIds,
  }) async {
    try {
      // Build query
      Query query = _collectionReference
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThan: endDate.toIso8601String());

      // Filter by specific zone members if provided
      if (zoneMemberIds != null && zoneMemberIds.isNotEmpty) {
        if (zoneMemberIds.length <= 10) {
          query = query.where('zoneMember.UID', whereIn: zoneMemberIds);
        }
      }

      // Get all documents (we need to group by zone member)
      final snapshot = await query.get();
      
      // Count by zone member
      final Map<String, int> counts = {};
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final zoneMemberData = data['zoneMember'] as Map<String, dynamic>?;
          if (zoneMemberData != null) {
            final zoneMemberUID = zoneMemberData['UID'] as String?;
            if (zoneMemberUID != null) {
              counts[zoneMemberUID] = (counts[zoneMemberUID] ?? 0) + 1;
            }
          }
        } catch (e) {
          debugPrint('Error parsing zone member data: $e');
        }
      }

      return counts;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Firebase error in countPointagesByZoneMember: ${e.code}');
      throw PointageException.query(
        message: 'Erreur lors du comptage par chef de zone',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in countPointagesByZoneMember: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Count pointages by zone for a date range
  /// 
  /// Uses Firebase aggregation for efficient server-side counting
  /// Requirements: 1.2, 1.5
  Future<Map<String, int>> countPointagesByZone({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? zoneIds,
  }) async {
    try {
      // Build query
      Query query = _collectionReference
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThan: endDate.toIso8601String());

      // Filter by specific zones if provided
      if (zoneIds != null && zoneIds.isNotEmpty) {
        if (zoneIds.length <= 10) {
          query = query.where('zoneMember.zone.codeZone', whereIn: zoneIds);
        }
      }

      // Get all documents (we need to group by zone)
      final snapshot = await query.get();
      
      // Count by zone
      final Map<String, int> counts = {};
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final zoneMemberData = data['zoneMember'] as Map<String, dynamic>?;
          if (zoneMemberData != null) {
            final zoneData = zoneMemberData['zone'] as Map<String, dynamic>?;
            if (zoneData != null) {
              final zoneCode = zoneData['codeZone'] as String?;
              if (zoneCode != null) {
                counts[zoneCode] = (counts[zoneCode] ?? 0) + 1;
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing zone data: $e');
        }
      }

      return counts;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Firebase error in countPointagesByZone: ${e.code}');
      throw PointageException.query(
        message: 'Erreur lors du comptage par zone',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in countPointagesByZone: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get dashboard statistics for a date range
  /// 
  /// Calculates comprehensive statistics including totals and averages
  /// Requirements: 1.3, 1.4
  Future<PointageZoneStats> getStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Build query for date range
      final query = _collectionReference
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThan: endDate.toIso8601String());

      // Get all documents for the period
      final snapshot = await query.get();
      
      // Calculate statistics
      final Set<String> uniqueZones = {};
      final Set<String> uniqueZoneMembers = {};
      final Map<String, int> pointagesByZoneMember = {};
      final Map<String, int> pointagesByZone = {};

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          // Extract zone member info
          final zoneMemberData = data['zoneMember'] as Map<String, dynamic>?;
          if (zoneMemberData != null) {
            final zoneMemberUID = zoneMemberData['UID'] as String?;
            if (zoneMemberUID != null) {
              uniqueZoneMembers.add(zoneMemberUID);
              pointagesByZoneMember[zoneMemberUID] = 
                  (pointagesByZoneMember[zoneMemberUID] ?? 0) + 1;
            }
            
            // Extract zone info
            final zoneData = zoneMemberData['zone'] as Map<String, dynamic>?;
            if (zoneData != null) {
              final zoneCode = zoneData['codeZone'] as String?;
              if (zoneCode != null) {
                uniqueZones.add(zoneCode);
                pointagesByZone[zoneCode] = (pointagesByZone[zoneCode] ?? 0) + 1;
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing document for stats: $e');
        }
      }

      // Calculate average pointages per day
      final totalPointages = snapshot.docs.length;
      final daysDifference = endDate.difference(startDate).inDays;
      final averagePerDay = daysDifference > 0 
          ? totalPointages / daysDifference 
          : totalPointages.toDouble();

      return PointageZoneStats(
        totalPointages: totalPointages,
        uniqueZones: uniqueZones.length,
        uniqueZoneMembers: uniqueZoneMembers.length,
        averagePointagesPerDay: averagePerDay,
        pointagesByZoneMember: pointagesByZoneMember,
        pointagesByZone: pointagesByZone,
      );
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Firebase error in getStats: ${e.code}');
      throw PointageException.query(
        message: 'Erreur lors du calcul des statistiques',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in getStats: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get all pointages for a date range (use with caution for large datasets)
  /// 
  /// This method loads all data into memory and should only be used
  /// for report generation or when you need all data
  Future<List<PointingZone>> getAllPointages({
    required DateTime startDate,
    required DateTime endDate,
    PointageFilters? filters,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collectionReference
          .withConverter<Map<String, dynamic>>(
        fromFirestore: (snapshot, _) => snapshot.data() ?? {},
        toFirestore: (data, _) => data,
      )
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThan: endDate.toIso8601String());

      // Apply additional filters if provided
      if (filters != null && !filters.isEmpty) {
        query = filters.applyToZoneQuery(query);
      }

      final snapshot = await query.get();
      
      final List<PointingZone> pointages = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          pointages.add(PointingZone.fromJson(data));
        } catch (e) {
          debugPrint('Error parsing PointingZone: $e');
        }
      }

      return pointages;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Firebase error in getAllPointages: ${e.code}');
      throw PointageException.query(
        message: 'Erreur lors de la récupération de tous les pointages',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in getAllPointages: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
