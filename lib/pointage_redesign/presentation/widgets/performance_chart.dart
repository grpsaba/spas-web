import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../design_system.dart';

/// Performance chart component for supervisors
/// 
/// Displays a bar chart showing performance percentages with color coding
/// Requirements: 7.2, 7.5
class PerformanceChart extends StatefulWidget {
  final List<SupervisorPerformanceData> data;
  final double height;
  final bool showLegend;
  final String? title;

  const PerformanceChart({
    Key? key,
    required this.data,
    this.height = 400,
    this.showLegend = true,
    this.title,
  }) : super(key: key);

  @override
  State<PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends State<PerformanceChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: PointageCardDecorations.standard,
      padding: const EdgeInsets.all(PointageSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: PointageTextStyles.headline3,
            ),
            const SizedBox(height: PointageSpacing.md),
          ],
          if (widget.showLegend) ...[
            _buildLegend(),
            const SizedBox(height: PointageSpacing.lg),
          ],
          SizedBox(
            height: widget.height,
            child: BarChart(
              _buildBarChartData(),
              swapAnimationDuration: PointageAnimations.normal,
              swapAnimationCurve: PointageAnimations.defaultCurve,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: PointageCardDecorations.standard,
      padding: const EdgeInsets.all(PointageSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 64,
              color: PointageColors.textSecondary,
            ),
            const SizedBox(height: PointageSpacing.md),
            Text(
              'Aucune donnée de performance disponible',
              style: PointageTextStyles.body1.copyWith(
                color: PointageColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Excellent (≥80%)', PointageColors.chartGreen),
        const SizedBox(width: PointageSpacing.lg),
        _buildLegendItem('Moyen (50-79%)', PointageColors.chartOrange),
        const SizedBox(width: PointageSpacing.lg),
        _buildLegendItem('Faible (<50%)', PointageColors.chartRed),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: PointageSpacing.xs),
        Text(
          label,
          style: PointageTextStyles.caption,
        ),
      ],
    );
  }

  BarChartData _buildBarChartData() {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 100,
      minY: 0,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: PointageColors.textPrimary.withOpacity(0.9),
          tooltipRoundedRadius: PointageBorderRadius.md,
          tooltipPadding: const EdgeInsets.all(PointageSpacing.sm),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final data = widget.data[groupIndex];
            return BarTooltipItem(
              '${data.supervisorName}\n',
              PointageTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: '${data.performance.toStringAsFixed(1)}%\n',
                  style: PointageTextStyles.body2.copyWith(
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: '${data.actualPointages}/${data.maxPointages} pointages',
                  style: PointageTextStyles.caption.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              _touchedIndex = null;
              return;
            }
            _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= widget.data.length) {
                return const SizedBox.shrink();
              }
              
              final data = widget.data[index];
              final names = data.supervisorName.split(' ');
              final displayName = names.length > 1
                  ? '${names[0][0]}. ${names.last}'
                  : data.supervisorName;
              
              return Padding(
                padding: const EdgeInsets.only(top: PointageSpacing.sm),
                child: Text(
                  displayName,
                  style: PointageTextStyles.caption.copyWith(
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
            reservedSize: 40,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
                style: PointageTextStyles.caption,
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: PointageColors.divider,
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(
            color: PointageColors.divider,
            width: 1,
          ),
          left: BorderSide(
            color: PointageColors.divider,
            width: 1,
          ),
        ),
      ),
      barGroups: _buildBarGroups(),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == _touchedIndex;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.performance,
            color: _getPerformanceColor(data.performance),
            width: isTouched ? 24 : 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: PointageColors.background,
            ),
          ),
        ],
        showingTooltipIndicators: isTouched ? [0] : [],
      );
    }).toList();
  }

  Color _getPerformanceColor(double performance) {
    if (performance >= 80) {
      return PointageColors.chartGreen;
    } else if (performance >= 50) {
      return PointageColors.chartOrange;
    } else {
      return PointageColors.chartRed;
    }
  }
}

/// Data model for supervisor performance
class SupervisorPerformanceData {
  final String supervisorId;
  final String supervisorName;
  final double performance;
  final int actualPointages;
  final int maxPointages;
  final int nbSites;

  SupervisorPerformanceData({
    required this.supervisorId,
    required this.supervisorName,
    required this.performance,
    required this.actualPointages,
    required this.maxPointages,
    required this.nbSites,
  });

  /// Create from report data map
  factory SupervisorPerformanceData.fromReportData(
    Map<String, dynamic> reportData,
    int nbDays,
  ) {
    final supervisor = reportData['supervisor'];
    final nbSite = (reportData['nbSite'] ?? 0) as int;
    final pointings = reportData['Pointages'] as List<Map<String, dynamic>>? ?? [];
    
    int actualPointages = 0;
    for (var p in pointings) {
      actualPointages += (p['nbPointage'] ?? 0) as int;
    }
    
    final maxPointages = nbSite * nbDays;
    final performance = maxPointages == 0 ? 0.0 : (actualPointages * 100.0 / maxPointages);
    
    return SupervisorPerformanceData(
      supervisorId: supervisor.UID,
      supervisorName: '${supervisor.firstName} ${supervisor.lastName}',
      performance: performance,
      actualPointages: actualPointages,
      maxPointages: maxPointages,
      nbSites: nbSite,
    );
  }
}
