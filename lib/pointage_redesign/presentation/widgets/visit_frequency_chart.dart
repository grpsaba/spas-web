import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../design_system.dart';

/// Visit frequency chart component for sites
/// 
/// Displays line or bar chart for visit trends with date range selector
/// Requirements: 7.3
class VisitFrequencyChart extends StatefulWidget {
  final List<SiteVisitData> data;
  final List<SiteVisitData>? comparisonData;
  final double height;
  final ChartType chartType;
  final String? title;
  final DateTimeRange? dateRange;
  final Function(DateTimeRange)? onDateRangeChanged;

  const VisitFrequencyChart({
    Key? key,
    required this.data,
    this.comparisonData,
    this.height = 400,
    this.chartType = ChartType.bar,
    this.title,
    this.dateRange,
    this.onDateRangeChanged,
  }) : super(key: key);

  @override
  State<VisitFrequencyChart> createState() => _VisitFrequencyChartState();
}

class _VisitFrequencyChartState extends State<VisitFrequencyChart> {
  int? _touchedIndex;
  late ChartType _currentChartType;

  @override
  void initState() {
    super.initState();
    _currentChartType = widget.chartType;
  }

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
          _buildHeader(),
          const SizedBox(height: PointageSpacing.lg),
          if (widget.comparisonData != null) ...[
            _buildComparisonLegend(),
            const SizedBox(height: PointageSpacing.md),
          ],
          SizedBox(
            height: widget.height,
            child: _currentChartType == ChartType.bar
                ? BarChart(
                    _buildBarChartData(),
                  )
                : LineChart(
                    _buildLineChartData(),
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
              Icons.show_chart,
              size: 64,
              color: PointageColors.textSecondary,
            ),
            const SizedBox(height: PointageSpacing.md),
            Text(
              'Aucune donnée de visite disponible',
              style: PointageTextStyles.body1.copyWith(
                color: PointageColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.title != null)
          Text(
            widget.title!,
            style: PointageTextStyles.headline3,
          ),
        Row(
          children: [
            _buildChartTypeToggle(),
            if (widget.onDateRangeChanged != null) ...[
              const SizedBox(width: PointageSpacing.md),
              _buildDateRangeButton(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildChartTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: PointageColors.background,
        borderRadius: PointageBorderRadius.medium,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.bar_chart,
            isSelected: _currentChartType == ChartType.bar,
            onTap: () {
              setState(() {
                _currentChartType = ChartType.bar;
              });
            },
          ),
          _buildToggleButton(
            icon: Icons.show_chart,
            isSelected: _currentChartType == ChartType.line,
            onTap: () {
              setState(() {
                _currentChartType = ChartType.line;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: PointageBorderRadius.medium,
      child: Container(
        padding: const EdgeInsets.all(PointageSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? PointageColors.primary : Colors.transparent,
          borderRadius: PointageBorderRadius.medium,
        ),
        child: Icon(
          icon,
          size: PointageIconSizes.sm,
          color: isSelected ? Colors.white : PointageColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildDateRangeButton() {
    final dateRange = widget.dateRange;
    final String label = dateRange != null
        ? '${_formatDate(dateRange.start)} - ${_formatDate(dateRange.end)}'
        : 'Sélectionner période';

    return OutlinedButton.icon(
      onPressed: () => _showDateRangePicker(),
      icon: const Icon(Icons.date_range, size: PointageIconSizes.sm),
      label: Text(label),
      style: PointageButtonStyles.outlined.copyWith(
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: PointageSpacing.md,
            vertical: PointageSpacing.sm,
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Période actuelle', PointageColors.primary),
        const SizedBox(width: PointageSpacing.lg),
        _buildLegendItem('Période précédente', PointageColors.secondary),
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

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: widget.dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: PointageColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && widget.onDateRangeChanged != null) {
      widget.onDateRangeChanged!(picked);
    }
  }

  BarChartData _buildBarChartData() {
    final maxY = _calculateMaxY();
    
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      minY: 0,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: PointageColors.textPrimary.withOpacity(0.9),
          tooltipRoundedRadius: PointageBorderRadius.md,
          tooltipPadding: const EdgeInsets.all(PointageSpacing.sm),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final data = widget.data[groupIndex];
            final comparison = widget.comparisonData != null && 
                               groupIndex < widget.comparisonData!.length
                ? widget.comparisonData![groupIndex]
                : null;
            
            return BarTooltipItem(
              '${data.siteName}\n',
              PointageTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: '${data.visitCount} visites',
                  style: PointageTextStyles.body2.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (comparison != null)
                  TextSpan(
                    text: '\nPrécédent: ${comparison.visitCount}',
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
      titlesData: _buildTitlesData(),
      gridData: _buildGridData(),
      borderData: _buildBorderData(),
      barGroups: _buildBarGroupsForBarChart(),
    );
  }

  LineChartData _buildLineChartData() {
    final maxY = _calculateMaxY();
    
    return LineChartData(
      maxY: maxY,
      minY: 0,
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: PointageColors.textPrimary.withOpacity(0.9),
          tooltipRoundedRadius: PointageBorderRadius.md,
          tooltipPadding: const EdgeInsets.all(PointageSpacing.sm),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final data = widget.data[spot.x.toInt()];
              return LineTooltipItem(
                '${data.siteName}\n${data.visitCount} visites',
                PointageTextStyles.caption.copyWith(
                  color: Colors.white,
                ),
              );
            }).toList();
          },
        ),
      ),
      titlesData: _buildTitlesData(),
      gridData: _buildGridData(),
      borderData: _buildBorderData(),
      lineBarsData: _buildLineBarsData(),
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
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
            final displayName = data.siteName.length > 10
                ? '${data.siteName.substring(0, 10)}...'
                : data.siteName;
            
            return Padding(
              padding: const EdgeInsets.only(top: PointageSpacing.sm),
              child: Text(
                displayName,
                style: PointageTextStyles.caption.copyWith(fontSize: 10),
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
              value.toInt().toString(),
              style: PointageTextStyles.caption,
            );
          },
        ),
      ),
    );
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: PointageColors.divider,
          strokeWidth: 1,
        );
      },
    );
  }

  FlBorderData _buildBorderData() {
    return FlBorderData(
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
    );
  }

  List<BarChartGroupData> _buildBarGroupsForBarChart() {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == _touchedIndex;
      
      final List<BarChartRodData> rods = [
        BarChartRodData(
          toY: data.visitCount.toDouble(),
          color: PointageColors.primary,
          width: isTouched ? 18 : 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ];

      // Add comparison bar if available
      if (widget.comparisonData != null && index < widget.comparisonData!.length) {
        rods.add(
          BarChartRodData(
            toY: widget.comparisonData![index].visitCount.toDouble(),
            color: PointageColors.secondary,
            width: isTouched ? 18 : 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        );
      }
      
      return BarChartGroupData(
        x: index,
        barRods: rods,
        showingTooltipIndicators: isTouched ? [0] : [],
      );
    }).toList();
  }

  List<LineChartBarData> _buildLineBarsData() {
    final List<LineChartBarData> lines = [
      LineChartBarData(
        spots: widget.data.asMap().entries.map((entry) {
          return FlSpot(
            entry.key.toDouble(),
            entry.value.visitCount.toDouble(),
          );
        }).toList(),
        isCurved: true,
        color: PointageColors.primary,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: PointageColors.primary,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          color: PointageColors.primary.withOpacity(0.1),
        ),
      ),
    ];

    // Add comparison line if available
    if (widget.comparisonData != null) {
      lines.add(
        LineChartBarData(
          spots: widget.comparisonData!.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value.visitCount.toDouble(),
            );
          }).toList(),
          isCurved: true,
          color: PointageColors.secondary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: PointageColors.secondary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: PointageColors.secondary.withOpacity(0.1),
          ),
        ),
      );
    }

    return lines;
  }

  double _calculateMaxY() {
    double max = 0;
    for (var data in widget.data) {
      if (data.visitCount > max) {
        max = data.visitCount.toDouble();
      }
    }
    if (widget.comparisonData != null) {
      for (var data in widget.comparisonData!) {
        if (data.visitCount > max) {
          max = data.visitCount.toDouble();
        }
      }
    }
    return (max * 1.2).ceilToDouble();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Chart type enum
enum ChartType {
  bar,
  line,
}

/// Data model for site visit frequency
class SiteVisitData {
  final String siteId;
  final String siteName;
  final int visitCount;
  final DateTime? date;

  SiteVisitData({
    required this.siteId,
    required this.siteName,
    required this.visitCount,
    this.date,
  });

  /// Create from report data map
  factory SiteVisitData.fromReportData(Map<String, dynamic> reportData) {
    final site = reportData['site'];
    final nbPointage = (reportData['nbPointage'] ?? 0) as int;
    
    return SiteVisitData(
      siteId: site.UID,
      siteName: site.name,
      visitCount: nbPointage,
    );
  }
}
