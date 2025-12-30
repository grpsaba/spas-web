# Pointage Redesign UI Components

This directory contains all reusable UI components for the pointage system redesign.

## Components

### 1. ModernDateRangePicker
**File:** `modern_date_range_picker.dart`

A modern date range picker with visual calendar and quick selection buttons.

**Features:**
- Visual calendar picker
- Quick selection buttons (Today, This week, This month, etc.)
- Real-time validation
- Display number of days in range
- Error feedback

**Usage:**
```dart
ModernDateRangePicker(
  initialRange: DateTimeRange(start: startDate, end: endDate),
  onRangeSelected: (range) {
    // Handle range selection
  },
)
```

### 2. GenerationProgressCard
**File:** `generation_progress_card.dart`

Card displaying report generation progress with animated progress bar.

**Features:**
- Animated progress bar with gradient
- Display percentage and current step
- Cancel button with confirmation dialog
- Estimated time remaining
- Current item / total items counter

**Usage:**
```dart
GenerationProgressCard(
  progress: 0.65, // 0.0 to 1.0
  currentStep: 'Processing supervisor 3/10',
  currentItem: 3,
  totalItems: 10,
  estimatedTimeRemaining: Duration(minutes: 2),
  onCancel: () {
    // Handle cancellation
  },
)
```

### 3. StatisticsCard
**File:** `statistics_card.dart`

Card displaying key metrics in a grid layout with icons.

**Features:**
- Responsive grid layout (2 columns on mobile, 4 on desktop)
- Icons for each metric
- Hover effects
- Loading skeleton state
- Empty state

**Usage:**
```dart
StatisticsCard(
  stats: PointageStats(
    totalPointages: 1234,
    uniqueSites: 45,
    uniqueSupervisors: 12,
    averagePointagesPerDay: 41.0,
  ),
  isLoading: false,
)
```

### 4. ModernPointageTable
**File:** `modern_pointage_table.dart`

Modern table component for displaying pointages with hover effects and sorting.

**Features:**
- Hover effects on rows
- Sortable columns with animated icons
- Alternating row colors
- Loading skeleton for rows
- Empty state design
- Distance color coding (green/yellow/red)
- Supervisor avatars with initials

**Usage:**
```dart
ModernPointageTable(
  pointages: pointageList,
  sortConfig: TableSortConfig(field: 'date', ascending: false),
  onSort: (config) {
    // Handle sort
  },
  onRowTap: (pointage) {
    // Handle row tap
  },
)
```

### 5. FilterBar
**File:** `filter_bar.dart`

Filter bar component with search, filter chips, and dropdowns.

**Features:**
- Search input with debounce (500ms)
- Filter chips for active filters
- Filter dropdown buttons with badges
- Clear all filters button
- Result count display
- Responsive layout

**Usage:**
```dart
FilterBar(
  filters: currentFilters,
  onFiltersChanged: (newFilters) {
    // Handle filter changes
  },
  resultCount: 123,
  availableSupervisors: supervisorList,
  availableSites: siteList,
  availableZones: zoneList,
)
```

### 6. ErrorDisplay
**File:** `error_display.dart`

Display component for user-friendly error messages with retry functionality.

**Features:**
- Different styles for error types
- User-friendly error messages
- Retry button for retryable errors
- Actionable suggestions
- Compact and full display modes
- Color-coded by error severity

**Usage:**
```dart
// Full display
ErrorDisplay(
  exception: PointageException.network(),
  onRetry: () {
    // Handle retry
  },
)

// Compact display
ErrorDisplay(
  exception: error,
  compact: true,
  onRetry: retryFunction,
)
```

### 7. SuccessSnackbar
**File:** `success_snackbar.dart`

Success notification snackbar with auto-dismiss and slide-in animation.

**Features:**
- Auto-dismiss with configurable timer
- Slide-in animation from bottom
- Action button support
- Multiple variants (success, info, warning)
- Predefined helpers for common actions

**Usage:**
```dart
// Generic success
SuccessSnackbar.show(
  context,
  message: 'Operation completed successfully',
  actionLabel: 'Undo',
  onAction: () {
    // Handle action
  },
);

// Download success
SuccessSnackbar.showDownloadSuccess(
  context,
  fileName: 'report.xlsx',
  onOpen: () {
    // Open file
  },
);

// Report generation success
SuccessSnackbar.showReportSuccess(
  context,
  reportType: 'Superviseur',
);
```

### 8. ReportHeader
**File:** `report_header.dart`

A reusable header component for report pages with icon, title, and description.

**Features:**
- Modern card design with rounded corners
- Icon with colored background
- Title and description text
- Customizable icon and color
- Consistent with design system

**Usage:**
```dart
ReportHeader(
  title: 'Rapport mensuel par site',
  description: 'Générez un rapport détaillé du nombre de visites par site',
  icon: Icons.analytics_outlined,
  iconColor: PointageColors.primary, // Optional
)
```

## Dialogs

### ModernDialog
**File:** `dialogs/modern_dialog.dart`

Modern dialog component with rounded corners, smooth animations, and backdrop blur.

**Features:**
- Rounded corners
- Smooth animations
- Backdrop blur effect
- DialogAction button component with hover effects
- Primary, secondary, and destructive button styles

**Usage:**
```dart
ModernDialog.show(
  context: context,
  title: 'Confirm Action',
  content: Text('Are you sure you want to proceed?'),
  actions: [
    DialogAction(
      label: 'Cancel',
      onPressed: () => Navigator.pop(context),
    ),
    DialogAction(
      label: 'Confirm',
      onPressed: () {
        // Handle confirmation
        Navigator.pop(context);
      },
      isPrimary: true,
    ),
  ],
);
```

## Design System

All components use the design system constants defined in `design_system.dart`:

- **Colors:** `PointageColors`
- **Typography:** `PointageTextStyles`
- **Spacing:** `PointageSpacing`
- **Border Radius:** `PointageBorderRadius`
- **Shadows:** `PointageShadows`
- **Animations:** `PointageAnimations`
- **Icons:** `PointageIconSizes`
- **Buttons:** `PointageButtonStyles`
- **Inputs:** `PointageInputDecorations`
- **Cards:** `PointageCardDecorations`

### 9. LazyLoadingList
**File:** `lazy_loading_list.dart`

Widgets for implementing lazy loading (infinite scroll) in lists.

**Features:**
- Automatic loading when scrolling near bottom
- Loading indicator at bottom
- End of list indicator
- Configurable load threshold
- Multiple variants for different use cases

**Variants:**

#### LazyLoadingList
Wraps any scrollable content with lazy loading capability.

```dart
LazyLoadingList(
  child: YourScrollableContent(),
  onLoadMore: () {
    provider.loadNextPage();
  },
  hasMore: provider.hasMoreData,
  isLoadingMore: provider.isLoadingMore,
  loadMoreThreshold: 200.0, // Pixels from bottom
)
```

#### LazyLoadingListView
Optimized for ListView.builder patterns.

```dart
LazyLoadingListView(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index]));
  },
  onLoadMore: () {
    provider.loadNextPage();
  },
  hasMore: provider.hasMoreData,
  isLoadingMore: provider.isLoadingMore,
)
```

#### ScrollLoadTrigger
Simple trigger that just calls a callback when near bottom.

```dart
ScrollLoadTrigger(
  child: YourContent(),
  onLoadMore: () {
    provider.loadNextPage();
  },
  enabled: provider.hasMoreData,
  threshold: 200.0,
)
```

**Usage with PointageProvider:**
```dart
Consumer<PointageProvider>(
  builder: (context, provider, child) {
    return LazyLoadingList(
      child: ModernPointageTable(
        pointages: provider.pointages,
        sortConfig: TableSortConfig(
          field: provider.sortField,
          ascending: provider.sortAscending,
        ),
        onSort: (config) {
          provider.changeSort(config.field, ascending: config.ascending);
        },
      ),
      onLoadMore: () {
        provider.loadNextPage();
      },
      hasMore: provider.hasMoreData,
      isLoadingMore: provider.isLoadingMore,
    );
  },
)
```

### 10. PerformanceChart
**File:** `performance_chart.dart`

Bar chart component for displaying supervisor performance percentages.

**Features:**
- Bar chart with color coding (green ≥80%, orange 50-79%, red <50%)
- Interactive tooltips showing details
- Legend with performance ranges
- Hover effects on bars
- Empty state design
- Responsive layout

**Usage:**
```dart
PerformanceChart(
  data: [
    SupervisorPerformanceData(
      supervisorId: 'id1',
      supervisorName: 'John Doe',
      performance: 85.5,
      actualPointages: 120,
      maxPointages: 140,
      nbSites: 7,
    ),
    // More data...
  ],
  height: 400,
  showLegend: true,
  title: 'Performance des superviseurs',
)
```

**Creating data from report:**
```dart
final chartData = reportData.map((data) {
  return SupervisorPerformanceData.fromReportData(data, nbDays);
}).toList();
```

### 11. VisitFrequencyChart
**File:** `visit_frequency_chart.dart`

Line or bar chart component for displaying site visit trends.

**Features:**
- Switchable between bar and line chart
- Date range selector
- Comparison with previous period
- Interactive tooltips
- Smooth animations
- Empty state design

**Usage:**
```dart
VisitFrequencyChart(
  data: [
    SiteVisitData(
      siteId: 'id1',
      siteName: 'Site A',
      visitCount: 25,
    ),
    // More data...
  ],
  comparisonData: previousPeriodData, // Optional
  height: 400,
  chartType: ChartType.bar,
  title: 'Fréquence des visites par site',
  dateRange: currentDateRange,
  onDateRangeChanged: (newRange) {
    // Handle date range change
  },
)
```

**Creating data from report:**
```dart
final chartData = reportData.map((data) {
  return SiteVisitData.fromReportData(data);
}).toList();
```

### 12. ChartViewToggle
**File:** `chart_view_toggle.dart`

Toggle widget for switching between table and chart views with preference persistence.

**Features:**
- Toggle between table and chart views
- Saves user preference using SharedPreferences
- Smooth animations
- Modern design with icons and labels

**Usage:**
```dart
ChartViewToggle(
  initialMode: ViewMode.table,
  preferenceKey: 'supervisor_report_view_mode',
  onModeChanged: (mode) {
    setState(() {
      _viewMode = mode;
    });
  },
)
```

**With AnimatedViewSwitcher:**
```dart
Column(
  children: [
    ChartViewToggle(
      initialMode: _viewMode,
      preferenceKey: 'report_view_mode',
      onModeChanged: (mode) {
        setState(() {
          _viewMode = mode;
        });
      },
    ),
    SizedBox(height: 16),
    AnimatedViewSwitcher(
      currentMode: _viewMode,
      tableView: YourTableWidget(),
      chartView: YourChartWidget(),
    ),
  ],
)
```

### 13. TooltipHelper
**File:** `tooltip_helper.dart`

Utility class for creating consistent, accessible tooltips throughout the application.

**Features:**
- Standardized tooltip styling
- Keyboard shortcut integration
- Screen reader accessibility (ARIA labels)
- Consistent timing and behavior
- Convenience methods for common button types
- Predefined messages and shortcuts

**Usage:**

```dart
// Wrap any widget with a tooltip
TooltipHelper.wrap(
  message: 'Rafraîchir les données',
  shortcut: 'Ctrl+R',
  child: IconButton(
    icon: Icon(Icons.refresh),
    onPressed: _refresh,
  ),
)

// Icon button with tooltip
TooltipHelper.iconButton(
  tooltip: TooltipHelper.refresh,
  shortcut: TooltipHelper.shortcutRefresh,
  icon: Icons.refresh,
  onPressed: _refresh,
)

// Text button with tooltip
TooltipHelper.textButton(
  tooltip: TooltipHelper.clearFilters,
  label: 'Effacer tout',
  icon: Icons.clear_all,
  onPressed: _clearFilters,
)

// Elevated button with tooltip
TooltipHelper.elevatedButton(
  tooltip: TooltipHelper.generateReport,
  label: 'Générer',
  icon: Icons.download,
  onPressed: _generate,
  style: PointageButtonStyles.primary,
)
```

**Standard Messages:**
```dart
// Actions
TooltipHelper.refresh
TooltipHelper.search
TooltipHelper.filter
TooltipHelper.export
TooltipHelper.close
TooltipHelper.cancel
TooltipHelper.confirm
TooltipHelper.save
TooltipHelper.clear
TooltipHelper.clearAll

// Navigation
TooltipHelper.previousPage
TooltipHelper.nextPage
TooltipHelper.back

// Data operations
TooltipHelper.sort
TooltipHelper.selectDate
TooltipHelper.selectDateRange

// Reports
TooltipHelper.generateReport
TooltipHelper.downloadReport

// Filters
TooltipHelper.selectSupervisors
TooltipHelper.selectSites
TooltipHelper.selectZones
TooltipHelper.clearFilters
TooltipHelper.applyFilters

// Feedback
TooltipHelper.retry
TooltipHelper.help
```

**Keyboard Shortcuts:**
```dart
TooltipHelper.shortcutRefresh  // Ctrl+R
TooltipHelper.shortcutSearch   // Ctrl+F
TooltipHelper.shortcutExport   // Ctrl+E
TooltipHelper.shortcutSave     // Ctrl+S
TooltipHelper.shortcutClose    // Esc
```

**Accessibility:**
- All tooltips include semantic labels for screen readers
- Keyboard shortcuts are announced to screen readers
- Consistent wait duration (500ms) and show duration (3s)
- WCAG AA compliant contrast ratios

See `TOOLTIP_IMPLEMENTATION.md` for complete documentation.

## Notes

- All components are responsive and adapt to different screen sizes
- Components follow Material Design 3 principles
- Animations use consistent durations and curves from the design system
- All text is in French to match the application language
- Components are designed to work together as a cohesive system
- Lazy loading components automatically handle scroll detection and loading states
- Chart components use fl_chart package for high-performance visualizations
- Chart view preferences are persisted across sessions using SharedPreferences
- All interactive elements have accessible tooltips with keyboard shortcuts (Requirement 10.4)
