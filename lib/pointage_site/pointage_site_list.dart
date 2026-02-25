import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spas_web/administration/home.dart';

import '../pdf/api/pdf_api.dart';
import '../services/export.dart';
import '../services/supervisor.dart';
import '../services/site.dart';
import '../services/zone.dart';
import '../model.dart';
import '../pointage_redesign/providers/pointage_provider.dart';
import '../pointage_redesign/data/pointage_repository.dart';
import '../pointage_redesign/data/cache_manager.dart';
import '../pointage_redesign/models/pointage_exception.dart';
import '../pointage_redesign/presentation/widgets/statistics_card.dart';
import '../pointage_redesign/presentation/widgets/filter_bar.dart';
import '../pointage_redesign/presentation/widgets/modern_pointage_table.dart';
import '../pointage_redesign/presentation/widgets/error_display.dart';
import '../pointage_redesign/presentation/widgets/success_snackbar.dart';
import '../pointage_redesign/presentation/dialogs/modern_dialog.dart';
import '../pointage_redesign/presentation/widgets/modern_date_range_picker.dart';
import '../pointage_redesign/presentation/design_system.dart';

class PointageSiteList extends StatefulWidget {
  const PointageSiteList({super.key});

  @override
  State<PointageSiteList> createState() => _PointageSiteListState();
}

class _PointageSiteListState extends State<PointageSiteList> {
  late PointageProvider _provider;
  DateTime _selectedReportDate = DateTime.now();
  bool _isExporting = false;
  
  // Filter data
  List<Supervisor>? _availableSupervisors;
  List<Site>? _availableSites;
  List<Zone>? _availableZones;

  @override
  void initState() {
    super.initState();
    // Initialize provider
    _provider = PointageProvider(
      repository: PointageRepository(),
      cacheManager: CacheManager(),
    );
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.loadPointages();
      _provider.loadStats();
      _loadFilterData();
    });
  }
  
  /// Load available supervisors, sites, and zones for filtering
  Future<void> _loadFilterData() async {
    try {
      final supervisors = await SupervisorService().allFuture();
      final sites = await SiteService().allActifAsModel();
      final  zones = await ZoneService().allAsModel();
      
      if (mounted) {
        setState(() {
          _availableSupervisors = supervisors;
          _availableSites = sites;
          _availableZones = zones;
        });
      }
    } catch (e) {
      debugPrint('Error loading filter data: $e');
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: PageModel(
        pageIndex: 6,
        title: "Pointages des sites",
        child: Consumer<PointageProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(PointageSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Statistics Card
                  StatisticsCard(
                    stats: provider.stats,
                    isLoading: provider.isLoadingStats,
                  ),
                  
                  const SizedBox(height: PointageSpacing.lg),
                  
                  // Filter Bar
                  FilterBar(
                    filters: provider.filters,
                    onFiltersChanged: (filters) {
                      provider.applyFilters(filters);
                    },
                    resultCount: provider.pagination.totalItems,
                    availableSupervisors: _availableSupervisors,
                    availableSites: _availableSites,
                    availableZones: _availableZones,
                  ),
                  
                  const SizedBox(height: PointageSpacing.lg),
                  
                  // Action Buttons Row
                  _buildActionButtons(context, provider),
                  
                  const SizedBox(height: PointageSpacing.lg),
                  
                  // Error Display
                  if (provider.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: PointageSpacing.lg),
                      child: ErrorDisplay(
                        customMessage: provider.error,
                        onRetry: () => provider.refreshData(),
                        compact: true,
                      ),
                    ),
                  
                  // Pointage Table
                  ModernPointageTable(
                    pointages: provider.pointages,
                    isLoading: provider.isLoading,
                    sortConfig: TableSortConfig(
                      field: provider.sortField,
                      ascending: provider.sortAscending,
                    ),
                    onSort: (config) {
                      provider.changeSort(
                        config.field,
                        ascending: config.ascending,
                      );
                    },
                  ),
                  
                  const SizedBox(height: PointageSpacing.lg),
                  
                  // Pagination Controls
                  _buildPaginationControls(context, provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, PointageProvider provider) {
    return Row(
      children: [
        // Refresh Button
        ElevatedButton.icon(
          onPressed: provider.isLoading ? null : () => provider.refreshData(),
          icon: const Icon(Icons.refresh, size: PointageIconSizes.sm),
          label: const Text('Actualiser'),
          style: PointageButtonStyles.outlined,
        ),
        
        const SizedBox(width: PointageSpacing.sm),
        
        // Date Range Filter Button
        ElevatedButton.icon(
          onPressed: () => _showDateRangeDialog(context, provider),
          icon: const Icon(Icons.calendar_month, size: PointageIconSizes.sm),
          label: const Text('Période'),
          style: PointageButtonStyles.outlined,
        ),
        
        const SizedBox(width: PointageSpacing.sm),
        
        // Export PDF Button
        ElevatedButton.icon(
          onPressed: provider.pointages.isEmpty || _isExporting
              ? null
              : () => _exportToPDF(context, provider),
          icon: _isExporting
              ? const SizedBox(
                  width: PointageIconSizes.sm,
                  height: PointageIconSizes.sm,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.picture_as_pdf, size: PointageIconSizes.sm),
          label: Text(_isExporting ? 'Export en cours...' : 'Exporter PDF'),
          style: PointageButtonStyles.outlined,
        ),
        
        const SizedBox(width: PointageSpacing.sm),
        
        // Reports Button
        ElevatedButton.icon(
          onPressed: () => _showReportsDialog(context),
          icon: const Icon(Icons.assessment, size: PointageIconSizes.sm),
          label: const Text('Rapports'),
          style: PointageButtonStyles.primary,
        ),
        
        const Spacer(),
        
        // Items per page selector
        _buildItemsPerPageSelector(provider),
      ],
    );
  }

  Widget _buildItemsPerPageSelector(PointageProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Lignes par page:',
          style: PointageTextStyles.body2,
        ),
        const SizedBox(width: PointageSpacing.sm),
        DropdownButton<int>(
          value: provider.pagination.itemsPerPage,
          items: [10, 20, 50, 100].map((value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(value.toString()),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              provider.changeItemsPerPage(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPaginationControls(BuildContext context, PointageProvider provider) {
    final pagination = provider.pagination;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // First page button
        IconButton(
          onPressed: pagination.currentPage > 1 && !provider.isLoading
              ? () => provider.goToPage(1)
              : null,
          icon: const Icon(Icons.first_page),
          tooltip: 'Première page',
        ),
        
        // Previous page button
        IconButton(
          onPressed: pagination.canGoPrevious && !provider.isLoading
              ? () => provider.loadPreviousPage()
              : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Page précédente',
        ),
        
        const SizedBox(width: PointageSpacing.md),
        
        // Page info
        Text(
          'Page ${pagination.currentPage} sur ${pagination.totalPages}',
          style: PointageTextStyles.body2,
        ),
        
        const SizedBox(width: PointageSpacing.md),
        
        // Next page button
        IconButton(
          onPressed: pagination.canGoNext && !provider.isLoading
              ? () => provider.loadNextPage()
              : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Page suivante',
        ),
        
        // Last page button
        IconButton(
          onPressed: pagination.currentPage < pagination.totalPages && !provider.isLoading
              ? () => provider.goToPage(pagination.totalPages)
              : null,
          icon: const Icon(Icons.last_page),
          tooltip: 'Dernière page',
        ),
      ],
    );
  }

  void _showDateRangeDialog(BuildContext context, PointageProvider provider) {
    DateTimeRange? selectedRange = provider.filters.dateRange;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: PointageCardDecorations.elevated,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      const Padding(
                        padding: EdgeInsets.all(PointageSpacing.lg),
                        child: Text(
                          'Sélectionner une période',
                          style: PointageTextStyles.headline3,
                        ),
                      ),
                      
                      // Divider
                      const Divider(height: 1, color: PointageColors.divider),
                      
                      // Content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(PointageSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Choisissez une plage de dates pour filtrer les pointages',
                                style: PointageTextStyles.body2.copyWith(
                                  color: PointageColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: PointageSpacing.md),
                              ModernDateRangePicker(
                                initialRange: selectedRange,
                                onRangeSelected: (range) {
                                  setDialogState(() {
                                    selectedRange = range;
                                  });
                                },
                              ),
                              if (selectedRange != null) ...[
                                const SizedBox(height: PointageSpacing.md),
                                Container(
                                  padding: const EdgeInsets.all(PointageSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: PointageColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(PointageBorderRadius.sm),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        size: PointageIconSizes.sm,
                                        color: PointageColors.primary,
                                      ),
                                      const SizedBox(width: PointageSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          'Période sélectionnée: ${selectedRange!.duration.inDays + 1} jour(s)',
                                          style: PointageTextStyles.caption.copyWith(
                                            color: PointageColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      // Actions
                      const Divider(height: 1, color: PointageColors.divider),
                      Padding(
                        padding: const EdgeInsets.all(PointageSpacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              style: PointageButtonStyles.outlined,
                              child: const Text('Annuler'),
                            ),
                            const SizedBox(width: PointageSpacing.sm),
                            ElevatedButton(
                              onPressed: selectedRange != null
                                  ? () {
                                      final updatedFilters = provider.filters.copyWith(
                                        dateRange: selectedRange,
                                      );
                                      provider.applyFilters(updatedFilters);
                                      Navigator.of(dialogContext).pop();
                                      SuccessSnackbar.show(
                                        context,
                                        message: 'Période mise à jour',
                                        icon: Icons.calendar_today,
                                      );
                                    }
                                  : null,
                              style: PointageButtonStyles.primary,
                              child: const Text('Appliquer'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReportsDialog(BuildContext context) {
    DateTimeRange? selectedRange;
    
    ModernDialog.show(
      context: context,
      title: 'Générer un rapport',
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sélectionnez une période pour générer un rapport de pointage',
                style: PointageTextStyles.body2.copyWith(
                  color: PointageColors.textSecondary,
                ),
              ),
              const SizedBox(height: PointageSpacing.md),
              
              // Date Range Picker
              ModernDateRangePicker(
                initialRange: selectedRange ?? DateTimeRange(
                  start: _selectedReportDate,
                  end: _selectedReportDate,
                ),
                onRangeSelected: (range) {
                  setState(() {
                    selectedRange = range;
                    _selectedReportDate = range.start;
                  });
                },
              ),
              
              // Validation feedback
              if (selectedRange != null) ...[
                const SizedBox(height: PointageSpacing.md),
                Container(
                  padding: const EdgeInsets.all(PointageSpacing.sm),
                  decoration: BoxDecoration(
                    color: PointageColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(PointageBorderRadius.sm),
                    border: Border.all(
                      color: PointageColors.success.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: PointageIconSizes.sm,
                        color: PointageColors.success,
                      ),
                      const SizedBox(width: PointageSpacing.sm),
                      Expanded(
                        child: Text(
                          'Période valide: ${selectedRange!.duration.inDays + 1} jour(s)',
                          style: PointageTextStyles.caption.copyWith(
                            color: PointageColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: PointageSpacing.lg),
              
              // Divider
              Divider(
                color: PointageColors.textSecondary.withValues(alpha: 0.2),
                height: 1,
              ),
              
              const SizedBox(height: PointageSpacing.md),
              
              Text(
                'Type de rapport',
                style: PointageTextStyles.headline4.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: PointageSpacing.sm),
              
              // Report buttons with improved styling
              ElevatedButton.icon(
                onPressed: selectedRange != null
                    ? () {
                        Navigator.of(context).pop();
                        context.go('/pointages/spm', extra: _selectedReportDate);
                      }
                    : null,
                icon: const Icon(Icons.people, size: PointageIconSizes.md),
                label: const Text('Rapport par superviseur'),
                style: PointageButtonStyles.primary.copyWith(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(
                      horizontal: PointageSpacing.lg,
                      vertical: PointageSpacing.md,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: PointageSpacing.sm),
              
              ElevatedButton.icon(
                onPressed: selectedRange != null
                    ? () {
                        Navigator.of(context).pop();
                        context.go('/pointages/smp', extra: _selectedReportDate);
                      }
                    : null,
                icon: const Icon(Icons.location_on, size: PointageIconSizes.md),
                label: const Text('Rapport par site'),
                style: PointageButtonStyles.outlined.copyWith(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(
                      horizontal: PointageSpacing.lg,
                      vertical: PointageSpacing.md,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        DialogAction(
          label: 'Fermer',
          onPressed: () => Navigator.of(context).pop(),
          isPrimary: false,
        ),
      ],
    );
  }

  Future<void> _exportToPDF(BuildContext context, PointageProvider provider) async {
    if (!mounted || _isExporting) return;
    
    // Store context for async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Show loading state
      setState(() {
        _isExporting = true;
      });
      
      InfoSnackbar.show(
        context,
        message: 'Génération du PDF en cours...',
        duration: const Duration(seconds: 2),
      );
      
      // Export to PDF using existing service
      final document = await PointageSiteListToPDF.export(provider.pointages);
      await PdfApi.openFile(document);
      
      // Clear loading state
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
      
      // Show success notification
      if (!mounted) return;
      
      final fileName = 'pointages_${DateTime.now().toString().replaceAll(RegExp(r'[:\s]'), '_').substring(0, 19)}.pdf';
      SuccessSnackbar.showDownloadSuccess(
        context,
        fileName: fileName,
      );
    } catch (e, stackTrace) {
      // Clear loading state
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
      
      // Log error for debugging
      debugPrint('PDF export error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Create appropriate exception
      final exception = PointageException.generationFailed(
        message: 'Échec de l\'export PDF',
        originalError: e,
        stackTrace: stackTrace,
      );
      
      // Show error with retry option
      if (!mounted) return;
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: PointageIconSizes.md,
              ),
              const SizedBox(width: PointageSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Erreur d\'export PDF',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: PointageSpacing.xs),
                    Text(
                      exception.userMessage,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: PointageColors.error,
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: () {
              _exportToPDF(context, provider);
            },
          ),
        ),
      );
    }
  }
}

