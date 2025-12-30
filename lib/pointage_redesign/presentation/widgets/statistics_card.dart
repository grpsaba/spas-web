import 'package:flutter/material.dart';
import '../../models/pointage_stats.dart';
import '../design_system.dart';

/// Card displaying key metrics in a grid layout with icons
/// Supports both standard and compact modes
class StatisticsCard extends StatelessWidget {
  final int? totalPointages;
  final int? uniqueSupervisors;
  final int? uniqueSites;
  final double? averagePerDay;
  final String? supervisorLabel;
  final String? siteLabel;
  final bool isLoading;
  final PointageStats? stats;
  
  /// When true, displays a compact horizontal layout with reduced height
  final bool compact;

  const StatisticsCard({
    Key? key,
    this.totalPointages,
    this.uniqueSupervisors,
    this.uniqueSites,
    this.averagePerDay,
    this.supervisorLabel,
    this.siteLabel,
    this.isLoading = false,
    this.stats,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PointageCardDecorations.standard,
      padding: EdgeInsets.all(compact ? PointageSpacing.md : PointageSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          // Header - smaller in compact mode
          if (!compact) ...[
            Row(
              children: const [
                Icon(
                  Icons.analytics_outlined,
                  color: PointageColors.primary,
                  size: PointageIconSizes.md,
                ),
                SizedBox(width: PointageSpacing.sm),
                Text(
                  'Statistiques',
                  style: PointageTextStyles.headline3,
                ),
              ],
            ),
            const SizedBox(height: PointageSpacing.lg),
          ],
          
          // Metrics content
          if (isLoading)
            compact ? _buildCompactLoadingSkeleton() : _buildLoadingSkeleton()
          else if (stats != null || _hasDirectValues())
            compact ? _buildCompactLayout() : _buildMetricsGrid(stats)
          else
            _buildEmptyState(),
        ],
      ),
    );
  }

  bool _hasDirectValues() {
    return totalPointages != null || 
           uniqueSupervisors != null || 
           uniqueSites != null || 
           averagePerDay != null;
  }

  /// Compact horizontal layout with 4 items in a row
  /// Uses LayoutBuilder for responsive behavior on small screens
  Widget _buildCompactLayout() {
    final total = totalPointages ?? stats?.totalPointages ?? 0;
    final supervisors = uniqueSupervisors ?? stats?.uniqueSupervisors ?? 0;
    final sites = uniqueSites ?? stats?.uniqueSites ?? 0;
    final average = averagePerDay ?? stats?.averagePointagesPerDay ?? 0.0;

    final items = [
      _CompactStatItem(
        icon: Icons.check_circle_outline,
        label: 'Total',
        value: total.toString(),
        color: PointageColors.primary,
      ),
      _CompactStatItem(
        icon: Icons.location_on_outlined,
        label: siteLabel ?? 'Sites',
        value: sites.toString(),
        color: PointageColors.secondary,
      ),
      _CompactStatItem(
        icon: Icons.people_outline,
        label: supervisorLabel ?? 'Superviseurs',
        value: supervisors.toString(),
        color: PointageColors.success,
      ),
      _CompactStatItem(
        icon: Icons.trending_up,
        label: 'Moy/Jour',
        value: average.toStringAsFixed(1),
        color: PointageColors.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 2 items per row if width < 600, otherwise 4 items
        if (constraints.maxWidth < 600) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: items[0]),
                  const SizedBox(width: PointageSpacing.sm),
                  Expanded(child: items[1]),
                ],
              ),
              const SizedBox(height: PointageSpacing.sm),
              Row(
                children: [
                  Expanded(child: items[2]),
                  const SizedBox(width: PointageSpacing.sm),
                  Expanded(child: items[3]),
                ],
              ),
            ],
          );
        }
        
        // Desktop: 4 items in a single row
        return Row(
          children: [
            Expanded(child: items[0]),
            const SizedBox(width: PointageSpacing.sm),
            Expanded(child: items[1]),
            const SizedBox(width: PointageSpacing.sm),
            Expanded(child: items[2]),
            const SizedBox(width: PointageSpacing.sm),
            Expanded(child: items[3]),
          ],
        );
      },
    );
  }

  /// Compact loading skeleton
  Widget _buildCompactLoadingSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final items = List.generate(4, (_) => const _CompactLoadingItem());
        
        if (constraints.maxWidth < 600) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: items[0]),
                  const SizedBox(width: PointageSpacing.sm),
                  Expanded(child: items[1]),
                ],
              ),
              const SizedBox(height: PointageSpacing.sm),
              Row(
                children: [
                  Expanded(child: items[2]),
                  const SizedBox(width: PointageSpacing.sm),
                  Expanded(child: items[3]),
                ],
              ),
            ],
          );
        }
        
        return Row(
          children: [
            Expanded(child: items[0]),
            const SizedBox(width: PointageSpacing.sm),
            Expanded(child: items[1]),
            const SizedBox(width: PointageSpacing.sm),
            Expanded(child: items[2]),
            const SizedBox(width: PointageSpacing.sm),
            Expanded(child: items[3]),
          ],
        );
      },
    );
  }

  Widget _buildMetricsGrid(PointageStats? stats) {
    // Use provided values or fall back to stats object
    final total = totalPointages ?? stats?.totalPointages ?? 0;
    final supervisors = uniqueSupervisors ?? stats?.uniqueSupervisors ?? 0;
    final sites = uniqueSites ?? stats?.uniqueSites ?? 0;
    final average = averagePerDay ?? stats?.averagePointagesPerDay ?? 0.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid: 2 columns on mobile, 4 on desktop
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: PointageSpacing.md,
          crossAxisSpacing: PointageSpacing.md,
          childAspectRatio: 1.5,
          children: [
            _StatisticItem(
              icon: Icons.check_circle_outline,
              label: 'Total Pointages',
              value: total.toString(),
              color: PointageColors.primary,
            ),
            _StatisticItem(
              icon: Icons.location_on_outlined,
              label: siteLabel ?? 'Sites Uniques',
              value: sites.toString(),
              color: PointageColors.secondary,
            ),
            _StatisticItem(
              icon: Icons.people_outline,
              label: supervisorLabel ?? 'Superviseurs',
              value: supervisors.toString(),
              color: PointageColors.success,
            ),
            _StatisticItem(
              icon: Icons.trending_up,
              label: 'Moyenne/Jour',
              value: average.toStringAsFixed(1),
              color: PointageColors.warning,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: PointageSpacing.md,
          crossAxisSpacing: PointageSpacing.md,
          childAspectRatio: 1.5,
          children: List.generate(
            4,
            (index) => _LoadingStatisticItem(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? PointageSpacing.md : PointageSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: compact ? PointageIconSizes.lg : PointageIconSizes.xl,
              color: PointageColors.textSecondary,
            ),
            const SizedBox(height: PointageSpacing.md),
            Text(
              'Aucune statistique disponible',
              style: PointageTextStyles.body1.copyWith(
                color: PointageColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Compact statistic item with horizontal layout
class _CompactStatItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CompactStatItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  State<_CompactStatItem> createState() => _CompactStatItemState();
}

class _CompactStatItemState extends State<_CompactStatItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: PointageAnimations.fast,
        curve: PointageAnimations.defaultCurve,
        padding: const EdgeInsets.all(PointageSpacing.sm),
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.color.withValues(alpha: 0.05)
              : PointageColors.background,
          borderRadius: PointageBorderRadius.medium,
          border: Border.all(
            color: _isHovered ? widget.color : PointageColors.divider,
            width: _isHovered ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon - smaller in compact mode
            Container(
              padding: const EdgeInsets.all(PointageSpacing.xs),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: PointageBorderRadius.small,
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: PointageIconSizes.sm,
              ),
            ),
            
            const SizedBox(width: PointageSpacing.sm),
            
            // Value and label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.value,
                    style: PointageTextStyles.headline4.copyWith(
                      color: widget.color,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.label,
                    style: PointageTextStyles.caption.copyWith(
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact loading skeleton item
class _CompactLoadingItem extends StatefulWidget {
  const _CompactLoadingItem({Key? key}) : super(key: key);

  @override
  State<_CompactLoadingItem> createState() => _CompactLoadingItemState();
}

class _CompactLoadingItemState extends State<_CompactLoadingItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(PointageSpacing.sm),
          decoration: BoxDecoration(
            color: PointageColors.background,
            borderRadius: PointageBorderRadius.medium,
            border: Border.all(color: PointageColors.divider),
          ),
          child: Row(
            children: [
              // Icon skeleton
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: PointageColors.divider.withValues(alpha: _animation.value),
                  borderRadius: PointageBorderRadius.small,
                ),
              ),
              const SizedBox(width: PointageSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 16,
                      decoration: BoxDecoration(
                        color: PointageColors.divider.withValues(alpha: _animation.value),
                        borderRadius: PointageBorderRadius.small,
                      ),
                    ),
                    const SizedBox(height: PointageSpacing.xs),
                    Container(
                      width: 60,
                      height: 10,
                      decoration: BoxDecoration(
                        color: PointageColors.divider.withValues(alpha: _animation.value),
                        borderRadius: PointageBorderRadius.small,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


/// Individual statistic item (standard mode)
class _StatisticItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatisticItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  State<_StatisticItem> createState() => _StatisticItemState();
}

class _StatisticItemState extends State<_StatisticItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: PointageAnimations.fast,
        curve: PointageAnimations.defaultCurve,
        padding: const EdgeInsets.all(PointageSpacing.md),
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.color.withValues(alpha: 0.05)
              : PointageColors.background,
          borderRadius: PointageBorderRadius.medium,
          border: Border.all(
            color: _isHovered ? widget.color : PointageColors.divider,
            width: _isHovered ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(PointageSpacing.sm),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: PointageBorderRadius.small,
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: PointageIconSizes.md,
              ),
            ),
            
            const SizedBox(height: PointageSpacing.sm),
            
            // Value
            Text(
              widget.value,
              style: PointageTextStyles.headline2.copyWith(
                color: widget.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: PointageSpacing.xs),
            
            // Label
            Text(
              widget.label,
              style: PointageTextStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading skeleton for statistic item (standard mode)
class _LoadingStatisticItem extends StatefulWidget {
  @override
  State<_LoadingStatisticItem> createState() => _LoadingStatisticItemState();
}

class _LoadingStatisticItemState extends State<_LoadingStatisticItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(PointageSpacing.md),
          decoration: BoxDecoration(
            color: PointageColors.background,
            borderRadius: PointageBorderRadius.medium,
            border: Border.all(color: PointageColors.divider),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon skeleton
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: PointageColors.divider.withValues(alpha: _animation.value),
                  borderRadius: PointageBorderRadius.small,
                ),
              ),
              
              const SizedBox(height: PointageSpacing.sm),
              
              // Value skeleton
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: PointageColors.divider.withValues(alpha: _animation.value),
                  borderRadius: PointageBorderRadius.small,
                ),
              ),
              
              const SizedBox(height: PointageSpacing.xs),
              
              // Label skeleton
              Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                  color: PointageColors.divider.withValues(alpha: _animation.value),
                  borderRadius: PointageBorderRadius.small,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
