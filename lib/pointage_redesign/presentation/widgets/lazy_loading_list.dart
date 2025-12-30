import 'package:flutter/material.dart';
import '../design_system.dart';

/// A widget that implements lazy loading for lists
/// 
/// Automatically loads more items when the user scrolls near the bottom
/// Requirements: 1.1, 9.4
class LazyLoadingList extends StatefulWidget {
  final Widget child;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;
  final double loadMoreThreshold;

  const LazyLoadingList({
    Key? key,
    required this.child,
    this.onLoadMore,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.loadMoreThreshold = 200.0, // Trigger when 200px from bottom
  }) : super(key: key);

  @override
  State<LazyLoadingList> createState() => _LazyLoadingListState();
}

class _LazyLoadingListState extends State<LazyLoadingList> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingTriggered = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoadingMore || _isLoadingTriggered) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = widget.loadMoreThreshold;

    // Check if we're near the bottom
    if (maxScroll - currentScroll <= threshold) {
      _triggerLoadMore();
    }
  }

  void _triggerLoadMore() {
    if (widget.onLoadMore != null && !_isLoadingTriggered) {
      setState(() {
        _isLoadingTriggered = true;
      });

      widget.onLoadMore!();

      // Reset the trigger flag after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoadingTriggered = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: widget.child,
          ),
        ),
        if (widget.isLoadingMore) _buildLoadingIndicator(),
        if (!widget.hasMore && !widget.isLoadingMore) _buildEndOfListIndicator(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                PointageColors.primary,
              ),
            ),
          ),
          const SizedBox(width: PointageSpacing.md),
          Text(
            'Chargement...',
            style: PointageTextStyles.body2.copyWith(
              color: PointageColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndOfListIndicator() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: PointageIconSizes.sm,
            color: PointageColors.success,
          ),
          const SizedBox(width: PointageSpacing.sm),
          Text(
            'Toutes les données ont été chargées',
            style: PointageTextStyles.caption.copyWith(
              color: PointageColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that wraps a scrollable list with lazy loading capability
/// 
/// This version is optimized for ListView.builder patterns
/// Requirements: 1.1, 9.4
class LazyLoadingListView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final double loadMoreThreshold;

  const LazyLoadingListView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.onLoadMore,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.controller,
    this.padding,
    this.loadMoreThreshold = 200.0,
  }) : super(key: key);

  @override
  State<LazyLoadingListView> createState() => _LazyLoadingListViewState();
}

class _LazyLoadingListViewState extends State<LazyLoadingListView> {
  late ScrollController _scrollController;
  bool _isLoadingTriggered = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoadingMore || _isLoadingTriggered) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = widget.loadMoreThreshold;

    if (maxScroll - currentScroll <= threshold) {
      _triggerLoadMore();
    }
  }

  void _triggerLoadMore() {
    if (widget.onLoadMore != null && !_isLoadingTriggered) {
      setState(() {
        _isLoadingTriggered = true;
      });

      widget.onLoadMore!();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoadingTriggered = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total item count including loading indicator
    final totalItemCount = widget.itemCount + 
        (widget.isLoadingMore ? 1 : 0) + 
        (!widget.hasMore && widget.itemCount > 0 ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: totalItemCount,
      itemBuilder: (context, index) {
        // Regular items
        if (index < widget.itemCount) {
          return widget.itemBuilder(context, index);
        }

        // Loading indicator at the end
        if (widget.isLoadingMore && index == widget.itemCount) {
          return _buildLoadingIndicator();
        }

        // End of list indicator
        if (!widget.hasMore && index == widget.itemCount) {
          return _buildEndOfListIndicator();
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  PointageColors.primary,
                ),
              ),
            ),
            const SizedBox(width: PointageSpacing.md),
            Text(
              'Chargement...',
              style: PointageTextStyles.body2.copyWith(
                color: PointageColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndOfListIndicator() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: PointageIconSizes.sm,
              color: PointageColors.success,
            ),
            const SizedBox(width: PointageSpacing.sm),
            Text(
              'Toutes les données ont été chargées',
              style: PointageTextStyles.caption.copyWith(
                color: PointageColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A widget that detects when user scrolls near the bottom
/// 
/// Simpler version that just triggers a callback without managing the list
/// Requirements: 1.1, 9.4
class ScrollLoadTrigger extends StatefulWidget {
  final Widget child;
  final VoidCallback onLoadMore;
  final bool enabled;
  final double threshold;

  const ScrollLoadTrigger({
    Key? key,
    required this.child,
    required this.onLoadMore,
    this.enabled = true,
    this.threshold = 200.0,
  }) : super(key: key);

  @override
  State<ScrollLoadTrigger> createState() => _ScrollLoadTriggerState();
}

class _ScrollLoadTriggerState extends State<ScrollLoadTrigger> {
  final ScrollController _scrollController = ScrollController();
  bool _isTriggered = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.enabled || _isTriggered) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= widget.threshold) {
      _isTriggered = true;
      widget.onLoadMore();

      // Reset after delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _isTriggered = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: widget.child,
    );
  }
}
