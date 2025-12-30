import 'dart:math';

/// Configuration and state for pagination
class PaginationState {
  final int currentPage;
  final int itemsPerPage;
  final int totalItems;

  PaginationState({
    this.currentPage = 1,
    this.itemsPerPage = 10,
    this.totalItems = 0,
  });

  /// Calculate total number of pages
  int get totalPages {
    if (totalItems == 0) return 0;
    return (totalItems / itemsPerPage).ceil();
  }

  /// Check if there are more pages after current
  bool get hasMore => currentPage < totalPages;

  /// Check if can navigate to next page
  bool get canGoNext => currentPage < totalPages;

  /// Check if can navigate to previous page
  bool get canGoPrevious => currentPage > 1;

  /// Get the starting item index for current page (0-based)
  int get startIndex => (currentPage - 1) * itemsPerPage;

  /// Get the ending item index for current page (0-based, exclusive)
  int get endIndex => min(startIndex + itemsPerPage, totalItems);

  /// Get the number of items on current page
  int get itemsOnCurrentPage {
    if (totalItems == 0) return 0;
    return min(itemsPerPage, totalItems - startIndex);
  }

  /// Navigate to next page
  PaginationState next() {
    if (!canGoNext) return this;
    return copyWith(currentPage: currentPage + 1);
  }

  /// Navigate to previous page
  PaginationState previous() {
    if (!canGoPrevious) return this;
    return copyWith(currentPage: currentPage - 1);
  }

  /// Navigate to specific page
  PaginationState goToPage(int page) {
    if (page < 1 || page > totalPages) return this;
    return copyWith(currentPage: page);
  }

  /// Navigate to first page
  PaginationState goToFirst() {
    return copyWith(currentPage: 1);
  }

  /// Navigate to last page
  PaginationState goToLast() {
    return copyWith(currentPage: totalPages);
  }

  /// Update total items count (useful when data changes)
  PaginationState updateTotalItems(int newTotal) {
    // Adjust current page if it's now out of bounds
    final newTotalPages = (newTotal / itemsPerPage).ceil();
    final adjustedPage = currentPage > newTotalPages ? newTotalPages : currentPage;
    
    return PaginationState(
      currentPage: max(1, adjustedPage),
      itemsPerPage: itemsPerPage,
      totalItems: newTotal,
    );
  }

  /// Create a copy with updated values
  PaginationState copyWith({
    int? currentPage,
    int? itemsPerPage,
    int? totalItems,
  }) {
    return PaginationState(
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      totalItems: totalItems ?? this.totalItems,
    );
  }

  /// Reset to first page
  PaginationState reset() {
    return PaginationState(
      currentPage: 1,
      itemsPerPage: itemsPerPage,
      totalItems: totalItems,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaginationState &&
        other.currentPage == currentPage &&
        other.itemsPerPage == itemsPerPage &&
        other.totalItems == totalItems;
  }

  @override
  int get hashCode =>
      currentPage.hashCode ^ itemsPerPage.hashCode ^ totalItems.hashCode;

  @override
  String toString() {
    return 'PaginationState(currentPage: $currentPage, itemsPerPage: $itemsPerPage, totalItems: $totalItems, totalPages: $totalPages)';
  }
}

/// Result of a paginated query
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  /// Check if there are more pages after this one
  bool get hasMore => page < totalPages;

  /// Calculate total number of pages
  int get totalPages {
    if (totalCount == 0) return 0;
    return (totalCount / pageSize).ceil();
  }

  /// Check if this is the first page
  bool get isFirstPage => page == 1;

  /// Check if this is the last page
  bool get isLastPage => page >= totalPages;

  /// Get the starting item number (1-based for display)
  int get startItemNumber => (page - 1) * pageSize + 1;

  /// Get the ending item number (1-based for display)
  int get endItemNumber => min(startItemNumber + items.length - 1, totalCount);

  /// Create an empty result
  factory PaginatedResult.empty({int page = 1, int pageSize = 10}) {
    return PaginatedResult<T>(
      items: [],
      totalCount: 0,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Map items to a different type
  PaginatedResult<R> map<R>(R Function(T) mapper) {
    return PaginatedResult<R>(
      items: items.map(mapper).toList(),
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  String toString() {
    return 'PaginatedResult(items: ${items.length}, totalCount: $totalCount, page: $page, pageSize: $pageSize)';
  }
}
