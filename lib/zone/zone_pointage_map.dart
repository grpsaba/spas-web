import 'package:flutter/material.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/zoneMember.dart';
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

/// Zone Member Report Page with modern UI and optimized report generation
/// 
/// Requirements: 2.1, 2.2, 2.3, 2.4
class ZonePointageMap extends StatefulWidget {
  const ZonePointageMap({super.key, this.date});
  final DateTime? date;
  
  @override
  State<ZonePointageMap> createState() => _ZonePointageMapState();
}

class _ZonePointageMapState extends State<ZonePointageMap> {
  // Services
  late final ReportGenerator _reportGenerator;
  late final ZoneMemberService _zoneMemberService;
  
  // State
  DateTimeRange? _selectedDateRange;
  List<String>? _selectedZoneMemberIds;
  ReportPreview? _preview;
  bool _isLoadingPreview = false;
  bool _isGenerating = false;
  double _progress = 0.0;
  String _currentStep = '';
  PointageException? _error;
  ReportResult? _lastGeneratedReport;
  ReportFormat _selectedFormat = ReportFormat.excel;
  
  // Zone members list
  List<ZoneMember> _zoneMembers = [];
  bool _isLoadingZoneMembers = true;
  
  @override
  void initState() {
    super.initState();
    _reportGenerator = ReportGenerator();
    _zoneMemberService = ZoneMemberService();
    
    // Load zone members
    _loadZoneMembers();
    
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
  
  /// Load zone members
  Future<void> _loadZoneMembers() async {
    try {
      final zoneMembers = await _zoneMemberService.allActifAsModel();
      setState(() {
        _zoneMembers = zoneMembers;
        _isLoadingZoneMembers = false;
      });
    } catch (e) {
      debugPrint('Error loading zone members: $e');
      setState(() {
        _isLoadingZoneMembers = false;
      });
    }
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
      final preview = await _reportGenerator.previewZoneMemberReport(
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
        zoneMemberIds: _selectedZoneMemberIds,
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
  
  /// Generate the zone member report
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
      final result = await _reportGenerator.generateZoneMemberReport(
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
        zoneMemberIds: _selectedZoneMemberIds,
        format: _selectedFormat,
        onProgress: (progress, step) {
          setState(() {
            _progress = progress;
            _currentStep = step;
          });
        },
      );
      
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
  
  /// Show zone member filter dialog
  Future<void> _showZoneMemberFilter() async {
    if (_zoneMembers.isEmpty) {
      if (mounted) {
        WarningSnackbar.show(
          context,
          message: 'Aucun chef de zone disponible',
        );
      }
      return;
    }
    
    final selected = await ModernDialog.show<List<String>>(
      context: context,
      title: 'Filtrer par chefs de zone',
      content: _ZoneMemberFilterDialog(
        zoneMembers: _zoneMembers,
        selectedIds: _selectedZoneMemberIds ?? [],
        onSelectionChanged: (ids) {
          _selectedZoneMemberIds = ids;
        },
      ),
      actions: [
        DialogAction(
          label: 'Annuler',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogAction(
          label: 'Appliquer',
          onPressed: () {
            Navigator.of(context).pop(_selectedZoneMemberIds);
          },
          isPrimary: true,
        ),
      ],
    );
    
    if (selected != null) {
      setState(() {
        _selectedZoneMemberIds = selected.isEmpty ? null : selected;
      });
      _loadPreview();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PointageColors.background,
      appBar: AppBar(
        title: const Text('Rapport Chef de Zone'),
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
                
                // Zone Member Filter (Optional)
                _buildZoneMemberFilterSection(),
                
                const SizedBox(height: PointageSpacing.lg),
                
                // Format Selection
                _buildFormatSelector(),
                
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
              Icons.map_outlined,
              size: 48,
              color: PointageColors.primary,
            ),
          ),
          const SizedBox(height: PointageSpacing.md),
          const Text(
            'Rapport de Pointage par Chef de Zone',
            style: PointageTextStyles.headline2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PointageSpacing.sm),
          Text(
            'Générez un rapport détaillé des pointages par chef de zone en Excel ou PDF',
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
          const Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: PointageColors.primary,
                size: PointageIconSizes.md,
              ),
              SizedBox(width: PointageSpacing.sm),
              Text(
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
  
  Widget _buildZoneMemberFilterSection() {
    final zoneMemberCount = _selectedZoneMemberIds?.length ?? 0;
    final isFiltered = zoneMemberCount > 0;
    
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.filter_list,
                color: PointageColors.primary,
                size: PointageIconSizes.md,
              ),
              SizedBox(width: PointageSpacing.sm),
              Text(
                'Filtrer par chefs de zone (optionnel)',
                style: PointageTextStyles.headline4,
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.md),
          InkWell(
            onTap: _isLoadingZoneMembers ? null : _showZoneMemberFilter,
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
                    child: _isLoadingZoneMembers
                        ? const Text(
                            'Chargement...',
                            style: PointageTextStyles.body2,
                          )
                        : Text(
                            isFiltered
                                ? '$zoneMemberCount chef${zoneMemberCount > 1 ? 's' : ''} de zone sélectionné${zoneMemberCount > 1 ? 's' : ''}'
                                : 'Tous les chefs de zone',
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
                  _selectedZoneMemberIds = null;
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
  
  Widget _buildFormatSelector() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.file_present,
                color: PointageColors.primary,
                size: PointageIconSizes.md,
              ),
              SizedBox(width: PointageSpacing.sm),
              Text(
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
    
    final zoneMemberCount = _preview!.summary['zoneMemberCount'] as int? ?? 0;
    final periodDays = _preview!.summary['periodDays'] as int? ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.preview,
                color: PointageColors.primary,
                size: PointageIconSizes.md,
              ),
              SizedBox(width: PointageSpacing.sm),
              Text(
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
                  'Chefs de zone',
                  zoneMemberCount.toString(),
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
              : Icon(_selectedFormat == ReportFormat.excel 
                  ? Icons.file_download 
                  : Icons.picture_as_pdf),
          label: Text(_isGenerating 
              ? 'Génération...' 
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

/// Dialog content for zone member filter
class _ZoneMemberFilterDialog extends StatefulWidget {
  final List<ZoneMember> zoneMembers;
  final List<String> selectedIds;
  final Function(List<String>) onSelectionChanged;
  
  const _ZoneMemberFilterDialog({
    required this.zoneMembers,
    required this.selectedIds,
    required this.onSelectionChanged,
  });
  
  @override
  State<_ZoneMemberFilterDialog> createState() => _ZoneMemberFilterDialogState();
}

class _ZoneMemberFilterDialogState extends State<_ZoneMemberFilterDialog> {
  late Set<String> _selectedIds;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }
  
  List<ZoneMember> get _filteredZoneMembers {
    if (_searchQuery.isEmpty) return widget.zoneMembers;
    
    final query = _searchQuery.toLowerCase();
    return widget.zoneMembers.where((zm) {
      final name = '${zm.firstName} ${zm.lastName}'.toLowerCase();
      final zoneName = zm.zone?.name.toLowerCase() ?? '';
      return name.contains(query) || zoneName.contains(query);
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
              hintText: 'Rechercher un chef de zone...',
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
                    _selectedIds = Set.from(widget.zoneMembers.map((zm) => zm.UID));
                    widget.onSelectionChanged(_selectedIds.toList());
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
                    widget.onSelectionChanged(_selectedIds.toList());
                  });
                },
                icon: const Icon(Icons.clear, size: PointageIconSizes.xs),
                label: const Text('Tout désélectionner'),
              ),
            ],
          ),
          
          const SizedBox(height: PointageSpacing.sm),
          
          // Zone member list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: PointageColors.divider),
                borderRadius: PointageBorderRadius.medium,
              ),
              child: ListView.builder(
                itemCount: _filteredZoneMembers.length,
                itemBuilder: (context, index) {
                  final zoneMember = _filteredZoneMembers[index];
                  final isSelected = _selectedIds.contains(zoneMember.UID);
                  
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(zoneMember.UID);
                        } else {
                          _selectedIds.remove(zoneMember.UID);
                        }
                        widget.onSelectionChanged(_selectedIds.toList());
                      });
                    },
                    title: Text(
                      '${zoneMember.firstName} ${zoneMember.lastName}',
                      style: PointageTextStyles.body2,
                    ),
                    subtitle: zoneMember.zone != null
                        ? Text(
                            zoneMember.zone!.name,
                            style: PointageTextStyles.caption,
                          )
                        : null,
                    activeColor: PointageColors.primary,
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: PointageSpacing.md),
          
          // Selected count
          Text(
            '${_selectedIds.length} chef${_selectedIds.length > 1 ? 's' : ''} de zone sélectionné${_selectedIds.length > 1 ? 's' : ''}',
            style: PointageTextStyles.caption.copyWith(
              color: PointageColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
