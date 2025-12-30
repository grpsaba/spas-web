import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/modern_date_range_picker.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/generation_progress_card.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/error_display.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/success_snackbar.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/report_header.dart';
import 'package:spas_web/pointage_redesign/providers/report_generator.dart';
import 'package:spas_web/pointage_redesign/data/aggregation_service.dart';
import 'package:spas_web/pointage_redesign/models/report_models.dart';
import 'package:spas_web/pointage_redesign/models/pointage_exception.dart';
import 'package:spas_web/services/site.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/utilsClass.dart';
import 'dart:html' as html;

/// Refactored ReportSitePage with modern UI and optimized data fetching
/// 
/// Requirements: 1.2, 1.3, 1.5, 2.1, 2.2, 3.1, 4.1, 4.3, 5.2, 6.1, 6.2, 6.3, 7.2, 7.3, 8.1, 8.2
class SiteMonthlyPointage extends StatefulWidget {
  const SiteMonthlyPointage({super.key, required this.date});
  
  final DateTime date;

  @override
  State<SiteMonthlyPointage> createState() => _SiteMonthlyPointageState();
}

class _SiteMonthlyPointageState extends State<SiteMonthlyPointage> {
  late ReportGenerator _reportGenerator;
  late AggregationService _aggregationService;
  
  // State variables
  DateTimeRange? _selectedDateRange;
  List<Site> _allSites = [];
  List<String> _selectedSiteIds = [];
  bool _isLoadingSites = true;
  bool _isGenerating = false;
  bool _showChart = true;
  double _progress = 0.0;
  String _currentStep = '';
  PointageException? _error;
  Map<String, int>? _siteVisitData;
  ReportFormat _selectedFormat = ReportFormat.excel;

  @override
  void initState() {
    super.initState();
    _reportGenerator = ReportGenerator();
    _aggregationService = AggregationService();
    
    // Initialize date range from widget.date (month)
    final days = UtilsClass().jourDuMois(widget.date);
    _selectedDateRange = DateTimeRange(
      start: days.first,
      end: days.last,
    );
    
    _loadSites();
    _loadPreviewData();
  }

  /// Load all active sites
  Future<void> _loadSites() async {
    try {
      setState(() {
        _isLoadingSites = true;
        _error = null;
      });
      
      final sites = await SiteService().allAsModel();
      
      if (!mounted) return;
      
      setState(() {
        _allSites = sites;
        _isLoadingSites = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      final exception = e is PointageException 
          ? e 
          : PointageException.query(
              message: 'Erreur lors du chargement des sites',
              originalError: e,
            );
      
      setState(() {
        _error = exception;
        _isLoadingSites = false;
      });
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exception.userMessage),
          backgroundColor: PointageColors.error,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: _retry,
          ),
        ),
      );
    }
  }

  /// Load preview data for chart
  Future<void> _loadPreviewData() async {
    if (_selectedDateRange == null) return;
    
    try {
      setState(() {
        _error = null;
      });
      
      final data = await _aggregationService.aggregateBySiteAndPeriod(
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end.add(const Duration(days: 1)),
        siteIds: _selectedSiteIds.isEmpty ? null : _selectedSiteIds,
      );
      
      if (!mounted) return;
      
      setState(() {
        _siteVisitData = data;
      });
      
      // Show success feedback for refresh
      if (data.isEmpty) {
        InfoSnackbar.show(
          context,
          message: 'Aucune donnée trouvée pour la période sélectionnée',
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      final exception = e is PointageException 
          ? e 
          : PointageException.query(
              message: 'Erreur lors du chargement des données',
              originalError: e,
            );
      
      setState(() {
        _error = exception;
      });
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exception.userMessage),
          backgroundColor: PointageColors.error,
          action: exception.isRetryable
              ? SnackBarAction(
                  label: 'Réessayer',
                  textColor: Colors.white,
                  onPressed: _retry,
                )
              : null,
        ),
      );
    }
  }

  /// Generate report with selected format
  Future<void> _generateReport() async {
    if (_selectedDateRange == null) {
      if (mounted) {
        WarningSnackbar.show(
          context,
          message: 'Veuillez sélectionner une période pour le rapport',
        );
      }
      return;
    }
    
    try {
      setState(() {
        _isGenerating = true;
        _progress = 0.0;
        _currentStep = 'Initialisation...';
        _error = null;
      });
      
      final result = await _reportGenerator.generateSiteReport(
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
        siteIds: _selectedSiteIds.isEmpty ? null : _selectedSiteIds,
        format: _selectedFormat,
        onProgress: (progress, step) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _currentStep = step;
            });
          }
        },
      );
      
      if (!mounted) return;
      
      setState(() {
        _isGenerating = false;
        _progress = 1.0;
      });
      
      // Auto-download the file
      _downloadReport(result);
      
      // Show success message
      SuccessSnackbar.show(
        context,
        message: 'Rapport généré avec succès: ${result.fullFilename}',
        actionLabel: 'Générer un autre',
        onAction: () {
          setState(() {
            _progress = 0.0;
            _currentStep = '';
          });
        },
      );
    } on PointageException catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isGenerating = false;
        _error = e;
      });
      
      // Show error snackbar for quick feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.userMessage),
          backgroundColor: PointageColors.error,
          action: e.isRetryable
              ? SnackBarAction(
                  label: 'Réessayer',
                  textColor: Colors.white,
                  onPressed: _retryGeneration,
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isGenerating = false;
        _error = PointageException.reportGeneration(
          message: 'Erreur lors de la génération du rapport',
          originalError: e,
        );
      });
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de la génération du rapport'),
          backgroundColor: PointageColors.error,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: _retryGeneration,
          ),
        ),
      );
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

  /// Handle date range change
  void _onDateRangeChanged(DateTimeRange? range) {
    setState(() {
      _selectedDateRange = range;
    });
    _loadPreviewData();
  }

  /// Handle site selection change
  void _onSiteSelectionChanged(List<String> siteIds) {
    setState(() {
      _selectedSiteIds = siteIds;
    });
    _loadPreviewData();
  }

  /// Retry after error
  void _retry() {
    setState(() {
      _error = null;
    });
    
    // Determine what to retry based on the error context
    if (_isLoadingSites || _allSites.isEmpty) {
      _loadSites();
    } else {
      _loadPreviewData();
    }
  }
  
  /// Retry report generation after error
  void _retryGeneration() {
    setState(() {
      _error = null;
    });
    _generateReport();
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 6,
      title: "Pointages -> Rapport mensuel par site",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PointageSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const ReportHeader(
                  title: 'Rapport mensuel par site',
                  description: 'Générez un rapport détaillé du nombre de visites par site',
                  icon: Icons.analytics_outlined,
                ),
                const SizedBox(height: PointageSpacing.xl),
                
                // Date Range Picker
                _buildDateRangePicker(),
                const SizedBox(height: PointageSpacing.lg),
                
                // Site Filter (optional)
                _buildSiteFilter(),
                const SizedBox(height: PointageSpacing.lg),
                
                // Format Selection
                _buildFormatSelector(),
                const SizedBox(height: PointageSpacing.xl),
                
                // Error Display
                if (_error != null && !_isGenerating) ...[
                  ErrorDisplay(
                    exception: _error!,
                    onRetry: _error!.type == PointageErrorType.generationFailed 
                        ? _retryGeneration 
                        : _retry,
                  ),
                  const SizedBox(height: PointageSpacing.lg),
                ],
                
                // Chart or Progress
                if (_isGenerating)
                  GenerationProgressCard(
                    progress: _progress,
                    currentStep: _currentStep,
                    canCancel: false,
                  )
                else if (_siteVisitData != null && _showChart)
                  _buildChart()
                else if (_siteVisitData != null)
                  _buildDataTable(),
                
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

  Widget _buildDateRangePicker() {
    return Card(
      elevation: 0,
      color: PointageColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PointageSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période du rapport',
              style: PointageTextStyles.headline4,
            ),
            const SizedBox(height: PointageSpacing.md),
            ModernDateRangePicker(
              initialRange: _selectedDateRange,
              onRangeSelected: _onDateRangeChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteFilter() {
    return Card(
      elevation: 0,
      color: PointageColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PointageSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filtrer par sites (optionnel)',
                  style: PointageTextStyles.headline4,
                ),
                const SizedBox(width: PointageSpacing.sm),
                Tooltip(
                  message: 'Laissez vide pour inclure tous les sites',
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: PointageColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: PointageSpacing.md),
            if (_isLoadingSites)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(PointageSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Wrap(
                spacing: PointageSpacing.sm,
                runSpacing: PointageSpacing.sm,
                children: [
                  // Select All / Clear All
                  FilterChip(
                    label: Text(_selectedSiteIds.isEmpty ? 'Tous les sites' : 'Effacer'),
                    selected: _selectedSiteIds.isEmpty,
                    onSelected: (selected) {
                      _onSiteSelectionChanged([]);
                    },
                    avatar: Icon(
                      _selectedSiteIds.isEmpty ? Icons.check_circle : Icons.clear,
                      size: 16,
                    ),
                  ),
                  // Individual sites
                  ..._allSites.take(20).map((site) {
                    final isSelected = _selectedSiteIds.contains(site.UID);
                    return FilterChip(
                      label: Text(site.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newSelection = List<String>.from(_selectedSiteIds);
                        if (selected) {
                          newSelection.add(site.UID);
                        } else {
                          newSelection.remove(site.UID);
                        }
                        _onSiteSelectionChanged(newSelection);
                      },
                    );
                  }).toList(),
                  if (_allSites.length > 20)
                    Chip(
                      label: Text('+ ${_allSites.length - 20} autres sites'),
                      avatar: const Icon(Icons.more_horiz, size: 16),
                    ),
                ],
              ),
            if (_selectedSiteIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: PointageSpacing.sm),
                child: Text(
                  '${_selectedSiteIds.length} site(s) sélectionné(s)',
                  style: PointageTextStyles.caption.copyWith(
                    color: PointageColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Card(
      elevation: 0,
      color: PointageColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PointageSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Format d\'export',
              style: PointageTextStyles.headline4,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(PointageSpacing.md),
        decoration: BoxDecoration(
          color: isSelected 
              ? PointageColors.primary.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
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
              Icon(
                Icons.check_circle,
                color: PointageColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_siteVisitData == null || _siteVisitData!.isEmpty) {
      return Card(
        elevation: 0,
        color: PointageColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(PointageSpacing.xl),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: PointageSpacing.md),
                Text(
                  'Aucune donnée disponible',
                  style: PointageTextStyles.body1.copyWith(
                    color: PointageColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Get site names for the chart
    final sortedData = _siteVisitData!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Take top 15 sites for better visibility
    final topSites = sortedData.take(15).toList();
    
    return Card(
      elevation: 0,
      color: PointageColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PointageSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nombre de visites par site',
                  style: PointageTextStyles.headline4,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_showChart ? Icons.table_chart : Icons.bar_chart),
                      onPressed: () {
                        setState(() {
                          _showChart = !_showChart;
                        });
                      },
                      tooltip: _showChart ? 'Afficher le tableau' : 'Afficher le graphique',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: PointageSpacing.lg),
            SizedBox(
              height: 400,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: topSites.isEmpty ? 10 : topSites.first.value.toDouble() * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final site = _allSites.firstWhere(
                          (s) => s.UID == topSites[groupIndex].key,
                          orElse: () => Site(
                            UID: '',
                            codeSite: '',
                            name: 'Site inconnu',
                            adresse: '',
                            email: '',
                            phone: '',
                            latLng: LatLngModel(lat: 0, lng: 0),
                            token: '',
                            nbAgent: 0,
                            supervisor: null,
                            supervisor_2: null,
                            actif: true,
                            zone: null,
                            dateContrat: null,
                            nbRonde: 1,
                          ),
                        );
                        return BarTooltipItem(
                          '${site.name}\n${rod.toY.toInt()} visites',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= topSites.length) return const Text('');
                          final site = _allSites.firstWhere(
                            (s) => s.UID == topSites[value.toInt()].key,
                            orElse: () => Site(
                              UID: '',
                              codeSite: '',
                              name: '?',
                              adresse: '',
                              email: '',
                              phone: '',
                              latLng: LatLngModel(lat: 0, lng: 0),
                              token: '',
                              nbAgent: 0,
                              supervisor: null,
                              supervisor_2: null,
                              actif: true,
                              zone: null,
                              dateContrat: null,
                              nbRonde: 1,
                            ),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              site.codeSite.isNotEmpty ? site.codeSite : site.name,
                              style: const TextStyle(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: topSites.isEmpty ? 1 : null,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: topSites.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: PointageColors.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            if (sortedData.length > 15)
              Padding(
                padding: const EdgeInsets.only(top: PointageSpacing.md),
                child: Text(
                  'Affichage des 15 sites les plus visités sur ${sortedData.length} au total',
                  style: PointageTextStyles.caption.copyWith(
                    color: PointageColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    if (_siteVisitData == null || _siteVisitData!.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedData = _siteVisitData!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      color: PointageColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PointageSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Données détaillées',
                  style: PointageTextStyles.headline4,
                ),
                IconButton(
                  icon: const Icon(Icons.bar_chart),
                  onPressed: () {
                    setState(() {
                      _showChart = true;
                    });
                  },
                  tooltip: 'Afficher le graphique',
                ),
              ],
            ),
            const SizedBox(height: PointageSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Site')),
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Superviseur 1')),
                  DataColumn(label: Text('Superviseur 2')),
                  DataColumn(label: Text('Nombre de visites'), numeric: true),
                ],
                rows: sortedData.map((entry) {
                  final site = _allSites.firstWhere(
                    (s) => s.UID == entry.key,
                    orElse: () => Site(
                      UID: entry.key,
                      codeSite: '',
                      name: 'Site inconnu',
                      adresse: '',
                      email: '',
                      phone: '',
                      latLng: LatLngModel(lat: 0, lng: 0),
                      token: '',
                      nbAgent: 0,
                      supervisor: null,
                      supervisor_2: null,
                      actif: true,
                      zone: null,
                      dateContrat: null,
                      nbRonde: 1,
                    ),
                  );
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(site.name)),
                      DataCell(Text(site.codeSite)),
                      DataCell(Text(
                        site.supervisor != null
                            ? '${site.supervisor!.firstName} ${site.supervisor!.lastName}'
                            : '-',
                      )),
                      DataCell(Text(
                        site.supervisor_2 != null
                            ? '${site.supervisor_2!.firstName} ${site.supervisor_2!.lastName}'
                            : '-',
                      )),
                      DataCell(Text(entry.value.toString())),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final canGenerate = _selectedDateRange != null && !_isGenerating;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isGenerating) ...[
          OutlinedButton.icon(
            onPressed: () async {
              await _loadPreviewData();
              if (mounted && _error == null) {
                SuccessSnackbar.showRefreshSuccess(context);
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: PointageSpacing.lg,
                vertical: PointageSpacing.md,
              ),
            ),
          ),
          const SizedBox(width: PointageSpacing.md),
        ],
        ElevatedButton.icon(
          onPressed: canGenerate ? _generateReport : null,
          icon: _isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(_selectedFormat == ReportFormat.excel 
                  ? Icons.download 
                  : Icons.picture_as_pdf),
          label: Text(_isGenerating 
              ? 'Génération en cours...' 
              : 'Générer le rapport ${_selectedFormat == ReportFormat.excel ? "Excel" : "PDF"}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: PointageColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: PointageSpacing.xl,
              vertical: PointageSpacing.md,
            ),
            textStyle: PointageTextStyles.button,
          ),
        ),
      ],
    );
  }
}
