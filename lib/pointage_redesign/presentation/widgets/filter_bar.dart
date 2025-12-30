import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/pointage_filters.dart';
import '../../../model.dart';
import '../design_system.dart';
import 'tooltip_helper.dart';

/// Filter bar component with search, filter chips, and dropdowns
class FilterBar extends StatefulWidget {
  final PointageFilters filters;
  final Function(PointageFilters) onFiltersChanged;
  final int? resultCount;
  final bool isLoading;
  final List<Supervisor>? availableSupervisors;
  final List<ZoneMember>? availableZoneMembers;
  final List<Site>? availableSites;
  final List<Zone>? availableZones;
  final bool showZoneMemberFilter;
  final bool showZoneFilter;
  final String? zoneMemberLabel;
  final bool showQuickFilters;

  const FilterBar({
    Key? key,
    required this.filters,
    required this.onFiltersChanged,
    this.resultCount,
    this.isLoading = false,
    this.availableSupervisors,
    this.availableZoneMembers,
    this.availableSites,
    this.availableZones,
    this.showZoneMemberFilter = false,
    this.showZoneFilter = false,
    this.zoneMemberLabel,
    this.showQuickFilters = true,
  }) : super(key: key);

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.filters.searchQuery ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Debounce search input
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final updatedFilters = widget.filters.copyWith(
        searchQuery: value.isEmpty ? null : value,
      );
      widget.onFiltersChanged(updatedFilters);
    });
  }

  void _clearAllFilters() {
    _searchController.clear();
    widget.onFiltersChanged(PointageFilters());
  }

  void _removeFilter(String filterType) {
    PointageFilters updatedFilters;
    
    switch (filterType) {
      case 'dateRange':
        updatedFilters = widget.filters.copyWith(clearDateRange: true);
        break;
      case 'supervisors':
        updatedFilters = widget.filters.copyWith(clearSupervisorIds: true);
        break;
      case 'sites':
        updatedFilters = widget.filters.copyWith(clearSiteIds: true);
        break;
      case 'zones':
        updatedFilters = widget.filters.copyWith(clearZoneIds: true);
        break;
      default:
        return;
    }
    
    widget.onFiltersChanged(updatedFilters);
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (widget.filters.dateRange != null) count++;
    if (widget.filters.supervisorIds != null && widget.filters.supervisorIds!.isNotEmpty) count++;
    if (widget.filters.siteIds != null && widget.filters.siteIds!.isNotEmpty) count++;
    if (widget.filters.zoneIds != null && widget.filters.zoneIds!.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final activeFilterCount = _getActiveFilterCount();
    
    return Container(
      decoration: PointageCardDecorations.standard,
      padding: const EdgeInsets.all(PointageSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick filters row
          if (widget.showQuickFilters) ...[
            _buildQuickFilters(),
            const SizedBox(height: PointageSpacing.md),
          ],
          
          // Search bar and filter buttons
          Row(
            children: [
              // Search input
              Expanded(
                child: Tooltip(
                  message: TooltipHelper.withShortcut(
                    TooltipHelper.search,
                    TooltipHelper.shortcutSearch,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: PointageInputDecorations.standard(
                      hintText: 'Rechercher par superviseur, site...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: PointageColors.textSecondary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? TooltipHelper.iconButton(
                              tooltip: TooltipHelper.clear,
                              icon: Icons.clear,
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: PointageSpacing.md),
              
              // Filter dropdowns
              if (widget.availableSupervisors != null && !widget.showZoneMemberFilter)
                Tooltip(
                  message: TooltipHelper.selectSupervisors,
                  child: _FilterDropdownButton(
                    icon: Icons.person_outline,
                    label: 'Superviseurs',
                    count: widget.filters.supervisorIds?.length,
                    onTap: () => _showSupervisorFilter(context),
                  ),
                ),
              
              // Zone member filter (for zone pointages)
              if (widget.availableZoneMembers != null && widget.showZoneMemberFilter)
                Tooltip(
                  message: 'Sélectionner des ${widget.zoneMemberLabel ?? 'chefs de zone'}',
                  child: _FilterDropdownButton(
                    icon: Icons.person_outline,
                    label: widget.zoneMemberLabel ?? 'Chefs de zone',
                    count: widget.filters.supervisorIds?.length,
                    onTap: () => _showZoneMemberFilter(context),
                  ),
                ),
              
              const SizedBox(width: PointageSpacing.sm),
              
              if (widget.availableSites != null)
                Tooltip(
                  message: TooltipHelper.selectSites,
                  child: _FilterDropdownButton(
                    icon: Icons.location_on_outlined,
                    label: 'Sites',
                    count: widget.filters.siteIds?.length,
                    onTap: () => _showSiteFilter(context),
                  ),
                ),
              
              const SizedBox(width: PointageSpacing.sm),
              
              if (widget.availableZones != null && widget.showZoneFilter)
                Tooltip(
                  message: TooltipHelper.selectZones,
                  child: _FilterDropdownButton(
                    icon: Icons.map_outlined,
                    label: 'Zones',
                    count: widget.filters.zoneIds?.length,
                    onTap: () => _showZoneFilter(context),
                  ),
                ),
              
              const SizedBox(width: PointageSpacing.sm),
              
              // Clear all button
              if (activeFilterCount > 0)
                TooltipHelper.textButton(
                  tooltip: TooltipHelper.clearFilters,
                  label: 'Effacer tout',
                  icon: Icons.clear_all,
                  onPressed: _clearAllFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: PointageColors.error,
                  ),
                ),
            ],
          ),
          
          // Active filter chips
          if (activeFilterCount > 0) ...[
            const SizedBox(height: PointageSpacing.md),
            Wrap(
              spacing: PointageSpacing.sm,
              runSpacing: PointageSpacing.sm,
              children: _buildFilterChips(),
            ),
          ],
          
          // Result count
          if (widget.resultCount != null) ...[
            const SizedBox(height: PointageSpacing.md),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: PointageIconSizes.xs,
                  color: PointageColors.textSecondary,
                ),
                const SizedBox(width: PointageSpacing.xs),
                Text(
                  '${widget.resultCount} résultat${widget.resultCount! > 1 ? 's' : ''} trouvé${widget.resultCount! > 1 ? 's' : ''}',
                  style: PointageTextStyles.caption,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build quick filter chips for common date ranges
  Widget _buildQuickFilters() {
    return Row(
      children: [
        Text(
          'Filtres rapides:',
          style: PointageTextStyles.body2.copyWith(
            color: PointageColors.textSecondary,
          ),
        ),
        const SizedBox(width: PointageSpacing.md),
        _QuickFilterChip(
          label: "Aujourd'hui",
          isSelected: widget.filters.isTodayFilter,
          onTap: () {
            widget.onFiltersChanged(PointageFilters.today());
          },
        ),
        const SizedBox(width: PointageSpacing.sm),
        _QuickFilterChip(
          label: 'Cette semaine',
          isSelected: widget.filters.isThisWeekFilter,
          onTap: () {
            widget.onFiltersChanged(PointageFilters.thisWeek());
          },
        ),
        const SizedBox(width: PointageSpacing.sm),
        _QuickFilterChip(
          label: 'Ce mois',
          isSelected: widget.filters.isThisMonthFilter,
          onTap: () {
            widget.onFiltersChanged(PointageFilters.thisMonth());
          },
        ),
      ],
    );
  }

  List<Widget> _buildFilterChips() {
    final chips = <Widget>[];
    
    // Date range chip
    if (widget.filters.dateRange != null) {
      chips.add(_FilterChip(
        label: 'Période: ${_formatDateRange(widget.filters.dateRange!)}',
        onRemove: () => _removeFilter('dateRange'),
      ));
    }
    
    // Supervisors/Zone Members chip
    if (widget.filters.supervisorIds != null && widget.filters.supervisorIds!.isNotEmpty) {
      final label = widget.showZoneMemberFilter
          ? '${widget.filters.supervisorIds!.length} ${widget.zoneMemberLabel?.toLowerCase() ?? 'chef de zone'}${widget.filters.supervisorIds!.length > 1 ? 's' : ''}'
          : '${widget.filters.supervisorIds!.length} superviseur${widget.filters.supervisorIds!.length > 1 ? 's' : ''}';
      chips.add(_FilterChip(
        label: label,
        onRemove: () => _removeFilter('supervisors'),
      ));
    }
    
    // Sites chip
    if (widget.filters.siteIds != null && widget.filters.siteIds!.isNotEmpty) {
      chips.add(_FilterChip(
        label: '${widget.filters.siteIds!.length} site${widget.filters.siteIds!.length > 1 ? 's' : ''}',
        onRemove: () => _removeFilter('sites'),
      ));
    }
    
    // Zones chip
    if (widget.filters.zoneIds != null && widget.filters.zoneIds!.isNotEmpty) {
      chips.add(_FilterChip(
        label: '${widget.filters.zoneIds!.length} zone${widget.filters.zoneIds!.length > 1 ? 's' : ''}',
        onRemove: () => _removeFilter('zones'),
      ));
    }
    
    return chips;
  }

  String _formatDateRange(DateTimeRange range) {
    final start = '${range.start.day}/${range.start.month}/${range.start.year}';
    final end = '${range.end.day}/${range.end.month}/${range.end.year}';
    return '$start - $end';
  }

  void _showSupervisorFilter(BuildContext context) {
    if (widget.availableSupervisors == null) return;
    
    _showMultiSelectDialog<Supervisor>(
      context: context,
      title: 'Sélectionner des superviseurs',
      items: widget.availableSupervisors!,
      selectedIds: widget.filters.supervisorIds ?? [],
      getItemId: (supervisor) => supervisor.UID,
      getItemLabel: (supervisor) => '${supervisor.firstName} ${supervisor.lastName}',
      onConfirm: (selectedIds) {
        final updatedFilters = widget.filters.copyWith(
          supervisorIds: selectedIds.isEmpty ? null : selectedIds,
        );
        widget.onFiltersChanged(updatedFilters);
      },
    );
  }

  void _showZoneMemberFilter(BuildContext context) {
    if (widget.availableZoneMembers == null) return;
    
    _showMultiSelectDialog<ZoneMember>(
      context: context,
      title: 'Sélectionner des ${widget.zoneMemberLabel ?? 'chefs de zone'}',
      items: widget.availableZoneMembers!,
      selectedIds: widget.filters.supervisorIds ?? [],
      getItemId: (zoneMember) => zoneMember.UID,
      getItemLabel: (zoneMember) => '${zoneMember.firstName} ${zoneMember.lastName}',
      onConfirm: (selectedIds) {
        final updatedFilters = widget.filters.copyWith(
          supervisorIds: selectedIds.isEmpty ? null : selectedIds,
        );
        widget.onFiltersChanged(updatedFilters);
      },
    );
  }

  void _showSiteFilter(BuildContext context) {
    if (widget.availableSites == null) return;
    
    _showMultiSelectDialog<Site>(
      context: context,
      title: 'Sélectionner des sites',
      items: widget.availableSites!,
      selectedIds: widget.filters.siteIds ?? [],
      getItemId: (site) => site.UID,
      getItemLabel: (site) => site.name,
      onConfirm: (selectedIds) {
        final updatedFilters = widget.filters.copyWith(
          siteIds: selectedIds.isEmpty ? null : selectedIds,
        );
        widget.onFiltersChanged(updatedFilters);
      },
    );
  }

  void _showZoneFilter(BuildContext context) {
    if (widget.availableZones == null) return;
    
    _showMultiSelectDialog<Zone>(
      context: context,
      title: 'Sélectionner des zones',
      items: widget.availableZones!,
      selectedIds: widget.filters.zoneIds ?? [],
      getItemId: (zone) => zone.codeZone,
      getItemLabel: (zone) => zone.name,
      onConfirm: (selectedIds) {
        final updatedFilters = widget.filters.copyWith(
          zoneIds: selectedIds.isEmpty ? null : selectedIds,
        );
        widget.onFiltersChanged(updatedFilters);
      },
    );
  }
  
  /// Show a multi-select dialog for filtering
  void _showMultiSelectDialog<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required List<String> selectedIds,
    required String Function(T) getItemId,
    required String Function(T) getItemLabel,
    required Function(List<String>) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => _MultiSelectDialog<T>(
        title: title,
        items: items,
        selectedIds: selectedIds,
        getItemId: getItemId,
        getItemLabel: getItemLabel,
        onConfirm: onConfirm,
      ),
    );
  }
}

/// Filter dropdown button
class _FilterDropdownButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback onTap;

  const _FilterDropdownButton({
    Key? key,
    required this.icon,
    required this.label,
    this.count,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_FilterDropdownButton> createState() => _FilterDropdownButtonState();
}

class _FilterDropdownButtonState extends State<_FilterDropdownButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.count != null && widget.count! > 0;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: PointageBorderRadius.medium,
        child: AnimatedContainer(
          duration: PointageAnimations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: PointageSpacing.md,
            vertical: PointageSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: hasSelection
                ? PointageColors.primary.withValues(alpha: 0.1)
                : (_isHovered
                    ? PointageColors.background
                    : Colors.transparent),
            borderRadius: PointageBorderRadius.medium,
            border: Border.all(
              color: hasSelection
                  ? PointageColors.primary
                  : (_isHovered
                      ? PointageColors.divider
                      : PointageColors.divider),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: PointageIconSizes.sm,
                color: hasSelection
                    ? PointageColors.primary
                    : PointageColors.textSecondary,
              ),
              const SizedBox(width: PointageSpacing.xs),
              Text(
                widget.label,
                style: PointageTextStyles.body2.copyWith(
                  color: hasSelection
                      ? PointageColors.primary
                      : PointageColors.textPrimary,
                ),
              ),
              if (hasSelection) ...[
                const SizedBox(width: PointageSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PointageSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: PointageColors.primary,
                    borderRadius: PointageBorderRadius.small,
                  ),
                  child: Text(
                    widget.count.toString(),
                    style: PointageTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: PointageSpacing.xs),
              Icon(
                Icons.arrow_drop_down,
                size: PointageIconSizes.sm,
                color: hasSelection
                    ? PointageColors.primary
                    : PointageColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filter chip showing active filter
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({
    Key? key,
    required this.label,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: PointageTextStyles.body2.copyWith(
          color: PointageColors.primary,
        ),
      ),
      deleteIcon: const Icon(
        Icons.close,
        size: PointageIconSizes.xs,
      ),
      onDeleted: onRemove,
      backgroundColor: PointageColors.primary.withValues(alpha: 0.1),
      deleteIconColor: PointageColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: PointageBorderRadius.medium,
        side: const BorderSide(color: PointageColors.primary),
      ),
    );
  }
}

/// Quick filter chip with glass smooth hover effect
class _QuickFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickFilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_QuickFilterChip> createState() => _QuickFilterChipState();
}

class _QuickFilterChipState extends State<_QuickFilterChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: PointageAnimations.fast,
          curve: PointageAnimations.defaultCurve,
          padding: const EdgeInsets.symmetric(
            horizontal: PointageSpacing.md,
            vertical: PointageSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? PointageColors.primary
                : (_isHovered
                    ? PointageColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent),
            borderRadius: PointageBorderRadius.medium,
            border: Border.all(
              color: widget.isSelected
                  ? PointageColors.primary
                  : (_isHovered
                      ? PointageColors.primary
                      : PointageColors.divider),
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: PointageColors.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isSelected) ...[
                const Icon(
                  Icons.check,
                  size: PointageIconSizes.xs,
                  color: Colors.white,
                ),
                const SizedBox(width: PointageSpacing.xs),
              ],
              Text(
                widget.label,
                style: PointageTextStyles.body2.copyWith(
                  color: widget.isSelected
                      ? Colors.white
                      : (_isHovered
                          ? PointageColors.primary
                          : PointageColors.textPrimary),
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Multi-select dialog for filtering
class _MultiSelectDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final List<String> selectedIds;
  final String Function(T) getItemId;
  final String Function(T) getItemLabel;
  final Function(List<String>) onConfirm;

  const _MultiSelectDialog({
    Key? key,
    required this.title,
    required this.items,
    required this.selectedIds,
    required this.getItemId,
    required this.getItemLabel,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late Set<String> _selectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }

  List<T> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    
    return widget.items.where((item) {
      final label = widget.getItemLabel(item).toLowerCase();
      return label.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: PointageBorderRadius.large,
      ),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(PointageSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: PointageTextStyles.headline2,
                  ),
                ),
                TooltipHelper.iconButton(
                  tooltip: TooltipHelper.close,
                  shortcut: TooltipHelper.shortcutClose,
                  icon: Icons.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const SizedBox(height: PointageSpacing.md),
            
            // Search bar
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: PointageInputDecorations.standard(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            
            const SizedBox(height: PointageSpacing.md),
            
            // Selection info
            Container(
              padding: const EdgeInsets.all(PointageSpacing.sm),
              decoration: BoxDecoration(
                color: PointageColors.primary.withValues(alpha: 0.1),
                borderRadius: PointageBorderRadius.medium,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: PointageIconSizes.sm,
                    color: PointageColors.primary,
                  ),
                  const SizedBox(width: PointageSpacing.sm),
                  Text(
                    '${_selectedIds.length} élément${_selectedIds.length > 1 ? 's' : ''} sélectionné${_selectedIds.length > 1 ? 's' : ''}',
                    style: PointageTextStyles.body2.copyWith(
                      color: PointageColors.primary,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedIds.isNotEmpty)
                    TooltipHelper.textButton(
                      tooltip: 'Désélectionner tous les éléments',
                      label: 'Tout désélectionner',
                      onPressed: () {
                        setState(() {
                          _selectedIds.clear();
                        });
                      },
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: PointageSpacing.md),
            
            // Items list
            Flexible(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun résultat trouvé',
                        style: PointageTextStyles.body2.copyWith(
                          color: PointageColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final itemId = widget.getItemId(item);
                        final isSelected = _selectedIds.contains(itemId);
                        
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedIds.add(itemId);
                              } else {
                                _selectedIds.remove(itemId);
                              }
                            });
                          },
                          title: Text(
                            widget.getItemLabel(item),
                            style: PointageTextStyles.body1,
                          ),
                          activeColor: PointageColors.primary,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: PointageSpacing.lg),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TooltipHelper.textButton(
                  tooltip: TooltipHelper.cancel,
                  shortcut: TooltipHelper.shortcutClose,
                  label: 'Annuler',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: PointageSpacing.sm),
                TooltipHelper.elevatedButton(
                  tooltip: TooltipHelper.applyFilters,
                  label: 'Appliquer',
                  onPressed: () {
                    widget.onConfirm(_selectedIds.toList());
                    Navigator.of(context).pop();
                  },
                  style: PointageButtonStyles.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
