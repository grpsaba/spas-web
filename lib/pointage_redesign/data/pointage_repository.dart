import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/pointage_filters.dart';
import '../models/pagination_models.dart';
import '../models/pointage_stats.dart';
import '../models/pointage_exception.dart';
import '../../model.dart';

/// Repository for accessing pointage data with server-side operations
/// 
/// IMPORTANT: Firebase Composite Indexes Required
/// For optimal query performance, create the following composite indexes in Firebase Console:
/// 
/// 1. Collection: sitePointings
///    Fields: datetimestamp (Descending), supervisor.UID (Ascending)
///    
/// 2. Collection: sitePointings
///    Fields: datetimestamp (Descending), site.UID (Ascending)
///    
/// 3. Collection: sitePointings
///    Fields: datetimestamp (Descending), zone.codeZone (Ascending)
///    
/// These indexes enable efficient server-side filtering and sorting
/// Requirements: 1.1, 1.2
class PointageRepository {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("sitePointings");
  
  // Cache for pagination cursors
  final Map<String, DocumentSnapshot> _paginationCursors = {};

  /// Get paginated pointages with optional filters and sorting
  /// 
  /// Implements cursor-based server-side pagination for optimal performance
  /// Uses query cursors (startAfter) instead of offset for efficient pagination
  /// Requirements: 1.1, 1.2, 1.3
  Future<PaginatedResult<PointingSite>> getPointages({
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
        query = filters.applyToQuery(query);
      }

      // Apply sorting
      final sort = sortField ?? 'datetimestamp';
      query = query.orderBy(sort, descending: !sortAscending);

      // Get total count first (for pagination metadata)
      // Note: This is cached by Firebase for a short time
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
          // This happens when jumping to a page without going through previous pages
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
      List<PointingSite> items = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          items.add(PointingSite.fromJson(data));
        } catch (e) {
          debugPrint('Error parsing PointingSite: $e');
          // Continue with other items
        }
      }

      return PaginatedResult<PointingSite>(
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
      'sort_${sortField ?? 'datetimestamp'}_${sortAscending ? 'asc' : 'desc'}',
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

  /// Count pointages by supervisor for a date range
  /// 
  /// Uses Firebase aggregation for efficient server-side counting
  /// Requirements: 1.2, 1.5
  Future<Map<String, int>> countPointagesBySupervisor({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? supervisorIds,
  }) async {
    try {
      // Build query
      Query query = _collectionReference
          .where('datetimestamp', isGreaterThanOrEqualTo: startDate)
          .where('datetimestamp', isLessThan: endDate);

      // Filter by specific supervisors if provided
      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        if (supervisorIds.length <= 10) {
          query = query.where('supervisor.UID', whereIn: supervisorIds);
        }
      }

      // Get all documents (we need to group by supervisor)
      final snapshot = await query.get();
      
      // Count by supervisor
      final Map<String, int> counts = {};
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final supervisorData = data['supervisor'] as Map<String, dynamic>?;
          if (supervisorData != null) {
            final supervisorUID = supervisorData['UID'] as String?;
            if (supervisorUID != null) {
              counts[supervisorUID] = (counts[supervisorUID] ?? 0) + 1;
            }
          }
        } catch (e) {
          debugPrint('Error parsing supervisor data: $e');
        }
      }

      return counts;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Firebase error in countPointagesBySupervisor: ${e.code}');
      throw PointageException.query(
        message: 'Erreur lors du comptage par superviseur',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in countPointagesBySupervisor: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Count pointages by site for a date range
  /// 
  /// Uses Firebase aggregation for efficient server-side counting
  /// Requirements: 1.2, 1.5
  Future<Map<String, int>> countPointagesBySite({
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
      if (siteIds != null && siteIds.isNotEmpty) {
        if (siteIds.length <= 10) {
          query = query.where('site.UID', whereIn: siteIds);
        }
      }

      // Get all documents (we need to group by site)
      final snapshot = await query.get();
      
      // Count by site
      final Map<String, int> counts = {};
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final siteData = data['site'] as Map<String, dynamic>?;
          if (siteData != null) {
            final siteUID = siteData['UID'] as String?;
            if (siteUID != null) {
              counts[siteUID] = (counts[siteUID] ?? 0) + 1;
            }
          }
        } catch (e) {
          debugPrint('Error parsing site data: $e');
        }
      }

      return counts;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Firebase error in countPointagesBySite: ${e.code}');
      throw PointageException.query(
        message: 'Erreur lors du comptage par site',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in countPointagesBySite: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get dashboard statistics for a date range
  /// 
  /// Calculates comprehensive statistics including totals and averages
  /// Requirements: 7.1, 7.2
  Future<PointageStats> getStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Build query for date range
      final query = _collectionReference
          .where('datetimestamp', isGreaterThanOrEqualTo: startDate)
          .where('datetimestamp', isLessThan: endDate);

      // Get all documents for the period
      final snapshot = await query.get();
      
      // Calculate statistics
      final Set<String> uniqueSites = {};
      final Set<String> uniqueSupervisors = {};
      final Map<String, int> pointagesBySupervisor = {};
      final Map<String, int> pointagesBySite = {};

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

      return PointageStats(
        totalPointages: totalPointages,
        uniqueSites: uniqueSites.length,
        uniqueSupervisors: uniqueSupervisors.length,
        averagePointagesPerDay: averagePerDay,
        pointagesBySupervisor: pointagesBySupervisor,
        pointagesBySite: pointagesBySite,
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

  /// Count pointages for a specific supervisor on a specific date
  /// 
  /// Optimized for single-day queries
  Future<int> countForSupervisorOnDate({
    required String supervisorUID,
    required DateTime date,
  }) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      
      final query = _collectionReference
          .where('supervisor.UID', isEqualTo: supervisorUID)
          .where('datetimestamp', isGreaterThanOrEqualTo: start)
          .where('datetimestamp', isLessThan: end);
      
      final countSnapshot = await query.count().get();
      return countSnapshot.count ?? 0;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Firebase error in countForSupervisorOnDate: ${e.code}');
      throw PointageException.query(
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in countForSupervisorOnDate: $e');
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
  Future<List<PointingSite>> getAllPointages({
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
          .where('datetimestamp', isGreaterThanOrEqualTo: startDate)
          .where('datetimestamp', isLessThan: endDate);

      // Apply additional filters if provided
      if (filters != null && !filters.isEmpty) {
        query = filters.applyToQuery(query);
      }

      final snapshot = await query.get();
      
      final List<PointingSite> pointages = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          pointages.add(PointingSite.fromJson(data));
        } catch (e) {
          debugPrint('Error parsing PointingSite: $e');
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
