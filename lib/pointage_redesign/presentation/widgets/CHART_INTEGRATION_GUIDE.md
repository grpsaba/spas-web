# Chart Integration Guide

This guide shows how to integrate the new chart components into the report pages.

## 1. Supervisor Report Page Integration

### Add to `site_pointage_map.dart`:

```dart
import 'package:spas_web/pointage_redesign/presentation/widgets/performance_chart.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/chart_view_toggle.dart';

class _SitePointageMapState extends State<SitePointageMap> {
  // Add view mode state
  ViewMode _viewMode = ViewMode.table;
  List<SupervisorPerformanceData>? _chartData;
  
  // After generating report, prepare chart data
  void _prepareChartData(List<Map<String, dynamic>> reportData) {
    final nbDays = _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1;
    
    setState(() {
      _chartData = reportData.map((data) {
        return SupervisorPerformanceData.fromReportData(data, nbDays);
      }).toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ... existing header and date picker ...
          
          // Add chart toggle
          if (_chartData != null && _chartData!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ChartViewToggle(
                initialMode: _viewMode,
                preferenceKey: 'supervisor_report_view_mode',
                onModeChanged: (mode) {
                  setState(() {
                    _viewMode = mode;
                  });
                },
              ),
            ),
          
          // Add animated view switcher
          Expanded(
            child: AnimatedViewSwitcher(
              currentMode: _viewMode,
              tableView: _buildTableView(), // Your existing table
              chartView: _buildChartView(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChartView() {
    if (_chartData == null || _chartData!.isEmpty) {
      return Center(child: Text('Aucune donnée disponible'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: PerformanceChart(
        data: _chartData!,
        height: 500,
        showLegend: true,
        title: 'Performance des superviseurs',
      ),
    );
  }
}
```

## 2. Site Report Page Integration

### Add to `site_monthly_pointage.dart`:

```dart
import 'package:spas_web/pointage_redesign/presentation/widgets/visit_frequency_chart.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/chart_view_toggle.dart';

class _SiteMonthlyPointageState extends State<SiteMonthlyPointage> {
  // Add view mode state
  ViewMode _viewMode = ViewMode.table;
  List<SiteVisitData>? _chartData;
  DateTimeRange? _chartDateRange;
  
  // After generating report, prepare chart data
  void _prepareChartData(List<Map<String, dynamic>> reportData) {
    setState(() {
      _chartData = reportData.map((data) {
        return SiteVisitData.fromReportData(data);
      }).toList();
      
      // Sort by visit count descending for better visualization
      _chartData!.sort((a, b) => b.visitCount.compareTo(a.visitCount));
      
      // Take top 20 sites for better readability
      if (_chartData!.length > 20) {
        _chartData = _chartData!.sublist(0, 20);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ... existing header and date picker ...
          
          // Add chart toggle
          if (_chartData != null && _chartData!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ChartViewToggle(
                initialMode: _viewMode,
                preferenceKey: 'site_report_view_mode',
                onModeChanged: (mode) {
                  setState(() {
                    _viewMode = mode;
                  });
                },
              ),
            ),
          
          // Add animated view switcher
          Expanded(
            child: AnimatedViewSwitcher(
              currentMode: _viewMode,
              tableView: _buildTableView(), // Your existing table
              chartView: _buildChartView(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChartView() {
    if (_chartData == null || _chartData!.isEmpty) {
      return Center(child: Text('Aucune donnée disponible'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: VisitFrequencyChart(
        data: _chartData!,
        height: 500,
        chartType: ChartType.bar,
        title: 'Top 20 sites par nombre de visites',
        dateRange: _chartDateRange,
        onDateRangeChanged: (newRange) {
          setState(() {
            _chartDateRange = newRange;
          });
          // Reload data with new date range
          _loadDataForDateRange(newRange);
        },
      ),
    );
  }
}
```

## 3. Pointage List Page Integration

### Add to `pointage_site_list.dart`:

```dart
import 'package:spas_web/pointage_redesign/presentation/widgets/visit_frequency_chart.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/chart_view_toggle.dart';

class _PointageSiteListState extends State<PointageSiteList> {
  ViewMode _viewMode = ViewMode.table;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<PointageProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Column(
            children: [
              // ... existing statistics card and filter bar ...
              
              // Add chart toggle
              Padding(
                padding: const EdgeInsets.all(16),
                child: ChartViewToggle(
                  initialMode: _viewMode,
                  preferenceKey: 'pointage_list_view_mode',
                  onModeChanged: (mode) {
                    setState(() {
                      _viewMode = mode;
                    });
                  },
                ),
              ),
              
              // Add animated view switcher
              Expanded(
                child: AnimatedViewSwitcher(
                  currentMode: _viewMode,
                  tableView: ModernPointageTable(
                    pointages: provider.pointages,
                    sortConfig: TableSortConfig(
                      field: provider.sortField,
                      ascending: provider.sortAscending,
                    ),
                    onSort: (config) {
                      provider.changeSort(config.field, ascending: config.ascending);
                    },
                  ),
                  chartView: _buildChartView(provider),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildChartView(PointageProvider provider) {
    // Aggregate pointages by site
    final Map<String, int> siteVisits = {};
    for (var pointage in provider.pointages) {
      final siteId = pointage.site?.UID ?? 'unknown';
      final siteName = pointage.site?.name ?? 'Unknown';
      siteVisits[siteId] = (siteVisits[siteId] ?? 0) + 1;
    }
    
    // Convert to chart data
    final chartData = siteVisits.entries.map((entry) {
      final site = provider.pointages.firstWhere(
        (p) => p.site?.UID == entry.key,
        orElse: () => provider.pointages.first,
      ).site;
      
      return SiteVisitData(
        siteId: entry.key,
        siteName: site?.name ?? 'Unknown',
        visitCount: entry.value,
      );
    }).toList();
    
    // Sort and take top 20
    chartData.sort((a, b) => b.visitCount.compareTo(a.visitCount));
    final topSites = chartData.take(20).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: VisitFrequencyChart(
        data: topSites,
        height: 500,
        chartType: ChartType.bar,
        title: 'Top 20 sites par nombre de pointages',
      ),
    );
  }
}
```

## Tips

1. **Performance**: For large datasets, consider limiting the number of items shown in charts (e.g., top 20)
2. **Responsiveness**: Charts automatically adapt to container size
3. **User Preference**: The view mode is saved automatically using SharedPreferences
4. **Animations**: The AnimatedViewSwitcher provides smooth transitions between views
5. **Empty States**: All chart components handle empty data gracefully

## Chart Customization

### PerformanceChart
- Adjust `height` for different sizes
- Set `showLegend: false` to hide the legend
- Customize color thresholds in the component if needed

### VisitFrequencyChart
- Switch between `ChartType.bar` and `ChartType.line`
- Add `comparisonData` to show previous period comparison
- Use `onDateRangeChanged` to enable date range filtering

### ChartViewToggle
- Use unique `preferenceKey` for each page to save preferences separately
- Customize icons and labels if needed
