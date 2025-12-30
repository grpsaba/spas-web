import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/error_logs/models/error_log_model.dart';
import 'package:spas_web/error_logs/providers/error_log_provider.dart';
import 'package:spas_web/error_logs/widgets/error_type_badge.dart';
import 'package:spas_web/error_logs/widgets/status_filter_badges.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';
import 'package:spas_web/services/authentication.dart';
import 'package:spas_web/helpers/download_helper.dart';

class ErrorLogsListPage extends StatefulWidget {
  const ErrorLogsListPage({super.key});

  @override
  State<ErrorLogsListPage> createState() => _ErrorLogsListPageState();
}

class _ErrorLogsListPageState extends State<ErrorLogsListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ErrorLogProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ErrorLogProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 18,
      title: "Erreurs de pointage",
      child: Consumer<ErrorLogProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildHeader(context, provider),
              _buildFilters(context, provider),
              Expanded(
                child: _buildContent(context, provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ErrorLogProvider provider) {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.md),
      decoration: BoxDecoration(
        color: PointageColors.surface,
        boxShadow: PointageShadows.sm,
      ),
      child: Row(
        children: [
          // Stats summary
          _buildStatChip(
            'Total',
            provider.stats.total.toString(),
            PointageColors.primary,
          ),
          const SizedBox(width: PointageSpacing.sm),
          _buildStatChip(
            'Non résolus',
            provider.stats.unresolved.toString(),
            PointageColors.error,
          ),
          const SizedBox(width: PointageSpacing.sm),
          _buildStatChip(
            'Résolus',
            provider.stats.resolved.toString(),
            PointageColors.success,
          ),
          const Spacer(),
          // Search bar
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchController,
              decoration: PointageInputDecorations.standard(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => provider.setSearchQuery(value),
            ),
          ),
          const SizedBox(width: PointageSpacing.md),
          // Actions
          if (provider.hasSelection) ...[
            ElevatedButton.icon(
              onPressed: () => _resolveSelected(context, provider),
              icon: const Icon(Icons.check_circle, size: 18),
              label: Text('Résoudre (${provider.selectedCount})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PointageColors.success,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: PointageSpacing.sm),
          ],
          IconButton(
            onPressed: () => _exportCsv(context, provider),
            icon: const Icon(Icons.download),
            tooltip: 'Exporter CSV',
          ),
          IconButton(
            onPressed: provider.isLoading ? null : () => provider.refresh(),
            icon: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.md,
        vertical: PointageSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: PointageTextStyles.headline4.copyWith(color: color),
          ),
          const SizedBox(width: PointageSpacing.xs),
          Text(
            label,
            style: PointageTextStyles.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, ErrorLogProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.md,
        vertical: PointageSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: PointageColors.background,
        border: Border(
          bottom: BorderSide(color: PointageColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filter badges
          StatusFilterBadges(
            currentFilter: provider.filters.isResolved,
            onFilterChanged: (value) => provider.setResolvedFilter(value),
          ),
          const SizedBox(height: PointageSpacing.sm),
          // Error type badges
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildErrorTypeBadge(
                  context,
                  provider,
                  null,
                  'Tous types',
                  Icons.all_inclusive,
                  PointageColors.textSecondary,
                ),
                const SizedBox(width: PointageSpacing.xs),
                ...ErrorTypeConfig.allErrorTypes.map((type) {
                  final count = provider.stats.byErrorType[type] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: PointageSpacing.xs),
                    child: _buildErrorTypeBadge(
                      context,
                      provider,
                      type,
                      '${ErrorTypeConfig.getLabel(type)} ($count)',
                      ErrorTypeConfig.getIcon(type),
                      ErrorTypeConfig.getColor(type),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorTypeBadge(
    BuildContext context,
    ErrorLogProvider provider,
    String? type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = provider.filters.errorType == type;
    return InkWell(
      onTap: () => provider.setErrorTypeFilter(type),
      borderRadius: PointageBorderRadius.medium,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PointageSpacing.sm,
          vertical: PointageSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: PointageBorderRadius.medium,
          border: Border.all(
            color: isSelected ? color : PointageColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: PointageSpacing.xs),
            Text(
              label,
              style: PointageTextStyles.caption.copyWith(
                color: isSelected ? color : PointageColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ErrorLogProvider provider) {
    if (provider.isLoading && provider.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: PointageColors.error),
            const SizedBox(height: PointageSpacing.md),
            Text(provider.error!, style: PointageTextStyles.body1),
            const SizedBox(height: PointageSpacing.md),
            ElevatedButton(
              onPressed: () => provider.refresh(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final logs = provider.filteredLogs;

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: PointageColors.success),
            const SizedBox(height: PointageSpacing.md),
            Text(
              'Aucune erreur trouvée',
              style: PointageTextStyles.headline4,
            ),
            if (provider.filters.hasActiveFilters) ...[
              const SizedBox(height: PointageSpacing.sm),
              TextButton(
                onPressed: () => provider.clearFilters(),
                child: const Text('Effacer les filtres'),
              ),
            ],
          ],
        ),
      );
    }

    return _buildTable(context, provider, logs);
  }

  Widget _buildTable(
      BuildContext context, ErrorLogProvider provider, List<ErrorLog> logs) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PointageSpacing.md,
              vertical: PointageSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: PointageColors.background,
              border: Border(
                bottom: BorderSide(color: PointageColors.divider),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Checkbox(
                    value: provider.selectedIds.length == logs.length &&
                        logs.isNotEmpty,
                    tristate: true,
                    onChanged: (value) {
                      if (value == true) {
                        provider.selectAll();
                      } else {
                        provider.clearSelection();
                      }
                    },
                  ),
                ),
                _tableHeader('Date', flex: 2),
                _tableHeader('Type', flex: 2),
                _tableHeader('Superviseur', flex: 2),
                _tableHeader('Site/Agent', flex: 2),
                _tableHeader('Message', flex: 3),
                _tableHeader('Actions', flex: 1),
              ],
            ),
          ),
          // Table rows
          ...logs.map((log) => _buildTableRow(context, provider, log)),
          // Loading more indicator
          if (provider.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(PointageSpacing.md),
              child: CircularProgressIndicator(),
            ),
          // End of list
          if (!provider.hasMore && logs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(PointageSpacing.md),
              child: Text(
                'Fin de la liste (${logs.length} erreurs)',
                style: PointageTextStyles.caption,
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: PointageTextStyles.label.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTableRow(
      BuildContext context, ErrorLogProvider provider, ErrorLog log) {
    final isSelected = provider.selectedIds.contains(log.id);

    return InkWell(
      onTap: () => context.go('/errorlogs/detail', extra: log),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PointageSpacing.md,
          vertical: PointageSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? PointageColors.primary.withValues(alpha: 0.05)
              : log.isResolved
                  ? PointageColors.success.withValues(alpha: 0.03)
                  : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: PointageColors.divider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Checkbox(
                value: isSelected,
                onChanged: log.isResolved
                    ? null
                    : (value) => provider.toggleSelection(log.id),
              ),
            ),
            // Date
            Expanded(
              flex: 2,
              child: Text(
                _formatDate(log.timestamp),
                style: PointageTextStyles.body2,
              ),
            ),
            // Type badge
            Expanded(
              flex: 2,
              child: ErrorTypeBadge(errorType: log.errorType),
            ),
            // Supervisor
            Expanded(
              flex: 2,
              child: Text(
                log.supervisorName,
                style: PointageTextStyles.body2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Site/Agent
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(
                    log.type == 'pointing_site'
                        ? Icons.location_on
                        : Icons.person,
                    size: 16,
                    color: PointageColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      log.entityName,
                      style: PointageTextStyles.body2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Message
            Expanded(
              flex: 3,
              child: Text(
                log.customMessage ?? '-',
                style: PointageTextStyles.body2,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            // Actions
            Expanded(
              flex: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (log.isResolved)
                    Tooltip(
                      message: 'Résolu par ${log.resolvedBy ?? "N/A"}',
                      child: Icon(
                        Icons.check_circle,
                        color: PointageColors.success,
                        size: 20,
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () => _resolveSingle(context, provider, log),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      tooltip: 'Marquer comme résolu',
                      color: PointageColors.success,
                    ),
                  IconButton(
                    onPressed: () => context.go('/errorlogs/detail', extra: log),
                    icon: const Icon(Icons.visibility, size: 20),
                    tooltip: 'Voir détails',
                    color: PointageColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _resolveSingle(
      BuildContext context, ErrorLogProvider provider, ErrorLog log) async {
    final manager = AuthService.currentManager;
    if (manager == null) return;

    final resolvedBy = '${manager.firstName} ${manager.lastName}';
    final success = await provider.markAsResolved(log.id, resolvedBy);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Erreur marquée comme résolue'
              : 'Échec de la résolution'),
          backgroundColor: success ? PointageColors.success : PointageColors.error,
        ),
      );
    }
  }

  Future<void> _resolveSelected(
      BuildContext context, ErrorLogProvider provider) async {
    final manager = AuthService.currentManager;
    if (manager == null) return;

    final resolvedBy = '${manager.firstName} ${manager.lastName}';
    final ids = provider.selectedIds.toList();
    final count = await provider.markMultipleAsResolved(ids, resolvedBy);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count erreur(s) marquée(s) comme résolue(s)'),
          backgroundColor: PointageColors.success,
        ),
      );
    }
  }

  void _exportCsv(BuildContext context, ErrorLogProvider provider) {
    final csv = provider.exportToCsv();
    final filename =
        'erreurs_pointage_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
    
    DownloadHelper.downloadText(csv, filename);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export CSV téléchargé'),
        backgroundColor: PointageColors.success,
      ),
    );
  }
}
