import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/report_header.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/modern_date_range_picker.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/statistics_card.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/chart_view_toggle.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/visit_frequency_chart.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/generation_progress_card.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/error_display.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/success_snackbar.dart';
import 'package:spas_web/pointage_redesign/models/pointage_exception.dart';
import 'package:spas_web/services/site.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/utilsClass.dart';
import 'package:spas_web/zone_member/zone_rapport_pointage_generator.dart';

/// Modernized zone monthly pointage report with chart/table toggle
/// 
/// Requirements: 3.1, 3.2, 3.3, 3.4
class ZoneSiteMonthlyPointage extends StatefulWidget {
  const ZoneSiteMonthlyPointage({super.key, required this.date});
  
  final DateTime date;

  @override
  State<ZoneSiteMonthlyPointage> createState() => _ZoneSiteMonthlyPointageState();
}

class _ZoneSiteMonthlyPointageState extends State<ZoneSiteMonthlyPointage> {
  // State variables
  DateTimeRange? _selectedDateRange;
  List<Site> _allSites = [];
  bool _isLoadingSites = true;
  bool _isLoadingData = true;
  bool _isGenerating = false;
  ViewMode _viewMode = ViewMode.chart;
  double _progress = 0.0;
  String _currentStep = '';
  PointageException? _error;
  Map<String, int>? _siteVisitData;
  List<SiteVisitData> _chartData = [];
  
  // Statistics
  int _totalVisits = 0;
  int _uniqueZoneMembers = 0;
  int _uniqueSites = 0;
  double _averagePerDay = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Initialize date range from widget.date (month)
    final days = UtilsClass().jourDuMois(widget.date);
    _selectedDateRange = DateTimeRange(
      start: days.first,
      end: days.last,
    );
    
    _loadSites();
    _loadData();
  }

  /// Load all sites
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
    }
  }

  /// Load zone pointage data and calculate statistics
  Future<void> _loadData() async {
    if (_selectedDateRange == null) return;
    
    try {
      setState(() {
        _isLoadingData = true;
        _error = null;
      });
      
      final startDate = _selectedDateRange!.start;
      final endDate = _selectedDateRange!.end.add(const Duration(days: 1));
      
      // Query zone pointings
      final snapshot = await FirebaseFirestore.instance
          .collection('zonePointings')
          .where('datetimestamp', isGreaterThanOrEqualTo: startDate)
          .where('datetimestamp', isLessThan: endDate)
          .get();
      
      if (!mounted) return;
      
      // Aggregate data by site
      final Map<String, int> siteVisits = {};
      final Set<String> uniqueZoneMembers = {};
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          
          // Extract site UID
          final siteData = data['site'] as Map<String, dynamic>?;
          if (siteData != null) {
            final siteUID = siteData['UID'] as String?;
            if (siteUID != null) {
              siteVisits[siteUID] = (siteVisits[siteUID] ?? 0) + 1;
            }
          }
          
          // Track unique zone members
          final zoneMemberData = data['zoneMember'] as Map<String, dynamic>?;
          if (zoneMemberData != null) {
            final zoneMemberUID = zoneMemberData['UID'] as String?;
            if (zoneMemberUID != null) {
              uniqueZoneMembers.add(zoneMemberUID);
            }
          }
        } catch (e) {
          debugPrint('Error processing zone pointing document: $e');
        }
      }
      
      // Calculate statistics
      final totalVisits = siteVisits.values.fold<int>(0, (sum, count) => sum + count);
      final daysDifference = _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1;
      final averagePerDay = daysDifference > 0 ? totalVisits / daysDifference : 0.0;
      
      // Prepare chart data
      final chartData = <SiteVisitData>[];
      for (var entry in siteVisits.entries) {
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
        
        chartData.add(SiteVisitData(
          siteId: entry.key,
          siteName: site.name,
          visitCount: entry.value,
        ));
      }
      
      // Sort by visit count descending
      chartData.sort((a, b) => b.visitCount.compareTo(a.visitCount));
      
      setState(() {
        _siteVisitData = siteVisits;
        _chartData = chartData;
        _totalVisits = totalVisits;
        _uniqueZoneMembers = uniqueZoneMembers.length;
        _uniqueSites = siteVisits.length;
        _averagePerDay = averagePerDay;
        _isLoadingData = false;
      });
      
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
        _isLoadingData = false;
      });
    }
  }

  /// Generate report with selected format
  Future<void> _generateReport() async {
    if (_selectedDateRange == null || _siteVisitData == null) {
      if (mounted) {
        WarningSnackbar.show(
          context,
          message: 'Aucune donnée disponible pour générer le rapport',
        );
      }
      return;
    }
    
    try {
      setState(() {
        _isGenerating = true;
        _progress = 0.0;
        _currentStep = 'Préparation des données...';
        _error = null;
      });
      
      // Prepare report data in the format expected by the old generator
      final reportData = <Map<String, dynamic>>[];
      for (var entry in _siteVisitData!.entries) {
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
        
        reportData.add({
          'site': site,
          'date': '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
          'nbPointage': entry.value,
        });
      }
      
      // Sort by visit count descending
      reportData.sort((a, b) {
        final countA = a['nbPointage'] as int;
        final countB = b['nbPointage'] as int;
        return countB.compareTo(countA);
      });
      
      if (!mounted) return;
      
      setState(() {
        _progress = 0.5;
        _currentStep = 'Génération du fichier Excel...';
      });
      
      // Generate the report using the existing generator
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Use the existing zone rapport generator for Excel
      ZoneRapportPointage.printMonthlySiteRepportToExcel(reportData);
      
      if (!mounted) return;
      
      setState(() {
        _isGenerating = false;
        _progress = 1.0;
      });
      
      // Show success message
      SuccessSnackbar.show(
        context,
        message: 'Rapport généré avec succès',
        actionLabel: 'Générer un autre',
        onAction: () {
          setState(() {
            _progress = 0.0;
            _currentStep = '';
          });
        },
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
    }
  }



  /// Handle date range change
  void _onDateRangeChanged(DateTimeRange? range) {
    setState(() {
      _selectedDateRange = range;
    });
    _loadData();
  }

  /// Handle view mode change
  void _onViewModeChanged(ViewMode mode) {
    setState(() {
      _viewMode = mode;
    });
  }

  /// Retry after error
  void _retry() {
    setState(() {
      _error = null;
    });
    
    if (_isLoadingSites || _allSites.isEmpty) {
      _loadSites();
    } else {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 15,
      title: "Pointages Zone -> Rapport mensuel par site",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PointageSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const ReportHeader(
                  title: 'Rapport mensuel des visites par site',
                  description: 'Nombre de visites des sites par les chefs de zone',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: PointageSpacing.xl),
                
                // Statistics Card
                if (!_isLoadingData && _siteVisitData != null) ...[
                  StatisticsCard(
                    totalPointages: _totalVisits,
                    uniqueSupervisors: _uniqueZoneMembers,
                    uniqueSites: _uniqueSites,
                    averagePerDay: _averagePerDay,
                    supervisorLabel: 'Chefs de zone',
                    siteLabel: 'Sites visités',
                    isLoading: _isLoadingData,
                  ),
                  const SizedBox(height: PointageSpacing.lg),
                ],
                
                // Date Range Picker
                _buildDateRangePicker(),
                const SizedBox(height: PointageSpacing.lg),
                
                // View Toggle
                if (!_isLoadingData && _chartData.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Visualisation',
                        style: PointageTextStyles.headline4,
                      ),
                      ChartViewToggle(
                        initialMode: _viewMode,
                        onModeChanged: _onViewModeChanged,
                        preferenceKey: 'zone_monthly_view_mode',
                      ),
                    ],
                  ),
                  const SizedBox(height: PointageSpacing.lg),
                ],
                
                // Error Display
                if (_error != null && !_isGenerating) ...[
                  ErrorDisplay(
                    exception: _error!,
                    onRetry: _retry,
                  ),
                  const SizedBox(height: PointageSpacing.lg),
                ],
                
                // Content: Chart/Table or Progress
                if (_isGenerating)
                  GenerationProgressCard(
                    progress: _progress,
                    currentStep: _currentStep,
                    canCancel: false,
                  )
                else if (_isLoadingData)
                  _buildLoadingState()
                else if (_chartData.isEmpty)
                  _buildEmptyState()
                else
                  AnimatedViewSwitcher(
                    currentMode: _viewMode,
                    tableView: _buildDataTable(),
                    chartView: _buildChart(),
                  ),
                
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

  Widget _buildLoadingState() {
    return Card(
      elevation: 0,
      color: PointageColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: const Padding(
        padding: EdgeInsets.all(PointageSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: PointageSpacing.md),
              Text('Chargement des données...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: PointageSpacing.md),
              Text(
                'Aucune visite enregistrée pour cette période',
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

  Widget _buildChart() {
    // Take top 20 sites for better visibility
    final topSites = _chartData.take(20).toList();
    
    return VisitFrequencyChart(
      data: topSites,
      height: 500,
      chartType: ChartType.bar,
      title: 'Nombre de visites par site',
    );
  }

  Widget _buildDataTable() {
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
              'Données détaillées',
              style: PointageTextStyles.headline4,
            ),
            const SizedBox(height: PointageSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Rang')),
                  DataColumn(label: Text('Site')),
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Zone')),
                  DataColumn(label: Text('Nombre de visites'), numeric: true),
                ],
                rows: _chartData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final site = _allSites.firstWhere(
                    (s) => s.UID == data.siteId,
                    orElse: () => Site(
                      UID: data.siteId,
                      codeSite: '',
                      name: data.siteName,
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
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(site.name)),
                      DataCell(Text(site.codeSite)),
                      DataCell(Text(site.zone?.name ?? '-')),
                      DataCell(Text(
                        data.visitCount.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
            if (_chartData.length > 20)
              Padding(
                padding: const EdgeInsets.only(top: PointageSpacing.md),
                child: Text(
                  'Affichage de ${_chartData.length} sites au total',
                  style: PointageTextStyles.caption.copyWith(
                    color: PointageColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final canGenerate = _selectedDateRange != null && 
                        !_isGenerating && 
                        !_isLoadingData && 
                        _siteVisitData != null &&
                        _siteVisitData!.isNotEmpty;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isGenerating) ...[
          OutlinedButton.icon(
            onPressed: () async {
              await _loadData();
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
              : const Icon(Icons.download),
          label: Text(_isGenerating 
              ? 'Génération en cours...' 
              : 'Télécharger Excel'),
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
