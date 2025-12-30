import 'package:flutter/foundation.dart';
import '../models/pointage_filters.dart';
import '../models/pagination_models.dart';
import '../models/pointage_stats.dart';
import '../models/pointage_exception.dart';
import '../data/pointage_repository.dart';
import '../data/cache_manager.dart';
import '../../model.dart';

/// Provider for managing pointage state with caching and pagination
/// 
/// Implements state management with ChangeNotifier for reactive UI updates
/// Requirements: 1.1, 1.3, 5.3, 9.1
class PointageProvider extends ChangeNotifier {
  final PointageRepository _repository;
  final CacheManager _cacheManager;

  // State
  List<PointingSite> _pointages = [];
  PointageFilters _filters = PointageFilters();
  PaginationState _pagination = PaginationState(itemsPerPage: 20);
  PointageStats? _stats;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingStats = false;
  bool _isUsingCachedData = false;
  bool _isRefreshingInBackground = false;
  String? _error;
  String _sortField = 'datetimestamp';
  bool _sortAscending = false;

  PointageProvider({
    required PointageRepository repository,
    required CacheManager cacheManager,
  })  : _repository = repository,
        _cacheManager = cacheManager {
    _initialize();
  }

  // Getters
  List<PointingSite> get pointages => List.unmodifiable(_pointages);
  PointageFilters get filters => _filters;
  PaginationState get pagination => _pagination;
  PointageStats? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingStats => _isLoadingStats;
  bool get isUsingCachedData => _isUsingCachedData;
  bool get isRefreshingInBackground => _isRefreshingInBackground;
  String? get error => _error;
  String get sortField => _sortField;
  bool get sortAscending => _sortAscending;
  bool get hasData => _pointages.isNotEmpty;
  bool get hasError => _error != null;
  bool get hasMoreData => _pagination.canGoNext;
  bool get isAtEndOfList => !_pagination.canGoNext && _pointages.isNotEmpty;

  /// Initialize the provider
  Future<void> _initialize() async {
    try {
      await _cacheManager.initialize();
    } catch (e) {
      debugPrint('Error initializing PointageProvider: $e');
    }
  }

  /// Load pointages with optional cache integration
  /// 
  /// If refresh is false, will try to load from cache first
  /// Requirements: 1.1, 9.1
  Future<void> loadPointages({bool refresh = false}) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Try to load from cache if not refreshing
      if (!refresh) {
        final cached = await _loadFromCache();
        if (cached) {
          _isLoading = false;
          notifyListeners();
          
          // Load fresh data in background
          _loadFreshDataInBackground();
          return;
        }
      }

      // Load from repository
      await _loadFromRepository();
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Apply filters and reload data
  /// 
  /// Filters are applied server-side for optimal performance
  /// Requirements: 1.3, 5.3
  Future<void> applyFilters(PointageFilters newFilters) async {
    if (_filters == newFilters) return;

    try {
      _filters = newFilters;
      _pagination = _pagination.reset(); // Reset to first page
      _error = null;
      
      // Clear pagination cursors in repository
      _repository.clearPaginationCursors();
      
      // Invalidate cache for old filters
      await _invalidateCache();
      
      // Load with new filters
      await loadPointages(refresh: true);
      
      // Reload statistics with new filters
      await loadStats();
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
    }
  }

  /// Load next page of pointages
  /// 
  /// Implements pagination for efficient data loading
  /// Supports both traditional pagination and infinite scroll (lazy loading)
  /// Requirements: 1.1, 9.4
  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_pagination.canGoNext) return;

    try {
      _isLoadingMore = true;
      _error = null;
      notifyListeners();

      final nextPage = _pagination.currentPage + 1;
      final result = await _repository.getPointages(
        page: nextPage,
        pageSize: _pagination.itemsPerPage,
        filters: _filters.isEmpty ? null : _filters,
        sortField: _sortField,
        sortAscending: _sortAscending,
      );

      // Append new items to existing list (for lazy loading/infinite scroll)
      _pointages.addAll(result.items);
      _pagination = _pagination.copyWith(
        currentPage: nextPage,
        totalItems: result.totalCount,
      );

      // Update cache with new data
      await _saveToCache();
      
      debugPrint('Loaded page $nextPage: ${result.items.length} items (total: ${_pointages.length})');
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Load previous page of pointages
  Future<void> loadPreviousPage() async {
    if (_isLoading || !_pagination.canGoPrevious) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final prevPage = _pagination.currentPage - 1;
      final result = await _repository.getPointages(
        page: prevPage,
        pageSize: _pagination.itemsPerPage,
        filters: _filters.isEmpty ? null : _filters,
        sortField: _sortField,
        sortAscending: _sortAscending,
      );

      _pointages = result.items;
      _pagination = _pagination.copyWith(
        currentPage: prevPage,
        totalItems: result.totalCount,
      );

      await _saveToCache();
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Go to a specific page
  Future<void> goToPage(int page) async {
    if (_isLoading || page == _pagination.currentPage) return;
    if (page < 1 || page > _pagination.totalPages) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _repository.getPointages(
        page: page,
        pageSize: _pagination.itemsPerPage,
        filters: _filters.isEmpty ? null : _filters,
        sortField: _sortField,
        sortAscending: _sortAscending,
      );

      _pointages = result.items;
      _pagination = _pagination.copyWith(
        currentPage: page,
        totalItems: result.totalCount,
      );

      await _saveToCache();
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh data with cache invalidation
  /// 
  /// Forces a fresh load from the server
  /// Requirements: 9.1, 9.2
  Future<void> refreshData() async {
    await _invalidateCache();
    await loadPointages(refresh: true);
    await loadStats();
  }

  /// Load statistics for the current filters
  /// 
  /// Requirements: 7.1
  Future<void> loadStats() async {
    if (_isLoadingStats) return;

    try {
      _isLoadingStats = true;
      notifyListeners();

      // Use date range from filters or default to last 30 days
      final endDate = _filters.dateRange?.end ?? DateTime.now();
      final startDate = _filters.dateRange?.start ?? 
          endDate.subtract(const Duration(days: 30));

      _stats = await _repository.getStats(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Error loading stats: $e');
      // Don't set error state for stats, just log it
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Change sort configuration
  Future<void> changeSort(String field, {bool? ascending}) async {
    _sortField = field;
    _sortAscending = ascending ?? !_sortAscending;
    
    // Clear pagination cursors since sort changed
    _repository.clearPaginationCursors();
    
    // Reset to first page and reload
    _pagination = _pagination.reset();
    await loadPointages(refresh: true);
  }

  /// Change items per page
  Future<void> changeItemsPerPage(int itemsPerPage) async {
    if (itemsPerPage == _pagination.itemsPerPage) return;

    _pagination = PaginationState(
      currentPage: 1,
      itemsPerPage: itemsPerPage,
      totalItems: _pagination.totalItems,
    );

    await loadPointages(refresh: true);
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    await applyFilters(PointageFilters());
  }

  // Private helper methods

  /// Load data from repository
  Future<void> _loadFromRepository() async {
    final result = await _repository.getPointages(
      page: _pagination.currentPage,
      pageSize: _pagination.itemsPerPage,
      filters: _filters.isEmpty ? null : _filters,
      sortField: _sortField,
      sortAscending: _sortAscending,
    );

    _pointages = result.items;
    _pagination = _pagination.copyWith(
      totalItems: result.totalCount,
    );

    _isUsingCachedData = false;
    
    // Save to cache
    await _saveToCache();
  }

  /// Try to load from cache
  /// 
  /// Returns true if cache was valid and loaded
  Future<bool> _loadFromCache() async {
    try {
      final cacheKey = _getCacheKey();
      final cached = await _cacheManager.get<Map<String, dynamic>>(cacheKey);

      if (cached != null) {
        // Parse cached data
        final itemsList = cached['items'] as List<dynamic>?;
        if (itemsList != null) {
          _pointages = itemsList
              .map((json) => PointingSite.fromJson(json as Map<String, dynamic>))
              .toList();
          
          _pagination = PaginationState(
            currentPage: cached['currentPage'] as int? ?? 1,
            itemsPerPage: cached['itemsPerPage'] as int? ?? 20,
            totalItems: cached['totalItems'] as int? ?? 0,
          );

          _isUsingCachedData = true;
          debugPrint('Loaded ${_pointages.length} pointages from cache');
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }

    _isUsingCachedData = false;
    return false;
  }

  /// Save current data to cache
  Future<void> _saveToCache() async {
    try {
      final cacheKey = _getCacheKey();
      final data = {
        'items': _pointages.map((p) => p.toJson()).toList(),
        'currentPage': _pagination.currentPage,
        'itemsPerPage': _pagination.itemsPerPage,
        'totalItems': _pagination.totalItems,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _cacheManager.set(
        cacheKey,
        data,
        ttl: const Duration(minutes: 5),
      );

      debugPrint('Saved ${_pointages.length} pointages to cache');
    } catch (e) {
      debugPrint('Error saving to cache: $e');
      // Don't throw, caching is optional
    }
  }

  /// Invalidate cache for current filters
  Future<void> _invalidateCache() async {
    try {
      final cacheKey = _getCacheKey();
      await _cacheManager.invalidate(cacheKey);
    } catch (e) {
      debugPrint('Error invalidating cache: $e');
    }
  }

  /// Load fresh data in background without blocking UI
  Future<void> _loadFreshDataInBackground() async {
    if (_isRefreshingInBackground) return;
    
    try {
      _isRefreshingInBackground = true;
      notifyListeners();
      
      final result = await _repository.getPointages(
        page: _pagination.currentPage,
        pageSize: _pagination.itemsPerPage,
        filters: _filters.isEmpty ? null : _filters,
        sortField: _sortField,
        sortAscending: _sortAscending,
      );

      // Only update if data has changed
      if (result.items.length != _pointages.length ||
          result.totalCount != _pagination.totalItems) {
        _pointages = result.items;
        _pagination = _pagination.copyWith(
          totalItems: result.totalCount,
        );

        _isUsingCachedData = false;
        await _saveToCache();
        notifyListeners();
        
        debugPrint('Updated with fresh data in background');
      } else {
        // Data is the same, just mark as not using cache anymore
        _isUsingCachedData = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading fresh data in background: $e');
      // Don't show error to user, this is a background operation
    } finally {
      _isRefreshingInBackground = false;
      notifyListeners();
    }
  }

  /// Generate cache key based on current filters and pagination
  String _getCacheKey() {
    final parts = [
      'pointages',
      'page_${_pagination.currentPage}',
      'size_${_pagination.itemsPerPage}',
      'sort_${_sortField}_${_sortAscending ? 'asc' : 'desc'}',
    ];

    if (_filters.dateRange != null) {
      parts.add('date_${_filters.dateRange!.start.toIso8601String()}_${_filters.dateRange!.end.toIso8601String()}');
    }
    if (_filters.supervisorIds != null && _filters.supervisorIds!.isNotEmpty) {
      parts.add('sup_${_filters.supervisorIds!.join('_')}');
    }
    if (_filters.siteIds != null && _filters.siteIds!.isNotEmpty) {
      parts.add('site_${_filters.siteIds!.join('_')}');
    }
    if (_filters.zoneIds != null && _filters.zoneIds!.isNotEmpty) {
      parts.add('zone_${_filters.zoneIds!.join('_')}');
    }
    if (_filters.searchQuery != null && _filters.searchQuery!.isNotEmpty) {
      parts.add('search_${_filters.searchQuery}');
    }

    return parts.join('_');
  }

  /// Handle errors and convert to user-friendly messages
  void _handleError(dynamic error, StackTrace? stackTrace) {
    debugPrint('Error in PointageProvider: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }

    if (error is PointageException) {
      _error = error.userMessage;
    } else {
      _error = 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
    }
  }

  @override
  void dispose() {
    // Clean up resources if needed
    super.dispose();
  }
}
