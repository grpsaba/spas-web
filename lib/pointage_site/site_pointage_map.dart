import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/providers/home_provider.dart';
import 'package:spas_web/pointage_redesign/providers/report_generator.dart';
import 'package:spas_web/pointage_redesign/models/report_models.dart';
import 'package:spas_web/pointage_redesign/models/pointage_exception.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/generation_progress_card.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/modern_date_range_picker.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/error_display.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/success_snackbar.dart';
import 'package:spas_web/pointage_redesign/presentation/dialogs/modern_dialog.dart';
import 'dart:html' as html;

/// Refactored ReportSupervisorPage with modern UI and optimized report generation
/// 
/// Requirements: 1.2, 1.5, 2.1, 2.2, 3.1, 4.1, 4.2, 4.3, 4.5, 5.2, 6.1, 6.2, 6.3
class SitePointageMap extends StatefulWidget {
  const SitePointageMap({super.key, this.date});
  final DateTime? date;
  
  @override
  State<SitePointageMap> createState() => _SitePointageMapState();
}

class _SitePointageMapState extends State<SitePointageMap> {
  // Services
  late final ReportGenerator _reportGenerator;
  late final HomeProvider _homeProvider;
  
  // State
  DateTimeRange? _selectedDateRange;
  List<String>? _selectedSupervisorIds;
  ReportPreview? _preview;
  bool _isLoadingPreview = false;
  bool _isGenerating = false;
  double _progress = 0.0;
  String _currentStep = '';
  PointageException? _error;
  ReportResult? _lastGeneratedReport;
  ReportFormat _selectedFormat = ReportFormat.excel;
  bool _isHRSummary = false; // Toggle for HR Summary report
  bool _enableColorFormatting = true; // Toggle for conditional color formatting
  
  @override
  void initState() {
    super.initState();
    _reportGenerator = ReportGenerator();
    _homeProvider = Provider.of<HomeProvider>(context, listen: false);
    
    // Initialize with current month if date provided
    if (widget.date != null) {
      final date = widget.date!;
      final firstDay = DateTime(date.year, date.month, 1);
      final lastDay = DateTime(date.year, date.month + 1, 0);
      _selectedDateRange = DateTimeRange(start: firstDay, end: lastDay);
      _loadPreview();
    }
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  /// Load preview data for the selected date range
  Future<void> _loadPreview() async {
    if (_selectedDateRange == null) return;
    
    setState(() {
      _isLoadingPreview = true;
      _error = null;
      _preview = null;
    });
    
    try {
      final preview = await _reportGenerator.previewSupervisorReport(
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
        supervisorIds: _selectedSupervisorIds,
      );
      
      setState(() {
        _preview = preview;
        _isLoadingPreview = false;
      });
    } on PointageException catch (e) {
      setState(() {
        _error = e;
        _isLoadingPreview = false;
      });
    } catch (e) {
      setState(() {
        _error = PointageException.unknown(originalError: e);
        _isLoadingPreview = false;
      });
    }
  }
  
  /// Generate the supervisor report
  Future<void> _generateReport() async {
    if (_selectedDateRange == null) {
      setState(() {
        _error = PointageException.invalidInput(
          message: 'Veuillez sélectionner une période',
        );
      });
      return;
    }
    
    setState(() {
      _isGenerating = true;
      _progress = 0.0;
      _currentStep = 'Initialisation...';
      _error = null;
      _lastGeneratedReport = null;
    });
    
    try {
      final ReportResult result;
      
      if (_isHRSummary) {
        // Generate HR Summary Report
        result = await _reportGenerator.generateHRSummaryReport(
          startDate: _selectedDateRange!.start,
          endDate: _selectedDateRange!.end,
          supervisorIds: _selectedSupervisorIds,
          enableColors: _enableColorFormatting,
          onProgress: (progress, step) {
            setState(() {
              _progress = progress;
              _currentStep = step;
            });
          },
        );
      } else {
        // Generate detailed report
        result = await _reportGenerator.generateSupervisorReport(
          startDate: _selectedDateRange!.start,
          endDate: _selectedDateRange!.end,
          supervisorIds: _selectedSupervisorIds,
          format: _selectedFormat,
          onProgress: (progress, step) {
            setState(() {
              _progress = progress;
              _currentStep = step;
            });
          },
        );
      }
      
      setState(() {
        _isGenerating = false;
        _lastGeneratedReport = result;
      });
      
      // Auto-download the file
      _downloadReport(result);
      
      // Show success message
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: 'Rapport généré avec succès: ${result.fullFilename}',
          icon: Icons.check_circle,
        );
      }
    } on PointageException catch (e) {
      setState(() {
        _isGenerating = false;
        _error = e;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _error = PointageException.reportGeneration(originalError: e);
      });
    }
  }
  
  /// Download the generated report
  void _downloadReport(ReportResult result) {
    final blob = html.Blob([result.fileBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', result.fullFilename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
  
  /// Cancel report generation
  void _cancelGeneration() {
    _reportGenerator.cancel();
    setState(() {
      _isGenerating = false;
      _progress = 0.0;
      _currentStep = '';
    });
  }
  
  /// Handle date range selection
  void _onDateRangeSelected(DateTimeRange range) {
    setState(() {
      _selectedDateRange = range;
    });
    _loadPreview();
  }
  
  /// Show supervisor filter dialog
  Future<void> _showSupervisorFilter() async {
    // Get all supervisors from home provider
    final allSupervisors = _homeProvider.supervisors;
    
    if (allSupervisors.isEmpty) {
      if (mounted) {
        WarningSnackbar.show(
          context,
          message: 'Aucun superviseur disponible',
        );
      }
      return;
    }
    
    // Create a key to access the dialog state
    final dialogKey = GlobalKey<_SupervisorFilterDialogState>();
    
    final selected = await ModernDialog.show<List<String>>(
      context: context,
      title: 'Filtrer par superviseurs',
      content: _SupervisorFilterDialog(
        key: dialogKey,
        supervisors: allSupervisors,
        selectedIds: _selectedSupervisorIds ?? [],
      ),
      actions: [
        DialogAction(
          label: 'Annuler',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogAction(
          label: 'Appliquer',
          onPressed: () {
            // Get selected IDs from dialog state
            final selectedIds = dialogKey.currentState?._selectedIds.toList() ?? [];
            Navigator.of(context).pop(selectedIds);
          },
          isPrimary: true,
        ),
      ],
    );
    
    if (selected != null) {
      setState(() {
        _selectedSupervisorIds = selected.isEmpty ? null : selected;
      });
      _loadPreview();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PointageColors.background,
      appBar: AppBar(
        title: const Text('Rapport Superviseur'),
        backgroundColor: PointageColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(PointageSpacing.lg),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),
                
                const SizedBox(height: PointageSpacing.xl),
                
                // Date Range Picker
                _buildDateRangeSection(),
                
                const SizedBox(height: PointageSpacing.lg),
                
                // Supervisor Filter (Optional)
                _buildSupervisorFilterSection(),
                
                const SizedBox(height: PointageSpacing.lg),
                
                // Report Type Selection (Detailed vs HR Summary)
                _buildReportTypeSelector(),
                
                const SizedBox(height: PointageSpacing.lg),
                
                // Format Selection (only for detailed report)
                if (!_isHRSummary) _buildFormatSelector(),
                
                // HR Summary Options (only for HR Summary report)
                if (_isHRSummary) ...[
                  const SizedBox(height: PointageSpacing.lg),
                  _buildHRSummaryOptions(),
                ],
                
                const SizedBox(height: PointageSpacing.xl),
                
                // Preview or Progress
                if (_isGenerating)
                  _buildProgressSection()
                else if (_error != null)
                  _buildErrorSection()
                else if (_preview != null)
                  _buildPreviewSection()
                else if (_isLoadingPreview)
                  _buildLoadingSection(),
                
                const SizedBox(height: PointageSpacing.xl),
                
                // Action Buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.xl),
      decoration: PointageCardDecorations.standard,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(PointageSpacing.lg),
            decoration: BoxDecoration(
              color: PointageColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assessment,
              size: 48,
              color: PointageColors.primary,
            ),
          ),
          const SizedBox(height: PointageSpacing.md),
          const Text(
            'Rapport de Pointage par Superviseur',
            style: PointageTextStyles.headline2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PointageSpacing.sm),
          Text(
            'Générez un rapport détaillé des pointages par superviseur en Excel ou PDF',
            style: PointageTextStyles.body2.copyWith(
              color: PointageColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateRangeSection() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: PointageColors.primary,
                size: PointageIconSizes.md,
              ),
              const SizedBox(width: PointageSpacing.sm),
              const Text(
                'Période du rapport',
                style: PointageTextStyles.headline4,
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.md),
          ModernDateRangePicker(
            initialRange: _selectedDateRange,
            onRangeSelected: _onDateRangeSelected,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSupervisorFilterSection() {
    final supervisorCount = _selectedSupervisorIds?.length ?? 0;
    final isFiltered = supervisorCount > 0;
    
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_list,
                color: PointageColors.primary,
                size: PointageIconSizes.md,
              ),
              const SizedBox(width: PointageSpacing.sm),
              const Text(
                'Filtrer par superviseurs (optionnel)',
                style: PointageTextStyles.headline4,
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.md),
          InkWell(
            onTap: _showSupervisorFilter,
            borderRadius: PointageBorderRadius.medium,
            child: Container(
              padding: const EdgeInsets.all(PointageSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: PointageColors.divider),
                borderRadius: PointageBorderRadius.medium,
              ),
              child: Row(
                children: [
                  Icon(
                    isFiltered ? Icons.filter_alt : Icons.filter_alt_outlined,
                    color: isFiltered ? PointageColors.primary : PointageColors.textSecondary,
                  ),
                  const SizedBox(width: PointageSpacing.md),
                  Expanded(
                    child: Text(
                      isFiltered
                          ? '$supervisorCount superviseur${supervisorCount > 1 ? 's' : ''} sélectionné${supervisorCount > 1 ? 's' : ''}'
                          : 'Tous les superviseurs',
                      style: PointageTextStyles.body2.copyWith(
                        color: isFiltered ? PointageColors.primary : PointageColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: PointageColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: PointageSpacing.sm),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSupervisorIds = null;
                });
                _loadPreview();
              },
              icon: const Icon(Icons.clear, size: PointageIconSizes.xs),
              label: const Text('Effacer le filtre'),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildReportTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description,
                color: PointageColors.primary,
                size: PointageIconSizes.md,
              ),
              const SizedBox(width: PointageSpacing.sm),
              const Text(
                'Type de rapport',
                style: PointageTextStyles.headline4,
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildReportTypeOption(
                  isHRSummary: false,
                  icon: Icons.table_chart,
                  label: 'Rapport détaillé',
                  description: 'Pointages jour par jour',
                ),
              ),
              const SizedBox(width: PointageSpacing.md),
              Expanded(
                child: _buildReportTypeOption(
                  isHRSummary: true,
                  icon: Icons.summarize,
                  label: 'Résumé RH',
                  description: 'Vue synthétique pour RH',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeOption({
    required bool isHRSummary,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final isSelected = _isHRSummary == isHRSummary;

    return InkWell(
      onTap: () {
        setState(() {
          _isHRSummary = isHRSummary;
        });
      },
      borderRadius: PointageBorderRadius.medium,
      child: Container(
        padding: const EdgeInsets.all(PointageSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? PointageColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: PointageBorderRadius.medium,
          border: Border.all(
            color: isSelected ? PointageColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? PointageColors.primary : PointageColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: PointageSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: PointageTextStyles.label.copyWith(
                      color: isSelected ? PointageColors.primary : PointageColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: PointageTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: PointageColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHRSummaryOptions() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.settings,
                color: PointageColors.primary,
                size: PointageIconSizes.md,
              ),
              const SizedBox(width: PointageSpacing.sm),
              const Text(
                'Options du rapport',
                style: PointageTextStyles.headline4,
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.md),
          
          // Color formatting toggle
          Container(
            padding: const EdgeInsets.all(PointageSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: PointageColors.divider),
              borderRadius: PointageBorderRadius.medium,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _enableColorFormatting 
                        ? PointageColors.primary.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.format_color_fill,
                    color: _enableColorFormatting 
                        ? PointageColors.primary 
                        : PointageColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: PointageSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mise en couleurs conditionnelle',
                        style: PointageTextStyles.label,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _enableColorFormatting 
                            ? 'Vert/Jaune/Orange/Rouge selon la performance'
                            : 'Tableau sans couleurs',
                        style: PointageTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _enableColorFormatting,
                  onChanged: (value) {
                    setState(() {
                      _enableColorFormatting = value;
                    });
                  },
                  activeColor: PointageColors.primary,
                ),
              ],
            ),
          ),
          
          // Color legend (only shown when colors are enabled)
          if (_enableColorFormatting) ...[
            const SizedBox(height: PointageSpacing.md),
            Container(
              padding: const EdgeInsets.all(PointageSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: PointageBorderRadius.small,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildColorLegendItem('Objectif', const Color(0xFFC6EFCE)),
                  _buildColorLegendItem('1 jour', const Color(0xFFFFEB9C)),
                  _buildColorLegendItem('2-4 jours', const Color(0xFFFFCC99)),
                  _buildColorLegendItem('5+ jours', const Color(0xFFFFC7CE)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColorLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: PointageTextStyles.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildFormatSelector() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.file_present,
                color: PointageColors.primary,
                size: PointageIconSizes.md,
              ),
              const SizedBox(width: PointageSpacing.sm),
              const Text(
                'Format d\'export',
                style: PointageTextStyles.headline4,
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildFormatOption(
                  format: ReportFormat.excel,
                  icon: Icons.table_chart,
                  label: 'Excel',
                  description: 'Fichier .xlsx',
                ),
              ),
              const SizedBox(width: PointageSpacing.md),
              Expanded(
                child: _buildFormatOption(
                  format: ReportFormat.pdf,
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  description: 'Document PDF',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFormatOption({
    required ReportFormat format,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final isSelected = _selectedFormat == format;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFormat = format;
        });
      },
      borderRadius: PointageBorderRadius.medium,
      child: Container(
        padding: const EdgeInsets.all(PointageSpacing.md),
        decoration: BoxDecoration(
          color: isSelected 
              ? PointageColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: PointageBorderRadius.medium,
          border: Border.all(
            color: isSelected ? PointageColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? PointageColors.primary : PointageColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: PointageSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: PointageTextStyles.label.copyWith(
                      color: isSelected ? PointageColors.primary : PointageColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: PointageTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: PointageColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPreviewSection() {
    if (_preview == null) return const SizedBox.shrink();
    
    final supervisorCount = _preview!.summary['supervisorCount'] as int? ?? 0;
    final periodDays = _preview!.summary['periodDays'] as int? ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.preview,
                color: PointageColors.primary,
                size: PointageIconSizes.md,
              ),
              const SizedBox(width: PointageSpacing.sm),
              const Text(
                'Aperçu du rapport',
                style: PointageTextStyles.headline4,
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.lg),
          
          // Statistics Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Superviseurs',
                  supervisorCount.toString(),
                  Icons.person,
                  PointageColors.primary,
                ),
              ),
              const SizedBox(width: PointageSpacing.md),
              Expanded(
                child: _buildStatCard(
                  'Jours',
                  periodDays.toString(),
                  Icons.calendar_today,
                  PointageColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Enregistrements',
                  _preview!.totalRecords.toString(),
                  Icons.description,
                  PointageColors.success,
                ),
              ),
              const SizedBox(width: PointageSpacing.md),
              Expanded(
                child: _buildStatCard(
                  'Temps estimé',
                  _preview!.formattedEstimatedTime,
                  Icons.access_time,
                  PointageColors.warning,
                ),
              ),
            ],
          ),
          
          // Warning for long generation
          if (_preview!.isLongGeneration) ...[
            const SizedBox(height: PointageSpacing.md),
            Container(
              padding: const EdgeInsets.all(PointageSpacing.md),
              decoration: BoxDecoration(
                color: PointageColors.warning.withValues(alpha: 0.1),
                borderRadius: PointageBorderRadius.medium,
                border: Border.all(
                  color: PointageColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: PointageColors.warning,
                    size: PointageIconSizes.sm,
                  ),
                  const SizedBox(width: PointageSpacing.sm),
                  Expanded(
                    child: Text(
                      'La génération de ce rapport pourrait prendre du temps. Veuillez patienter.',
                      style: PointageTextStyles.body2.copyWith(
                        color: PointageColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: PointageIconSizes.lg),
          const SizedBox(height: PointageSpacing.sm),
          Text(
            value,
            style: PointageTextStyles.headline3.copyWith(color: color),
          ),
          const SizedBox(height: PointageSpacing.xs),
          Text(
            label,
            style: PointageTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressSection() {
    return GenerationProgressCard(
      progress: _progress,
      currentStep: _currentStep,
      canCancel: true,
      onCancel: _cancelGeneration,
    );
  }
  
  Widget _buildErrorSection() {
    return ErrorDisplay(
      exception: _error,
      onRetry: _loadPreview,
    );
  }
  
  Widget _buildLoadingSection() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.xl),
      decoration: PointageCardDecorations.standard,
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: PointageSpacing.md),
          Text(
            'Chargement de l\'aperçu...',
            style: PointageTextStyles.body2,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    final canGenerate = _selectedDateRange != null && !_isGenerating && _error == null;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_lastGeneratedReport != null && !_isGenerating) ...[
          OutlinedButton.icon(
            onPressed: () => _downloadReport(_lastGeneratedReport!),
            icon: const Icon(Icons.download),
            label: const Text('Télécharger à nouveau'),
            style: PointageButtonStyles.outlined,
          ),
          const SizedBox(width: PointageSpacing.md),
        ],
        ElevatedButton.icon(
          onPressed: canGenerate ? _generateReport : null,
          icon: _isGenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(_isHRSummary 
                  ? Icons.summarize 
                  : (_selectedFormat == ReportFormat.excel 
                      ? Icons.file_download 
                      : Icons.picture_as_pdf)),
          label: Text(_isGenerating 
              ? 'Génération...' 
              : _isHRSummary 
                  ? 'Générer le résumé RH'
                  : 'Générer le rapport ${_selectedFormat == ReportFormat.excel ? "Excel" : "PDF"}'),
          style: PointageButtonStyles.primary.copyWith(
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(
                horizontal: PointageSpacing.xl,
                vertical: PointageSpacing.md,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dialog content for supervisor filter
class _SupervisorFilterDialog extends StatefulWidget {
  final List<Supervisor> supervisors;
  final List<String> selectedIds;
  
  const _SupervisorFilterDialog({
    super.key,
    required this.supervisors,
    required this.selectedIds,
  });
  
  @override
  State<_SupervisorFilterDialog> createState() => _SupervisorFilterDialogState();
}

class _SupervisorFilterDialogState extends State<_SupervisorFilterDialog> {
  late Set<String> _selectedIds;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }
  
  List<Supervisor> get _filteredSupervisors {
    if (_searchQuery.isEmpty) return widget.supervisors;
    
    final query = _searchQuery.toLowerCase();
    return widget.supervisors.where((s) {
      final name = '${s.firstName} ${s.lastName}'.toLowerCase();
      return name.contains(query);
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search field
          TextField(
            decoration: PointageInputDecorations.standard(
              hintText: 'Rechercher un superviseur...',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          
          const SizedBox(height: PointageSpacing.md),
          
          // Select all / Deselect all
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedIds = Set.from(widget.supervisors.map((s) => s.UID));
                  });
                },
                icon: const Icon(Icons.select_all, size: PointageIconSizes.xs),
                label: const Text('Tout sélectionner'),
              ),
              const SizedBox(width: PointageSpacing.sm),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedIds.clear();
                  });
                },
                icon: const Icon(Icons.clear, size: PointageIconSizes.xs),
                label: const Text('Tout désélectionner'),
              ),
            ],
          ),
          
          const SizedBox(height: PointageSpacing.sm),
          
          // Supervisor list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: PointageColors.divider),
                borderRadius: PointageBorderRadius.medium,
              ),
              child: ListView.builder(
                itemCount: _filteredSupervisors.length,
                itemBuilder: (context, index) {
                  final supervisor = _filteredSupervisors[index];
                  final isSelected = _selectedIds.contains(supervisor.UID);
                  
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(supervisor.UID);
                        } else {
                          _selectedIds.remove(supervisor.UID);
                        }
                      });
                    },
                    title: Text(
                      '${supervisor.firstName} ${supervisor.lastName}',
                      style: PointageTextStyles.body2,
                    ),
                    activeColor: PointageColors.primary,
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: PointageSpacing.md),
          
          // Selected count
          Text(
            '${_selectedIds.length} superviseur${_selectedIds.length > 1 ? 's' : ''} sélectionné${_selectedIds.length > 1 ? 's' : ''}',
            style: PointageTextStyles.caption.copyWith(
              color: PointageColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
