# Tooltip Implementation Guide

## Overview

This document describes the comprehensive tooltip implementation for the Pointage System Redesign. All interactive elements (buttons, icons, links) now have accessible tooltips with keyboard shortcut information where applicable.

## Implementation Details

### TooltipHelper Utility

The `TooltipHelper` class provides:

1. **Consistent Styling**: All tooltips use the same visual style
2. **Keyboard Shortcuts**: Integration of keyboard shortcuts in tooltip messages
3. **Accessibility**: Semantic labels for screen readers
4. **Convenience Methods**: Helper methods for common button types

### Usage Examples

#### Basic Tooltip
```dart
TooltipHelper.wrap(
  message: 'Rafraîchir les données',
  shortcut: 'Ctrl+R',
  child: IconButton(
    icon: Icon(Icons.refresh),
    onPressed: _refresh,
  ),
)
```

#### Icon Button with Tooltip
```dart
TooltipHelper.iconButton(
  tooltip: TooltipHelper.refresh,
  shortcut: TooltipHelper.shortcutRefresh,
  icon: Icons.refresh,
  onPressed: _refresh,
)
```

#### Text Button with Tooltip
```dart
TooltipHelper.textButton(
  tooltip: TooltipHelper.clearFilters,
  label: 'Effacer tout',
  icon: Icons.clear_all,
  onPressed: _clearFilters,
)
```

#### Elevated Button with Tooltip
```dart
TooltipHelper.elevatedButton(
  tooltip: TooltipHelper.generateReport,
  label: 'Générer',
  icon: Icons.download,
  onPressed: _generate,
  style: PointageButtonStyles.primary,
)
```

## Components Updated

### 1. FilterBar
- Search input: "Rechercher (Ctrl+F)"
- Clear search button: "Effacer"
- Supervisor filter: "Sélectionner des superviseurs"
- Site filter: "Sélectionner des sites"
- Zone filter: "Sélectionner des zones"
- Clear all filters: "Effacer tous les filtres"
- Dialog close button: "Fermer (Esc)"
- Deselect all button: "Désélectionner tous les éléments"
- Cancel button: "Annuler (Esc)"
- Apply button: "Appliquer les filtres"

### 2. ModernPointageTable
- Sortable column headers: "Trier par [Column] (croissant/décroissant)"
- Each column shows current sort state in tooltip

### 3. GenerationProgressCard
- Cancel button: "Annuler la génération (Esc)"

### 4. ErrorDisplay
- Retry button (full): "Réessayer (Ctrl+R)"
- Retry button (compact): "Réessayer (Ctrl+R)"

### 5. ChartViewToggle
- Table view button: "Afficher en mode tableau"
- Chart view button: "Afficher en mode graphique"

### 6. ModernDialog
- Dialog action buttons: Contextual tooltips based on button type
  - Primary: "Confirmer: [Label]"
  - Destructive: "Action destructive: [Label]"
  - Default: "[Label]"

### 7. ModernDateRangePicker
- Quick selection chips: "Sélectionner: [Period]"
- Custom range selector: "Sélectionner une période"

## Keyboard Shortcuts

The following keyboard shortcuts are documented in tooltips:

| Shortcut | Action |
|----------|--------|
| Ctrl+F | Focus search input |
| Ctrl+R | Refresh data / Retry |
| Ctrl+E | Export data |
| Ctrl+S | Save |
| Esc | Close dialog / Cancel |
| Ctrl+A | Select all |

## Accessibility Features

### Screen Reader Support

All tooltips include semantic labels:
```dart
Semantics(
  label: message,
  hint: shortcut != null ? 'Raccourci clavier: $shortcut' : null,
  button: true,
  enabled: true,
  child: child,
)
```

### Timing

- **Wait Duration**: 500ms before showing tooltip
- **Show Duration**: 3 seconds
- **Hover Behavior**: Tooltips appear on hover and focus

### Visual Design

- **Background**: Dark semi-transparent (90% opacity)
- **Text**: White, medium weight
- **Padding**: Consistent spacing
- **Border Radius**: Small rounded corners

## Standard Tooltip Messages

The `TooltipHelper` class provides constants for common messages:

```dart
// Actions
TooltipHelper.refresh
TooltipHelper.search
TooltipHelper.filter
TooltipHelper.export
TooltipHelper.exportExcel
TooltipHelper.exportPdf
TooltipHelper.close
TooltipHelper.cancel
TooltipHelper.confirm
TooltipHelper.delete
TooltipHelper.edit
TooltipHelper.add
TooltipHelper.save
TooltipHelper.clear
TooltipHelper.clearAll

// Navigation
TooltipHelper.previousPage
TooltipHelper.nextPage
TooltipHelper.firstPage
TooltipHelper.lastPage
TooltipHelper.back
TooltipHelper.forward

// Data operations
TooltipHelper.sort
TooltipHelper.sortAscending
TooltipHelper.sortDescending
TooltipHelper.selectDate
TooltipHelper.selectDateRange

// Reports
TooltipHelper.generateReport
TooltipHelper.downloadReport
TooltipHelper.previewReport

// Filters
TooltipHelper.selectSupervisors
TooltipHelper.selectSites
TooltipHelper.selectZones
TooltipHelper.clearFilters
TooltipHelper.applyFilters

// Views
TooltipHelper.showChart
TooltipHelper.hideChart
TooltipHelper.toggleView

// Feedback
TooltipHelper.retry
TooltipHelper.help
TooltipHelper.info
TooltipHelper.warning
TooltipHelper.error
TooltipHelper.success
```

## Testing Tooltips

### Manual Testing Checklist

- [ ] Hover over each button/icon to verify tooltip appears
- [ ] Verify tooltip text is clear and descriptive
- [ ] Check keyboard shortcuts are displayed correctly
- [ ] Test with screen reader to verify semantic labels
- [ ] Verify tooltip timing (500ms delay, 3s display)
- [ ] Check tooltip positioning (preferBelow behavior)
- [ ] Test on different screen sizes

### Accessibility Testing

1. **Keyboard Navigation**: Tab through all interactive elements
2. **Screen Reader**: Use NVDA/JAWS to verify announcements
3. **High Contrast**: Verify tooltips are visible in high contrast mode
4. **Zoom**: Test at 200% zoom level

## Future Enhancements

1. **Localization**: Add support for multiple languages
2. **Custom Shortcuts**: Allow users to customize keyboard shortcuts
3. **Tooltip Preferences**: Let users adjust timing and behavior
4. **Rich Tooltips**: Support for images and formatted content
5. **Mobile Support**: Long-press tooltips for touch devices

## Requirements Satisfied

This implementation satisfies requirement **10.4** from the requirements document:

> THE System SHALL provide tooltips for all interactive elements

Key features:
- ✅ All buttons have tooltips
- ✅ All icons have tooltips
- ✅ Keyboard shortcuts included in tooltips
- ✅ Screen reader accessible
- ✅ Consistent styling and behavior
- ✅ Semantic HTML/ARIA labels

## Maintenance

When adding new interactive elements:

1. Import `TooltipHelper`
2. Wrap element with `TooltipHelper.wrap()` or use convenience methods
3. Use standard messages from `TooltipHelper` constants
4. Include keyboard shortcut if applicable
5. Test with keyboard and screen reader
6. Update this documentation if adding new patterns
