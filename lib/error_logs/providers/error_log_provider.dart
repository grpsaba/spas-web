import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/department_scope.dart';
import '../../services/tenant_scope.dart';
import '../models/error_log_model.dart';

/// Provider for managing error logs with Firestore pagination
class ErrorLogProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _pageSize = 20;

  // State
  List<ErrorLog> _logs = [];
  ErrorLogFilters _filters = const ErrorLogFilters();
  ErrorLogStats _stats = const ErrorLogStats();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  DocumentSnapshot? _lastDocument;
  Set<String> _selectedIds = {};

  // Getters
  List<ErrorLog> get logs => _logs;
  ErrorLogFilters get filters => _filters;
  ErrorLogStats get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  Set<String> get selectedIds => _selectedIds;
  bool get hasSelection => _selectedIds.isNotEmpty;
  int get selectedCount => _selectedIds.length;

  Query<Map<String, dynamic>> get _scopedQuery =>
      DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_firestore.collection('error_logs')),
      );

  /// Initialize and load first page
  Future<void> initialize() async {
    await Future.wait([
      loadLogs(),
      loadStats(),
    ]);
  }

  /// Load logs with current filters (first page)
  Future<void> loadLogs() async {
    _isLoading = true;
    _error = null;
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();

    try {
      final query = _buildQuery();
      final snapshot = await TenantScope.getQuery(
        'ErrorLogProvider.loadLogs',
        query.limit(_pageSize),
      );

      _logs = snapshot.docs.map((doc) => ErrorLog.fromFirestore(doc)).toList();
      _sortBySeverity();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      _hasMore = snapshot.docs.length == _pageSize;
    } catch (e) {
      _error = 'Erreur de chargement: $e';
      debugPrint('Error loading logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more logs (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final query = _buildQuery();
      final snapshot = await TenantScope.getQuery(
        'ErrorLogProvider.loadMore',
        query.startAfterDocument(_lastDocument!).limit(_pageSize),
      );

      final newLogs =
          snapshot.docs.map((doc) => ErrorLog.fromFirestore(doc)).toList();
      _logs.addAll(newLogs);
      _sortBySeverity();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      _hasMore = snapshot.docs.length == _pageSize;
    } catch (e) {
      _error = 'Erreur de chargement: $e';
      debugPrint('Error loading more logs: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Build Firestore query based on filters
  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = _scopedQuery;

    // Filter by resolved status
    if (_filters.isResolved != null) {
      query = query.where('isResolved', isEqualTo: _filters.isResolved);
    }

    // Filter by error type
    if (_filters.errorType != null) {
      query = query.where('errorType', isEqualTo: _filters.errorType);
    }

    // Filter by type (pointing_site | pointing_agent | pointing_zone)
    if (_filters.type != null) {
      query = query.where('type', isEqualTo: _filters.type);
    }

    // Filter by actor
    if (_filters.supervisorId != null) {
      query = query.where(
        _filters.type == 'pointing_zone' ? 'zoneMember.UID' : 'supervisor.UID',
        isEqualTo: _filters.supervisorId,
      );
    }

    // Filter by date range
    if (_filters.dateRange != null) {
      query = query
          .where('timestamp',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(_filters.dateRange!.start))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(
                  _filters.dateRange!.end.add(const Duration(days: 1))));
    }

    // Order by timestamp descending
    query = query.orderBy('timestamp', descending: true);

    return query;
  }

  /// Sort logs by severity (highest first)
  void _sortBySeverity() {
    _logs.sort((a, b) {
      // First by severity (descending)
      final severityCompare = b.severity.compareTo(a.severity);
      if (severityCompare != 0) return severityCompare;
      // Then by timestamp (descending)
      return b.timestamp.compareTo(a.timestamp);
    });
  }

  /// Load stats for dashboard
  Future<void> loadStats() async {
    try {
      // Get total count
      final totalSnapshot = await TenantScope.getCount(
        'ErrorLogProvider.totalCount',
        _scopedQuery.count(),
      );
      final total = totalSnapshot.count ?? 0;

      // Get unresolved count
      final unresolvedSnapshot = await TenantScope.getCount(
        'ErrorLogProvider.unresolvedCount',
        _scopedQuery.where('isResolved', isEqualTo: false).count(),
      );
      final unresolved = unresolvedSnapshot.count ?? 0;

      // Get counts by error type (limited query for performance)
      final recentLogs = await TenantScope.getQuery(
        'ErrorLogProvider.recentLogs',
        _scopedQuery.orderBy('timestamp', descending: true).limit(500),
      );

      final byErrorType = <String, int>{};
      final byType = <String, int>{};

      for (final doc in recentLogs.docs) {
        final data = doc.data();
        final errorType = data['errorType'] as String? ?? 'unknown';
        final type = data['type'] as String? ?? 'unknown';
        byErrorType[errorType] = (byErrorType[errorType] ?? 0) + 1;
        byType[type] = (byType[type] ?? 0) + 1;
      }

      _stats = ErrorLogStats(
        total: total,
        resolved: total - unresolved,
        unresolved: unresolved,
        byErrorType: byErrorType,
        byType: byType,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  /// Apply filters and reload
  void applyFilters(ErrorLogFilters newFilters) {
    _filters = newFilters;
    _selectedIds.clear();
    loadLogs();
  }

  /// Clear all filters
  void clearFilters() {
    _filters = const ErrorLogFilters();
    _selectedIds.clear();
    loadLogs();
  }

  /// Set resolved status filter
  void setResolvedFilter(bool? isResolved) {
    _filters = _filters.copyWith(
      isResolved: isResolved,
      clearIsResolved: isResolved == null,
    );
    _selectedIds.clear();
    loadLogs();
  }

  /// Set error type filter
  void setErrorTypeFilter(String? errorType) {
    _filters = _filters.copyWith(
      errorType: errorType,
      clearErrorType: errorType == null,
    );
    _selectedIds.clear();
    loadLogs();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _filters = _filters.copyWith(
      searchQuery: query.isEmpty ? null : query,
      clearSearchQuery: query.isEmpty,
    );
    // For search, we filter client-side since Firestore doesn't support full-text search
    notifyListeners();
  }

  /// Get filtered logs (applies client-side search)
  List<ErrorLog> get filteredLogs {
    if (_filters.searchQuery == null || _filters.searchQuery!.isEmpty) {
      return _logs;
    }

    final query = _filters.searchQuery!.toLowerCase();
    return _logs.where((log) {
      return log.customMessage?.toLowerCase().contains(query) == true ||
          log.entityName.toLowerCase().contains(query) ||
          log.actorName.toLowerCase().contains(query) ||
          log.actorRoleLabel.toLowerCase().contains(query) ||
          log.zoneName.toLowerCase().contains(query) ||
          log.errorType.toLowerCase().contains(query);
    }).toList();
  }

  /// Refresh data
  Future<void> refresh() async {
    _selectedIds.clear();
    await Future.wait([
      loadLogs(),
      loadStats(),
    ]);
  }

  /// Toggle selection for an error log
  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  /// Select all visible unresolved logs
  void selectAll() {
    _selectedIds = filteredLogs
        .where((log) => !log.isResolved)
        .map((log) => log.id)
        .toSet();
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  /// Mark a single error as resolved
  Future<bool> markAsResolved(String id, String resolvedBy) async {
    try {
      await _firestore.collection('error_logs').doc(id).update({
        'isResolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': resolvedBy,
      });

      // Update local state using copyWithResolved
      final index = _logs.indexWhere((log) => log.id == id);
      if (index != -1) {
        _logs[index] = _logs[index].copyWithResolved(
          resolvedBy: resolvedBy,
          resolvedAt: DateTime.now(),
        );
      }

      _selectedIds.remove(id);
      await loadStats();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error marking as resolved: $e');
      return false;
    }
  }

  /// Mark multiple errors as resolved
  Future<int> markMultipleAsResolved(
      List<String> ids, String resolvedBy) async {
    int successCount = 0;
    final batch = _firestore.batch();

    for (final id in ids) {
      final docRef = _firestore.collection('error_logs').doc(id);
      batch.update(docRef, {
        'isResolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': resolvedBy,
      });
    }

    try {
      await batch.commit();
      successCount = ids.length;

      // Update local state using copyWithResolved
      final now = DateTime.now();
      for (final id in ids) {
        final index = _logs.indexWhere((log) => log.id == id);
        if (index != -1) {
          _logs[index] = _logs[index].copyWithResolved(
            resolvedBy: resolvedBy,
            resolvedAt: now,
          );
        }
      }

      _selectedIds.removeAll(ids);
      await loadStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking multiple as resolved: $e');
    }

    return successCount;
  }

  /// Export logs to CSV format
  String exportToCsv() {
    final buffer = StringBuffer();
    buffer.writeln(
        'Date,Type,Error Type,Role,Acteur,Zone,Site/Agent,Message,Distance,Platform,Resolved,Resolved By,Resolved At');

    for (final log in filteredLogs) {
      final date =
          '${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}';
      final resolvedAt = log.resolvedAt != null
          ? '${log.resolvedAt!.day}/${log.resolvedAt!.month}/${log.resolvedAt!.year}'
          : '';

      buffer.writeln([
        date,
        log.pointageTypeLabel.replaceAll(',', ' '),
        ErrorTypeConfig.getLabel(log.errorType).replaceAll(',', ' '),
        log.actorRoleLabel.replaceAll(',', ' '),
        log.actorName.replaceAll(',', ' '),
        log.zoneName.replaceAll(',', ' '),
        log.entityName.replaceAll(',', ' '),
        (log.customMessage ?? '').replaceAll(',', ' ').replaceAll('\n', ' '),
        log.distance?.toStringAsFixed(2) ?? '',
        log.devicePlatform ?? '',
        log.isResolved ? 'Oui' : 'Non',
        log.resolvedBy ?? '',
        resolvedAt,
      ].join(','));
    }

    return buffer.toString();
  }

  @override
  void dispose() {
    _logs.clear();
    _selectedIds.clear();
    super.dispose();
  }
}
