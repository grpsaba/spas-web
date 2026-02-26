import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/aggregation_service.dart';
import '../models/report_models.dart';
import '../models/pointage_exception.dart';
import '../../model.dart';
import '../../services/pointage_weighted_engine.dart';
import '../../services/supervisor.dart';
import '../../services/site.dart';
import '../../services/zoneMember.dart';

/// Service for generating reports with progress tracking
/// 
/// Integrates with AggregationService for optimized data fetching
/// Uses existing RapportPointage class for Excel generation
/// Requirements: 4.1, 4.2, 4.3, 4.5
class ReportGenerator {
  final AggregationService _aggregationService;
  final SupervisorService _supervisorService;
  final SiteService _siteService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cancellation support
  bool _isCancelled = false;
  
  ReportGenerator({
    AggregationService? aggregationService,
    SupervisorService? supervisorService,
    SiteService? siteService,
  })  : _aggregationService = aggregationService ?? AggregationService(),
        _supervisorService = supervisorService ?? SupervisorService(),
        _siteService = siteService ?? SiteService();

  /// Cancel the current report generation
  void cancel() {
    _isCancelled = true;
  }

  /// Reset cancellation flag
  void _resetCancellation() {
    _isCancelled = false;
  }

  /// Check if generation was cancelled
  void _checkCancellation() {
    if (_isCancelled) {
      throw PointageException.cancelled(
        message: 'Génération du rapport annulée par l\'utilisateur',
      );
    }
  }

  /// Generate supervisor report with progress tracking
  /// 
  /// Requirements: 4.1, 4.2, 4.3, 4.5
  Future<ReportResult> generateSupervisorReport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? supervisorIds,
    ReportFormat format = ReportFormat.excel,
    Function(double progress, String currentStep)? onProgress,
  }) async {
    _resetCancellation();
    final startTime = DateTime.now();
    
    try {
      // Step 1: Fetch supervisors (10% progress)
      onProgress?.call(0.1, 'Chargement des superviseurs...');
      _checkCancellation();
      
      List<Supervisor> supervisors;
      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        supervisors = [];
        for (var id in supervisorIds) {
          final supervisor = await _supervisorService.one(id);
          if (supervisor != null) {
            supervisors.add(supervisor);
          }
        }
      } else {
        supervisors = await _supervisorService.allFuture();
      }

      if (supervisors.isEmpty) {
        throw PointageException.dataNotFound(
          message: 'Aucun superviseur trouvé',
        );
      }

      // Step 2: Generate list of days in the period (15% progress)
      onProgress?.call(0.15, 'Calcul de la période...');
      _checkCancellation();
      
      final days = _generateDaysList(startDate, endDate);
      final supervisorUids = supervisors.map((s) => s.UID).toList();

      // Step 3: Fetch assigned sites for each supervisor (25% progress)
      onProgress?.call(0.25, 'Chargement des sites...');
      _checkCancellation();

      final Map<String, List<Site>> assignedSitesBySupervisor = {};
      for (var supervisor in supervisors) {
        assignedSitesBySupervisor[supervisor.UID] =
            await _siteService.allBySupervisor(supervisor);
      }

      // Step 4: Aggregate daily counts + load raw pointings (60% progress)
      onProgress?.call(0.4, 'Agrégation des pointages...');
      _checkCancellation();

      final results = await Future.wait([
        _aggregationService.aggregateBySupervisorAndDay(
          supervisorIds: supervisorUids,
          days: days,
        ),
        _getSitePointingDocsForPeriod(startDate: startDate, endDate: endDate),
      ]);

      final aggregatedData = results[0] as Map<String, Map<DateTime, int>>;
      final sitePointingDocs = results[1] as List<Map<String, dynamic>>;
      final int periodDays = days.length;

      // Step 5: Build report data structure (75% progress)
      onProgress?.call(0.75, 'Construction du rapport...');
      _checkCancellation();

      final List<Map<String, dynamic>> reportData = [];
      int totalPointages = 0;

      for (var supervisor in supervisors) {
        final supervisorData = aggregatedData[supervisor.UID] ?? {};
        final assignedSites =
            assignedSitesBySupervisor[supervisor.UID] ?? const <Site>[];
        final nbSite = assignedSites.length;

        // Build daily pointages list
        final List<Map<String, dynamic>> dailyPointages = [];
        int supervisorTotal = 0;

        for (var day in days) {
          final count = supervisorData[day] ?? 0;
          dailyPointages.add({
            'date': day,
            'nbPointage': count,
            'count': count,
          });
          supervisorTotal += count;
        }

        final weighted = PointageWeightedEngine.computeForSitePointings(
          allSites: assignedSites,
          pointingDocs: sitePointingDocs,
          supervisorUid: supervisor.UID,
          periodDays: periodDays,
        );

        totalPointages += supervisorTotal;

        reportData.add({
          'supervisor': supervisor,
          'nbSite': nbSite,
          'Pointages': dailyPointages,
          'totalPointages': supervisorTotal,
          'weightedMetrics': {
            'realizedWeight': weighted.realizedWeight,
            'expectedWeight': weighted.expectedWeight,
            'performance': weighted.performancePercent,
          },
        });
      }

      // Step 6: Generate file (90% progress)
      final formatName = format == ReportFormat.excel ? 'Excel' : 'PDF';
      onProgress?.call(0.9, 'Génération du fichier $formatName...');
      _checkCancellation();
      
      final Uint8List bytes;
      if (format == ReportFormat.pdf) {
        bytes = await _generateSupervisorPdf(reportData);
      } else {
        bytes = await _generateSupervisorExcel(reportData);
      }

      // Step 7: Complete (100% progress)
      onProgress?.call(1.0, 'Terminé');
      
      final generationTime = DateTime.now().difference(startTime);
      final filename = _buildSupervisorFilename(startDate, endDate, format);

      return ReportResult(
        fileBytes: bytes,
        filename: filename,
        format: format,
        metadata: ReportMetadata(
          startDate: startDate,
          endDate: endDate,
          totalRecords: totalPointages,
          generationTime: generationTime,
          filters: {
            'supervisorIds': supervisorIds,
            'type': 'supervisor',
          },
        ),
      );
    } on PointageException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Error in generateSupervisorReport: $e');
      throw PointageException.reportGeneration(
        message: 'Erreur lors de la génération du rapport superviseur',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Generate site report with progress tracking
  /// 
  /// Requirements: 4.1, 4.2, 4.3, 4.5
  Future<ReportResult> generateSiteReport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? siteIds,
    ReportFormat format = ReportFormat.excel,
    Function(double progress, String currentStep)? onProgress,
  }) async {
    _resetCancellation();
    final startTime = DateTime.now();
    
    try {
      // Step 1: Aggregate pointages by site (40% progress)
      onProgress?.call(0.2, 'Agrégation des pointages par site...');
      _checkCancellation();
      
      final aggregatedData = await _aggregationService.aggregateBySiteAndPeriod(
        startDate: startDate,
        endDate: endDate,
        siteIds: siteIds,
      );

      // Step 2: Fetch site details (60% progress)
      onProgress?.call(0.5, 'Chargement des détails des sites...');
      _checkCancellation();
      
      final List<Site> sites = [];
      if (siteIds != null && siteIds.isNotEmpty) {
        for (var siteId in siteIds) {
          final site = await _siteService.one(siteId);
          if (site != null) {
            sites.add(site);
          }
        }
      } else {
        sites.addAll(await _siteService.allActifAsModel());
      }

      // Step 3: Build report data structure (80% progress)
      onProgress?.call(0.8, 'Construction du rapport...');
      _checkCancellation();
      
      final List<Map<String, dynamic>> reportData = [];
      int totalPointages = 0;

      for (var site in sites) {
        final nbPointage = aggregatedData[site.UID] ?? 0;
        totalPointages += nbPointage;
        
        reportData.add({
          'site': site,
          'nbPointage': nbPointage,
          'date': '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
        });
      }

      // Step 4: Generate file (95% progress)
      final formatName = format == ReportFormat.excel ? 'Excel' : 'PDF';
      onProgress?.call(0.95, 'Génération du fichier $formatName...');
      _checkCancellation();
      
      final Uint8List bytes;
      if (format == ReportFormat.pdf) {
        bytes = await _generateSitePdf(reportData);
      } else {
        bytes = await _generateSiteExcel(reportData);
      }

      // Step 5: Complete (100% progress)
      onProgress?.call(1.0, 'Terminé');
      
      final generationTime = DateTime.now().difference(startTime);
      final filename = _buildSiteFilename(startDate, endDate, format);

      return ReportResult(
        fileBytes: bytes,
        filename: filename,
        format: format,
        metadata: ReportMetadata(
          startDate: startDate,
          endDate: endDate,
          totalRecords: totalPointages,
          generationTime: generationTime,
          filters: {
            'siteIds': siteIds,
            'type': 'site',
          },
        ),
      );
    } on PointageException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Error in generateSiteReport: $e');
      throw PointageException.reportGeneration(
        message: 'Erreur lors de la génération du rapport site',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Preview supervisor report data before generation
  /// 
  /// Requirements: 4.1
  Future<ReportPreview> previewSupervisorReport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? supervisorIds,
  }) async {
    try {
      // Fetch supervisors
      List<Supervisor> supervisors;
      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        supervisors = [];
        for (var id in supervisorIds) {
          final supervisor = await _supervisorService.one(id);
          if (supervisor != null) {
            supervisors.add(supervisor);
          }
        }
      } else {
        supervisors = await _supervisorService.allFuture();
      }

      // Calculate period days
      final days = _generateDaysList(startDate, endDate);
      final periodDays = days.length;

      // Estimate records (supervisors × days)
      final estimatedRecords = supervisors.length * periodDays;
      
      // Estimate pages (assuming ~30 rows per page)
      final estimatedPages = (supervisors.length / 30).ceil();
      
      // Estimate generation time (rough estimate: 100ms per supervisor + 50ms per day)
      final estimatedTimeMs = (supervisors.length * 100) + (periodDays * 50);
      final estimatedTime = Duration(milliseconds: estimatedTimeMs);

      // Build summary
      final summary = {
        'supervisorCount': supervisors.length,
        'periodDays': periodDays,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      return ReportPreview(
        totalRecords: estimatedRecords,
        estimatedPages: estimatedPages,
        estimatedGenerationTime: estimatedTime,
        summary: summary,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in previewSupervisorReport: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Preview site report data before generation
  /// 
  /// Requirements: 4.1
  Future<ReportPreview> previewSiteReport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? siteIds,
  }) async {
    try {
      // Fetch sites
      List<Site> sites;
      if (siteIds != null && siteIds.isNotEmpty) {
        sites = [];
        for (var siteId in siteIds) {
          final site = await _siteService.one(siteId);
          if (site != null) {
            sites.add(site);
          }
        }
      } else {
        sites = await _siteService.allActifAsModel();
      }

      // Calculate period days
      final periodDays = endDate.difference(startDate).inDays + 1;

      // Estimate records (number of sites)
      final estimatedRecords = sites.length;
      
      // Estimate pages (assuming ~40 rows per page)
      final estimatedPages = (sites.length / 40).ceil();
      
      // Estimate generation time (rough estimate: 50ms per site)
      final estimatedTimeMs = sites.length * 50;
      final estimatedTime = Duration(milliseconds: estimatedTimeMs);

      // Build summary
      final summary = {
        'siteCount': sites.length,
        'periodDays': periodDays,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      return ReportPreview(
        totalRecords: estimatedRecords,
        estimatedPages: estimatedPages,
        estimatedGenerationTime: estimatedTime,
        summary: summary,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in previewSiteReport: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ========== Private Helper Methods ==========

  /// Generate list of days between start and end date
  List<DateTime> _generateDaysList(DateTime startDate, DateTime endDate) {
    final days = <DateTime>[];
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  Future<List<Map<String, dynamic>>> _getSitePointingDocsForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final endExclusive =
        DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('sitePointings')
        .where('datetimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('datetimestamp', isLessThan: Timestamp.fromDate(endExclusive))
        .get();

    return snapshot.docs
        .map((doc) => Map<String, dynamic>.from(doc.data()))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getZonePointingDocsForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final endExclusive =
        DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('zonePointings')
        .where('datetimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('datetimestamp', isLessThan: Timestamp.fromDate(endExclusive))
        .get();

    return snapshot.docs
        .map((doc) => Map<String, dynamic>.from(doc.data()))
        .toList();
  }

  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatWeight(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.0001) {
      return rounded.toInt().toString();
    }
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  /// Generate Excel file for supervisor report
  /// Based on existing RapportPointage.printReportToExcelWeb implementation
  Future<Uint8List> _generateSupervisorExcel(
    List<Map<String, dynamic>> reportData,
  ) async {
    try {
      if (reportData.isEmpty) {
        throw PointageException.invalidInput(
          message: 'Aucune donnée à exporter',
        );
      }

      // Get first row pointings (for dynamic day headers)
      final List<Map<String, dynamic>> firstPointings =
          reportData.first['Pointages'] as List<Map<String, dynamic>>? ?? [];

      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.showGridlines = true;

      // Create header style
      final Style headerStyle = workbook.styles.add('headerStyle');
      headerStyle.borders.all.lineStyle = LineStyle.thin;
      headerStyle.borders.all.color = '#000000';
      headerStyle.fontSize = 12;
      headerStyle.bold = true;
      headerStyle.backColor = "#B0C4DE";

      // Create row style
      final Style rowStyle = workbook.styles.add('rowStyle');
      rowStyle.borders.all.lineStyle = LineStyle.thin;
      rowStyle.borders.all.color = '#000000';
      rowStyle.fontSize = 10;
      rowStyle.bold = false;
      rowStyle.backColor = "#FFFFFF";

      // Title
      DateTime? titreDate;
      if (firstPointings.isNotEmpty) {
        titreDate = firstPointings.first['date'] as DateTime?;
      }
      final titre = titreDate != null 
          ? "Pointages du ${titreDate.month}/${titreDate.year}" 
          : "Pointages";
      sheet.getRangeByIndex(1, 1).setText(titre);
      sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 18;
      sheet.getRangeByIndex(1, 1).cellStyle.bold = true;

      // Header columns
      sheet.getRangeByIndex(2, 1).setText("Superviseurs");
      sheet.getRangeByIndex(2, 1).cellStyle = headerStyle;

      sheet.getRangeByIndex(2, 2).setText("Poids attendu");
      sheet.getRangeByIndex(2, 2).cellStyle = headerStyle;

      sheet.getRangeByIndex(2, 3).setText("Poids réalisé");
      sheet.getRangeByIndex(2, 3).cellStyle = headerStyle;

      sheet.getRangeByIndex(2, 4).setText("Performance");
      sheet.getRangeByIndex(2, 4).cellStyle = headerStyle;

      sheet.getRangeByIndex(2, 5).setText("Nombre de site");
      sheet.getRangeByIndex(2, 5).cellStyle = headerStyle;

      // Day headers
      int colIndex = 6;
      for (Map<String, dynamic> p in firstPointings) {
        DateTime date = p['date'] as DateTime;
        sheet.getRangeByIndex(2, colIndex).setValue(date.day);
        sheet.getRangeByIndex(2, colIndex).cellStyle = headerStyle;
        colIndex++;
      }

      // Data rows
      int rowIndex = 2;
      for (Map<String, dynamic> pointage in reportData) {
        rowIndex++;
        int colIdx = 6;
        
        final Supervisor superviseur = pointage['supervisor'] as Supervisor;
        final int nbSite = (pointage['nbSite'] ?? 0) as int;
        final List<Map<String, dynamic>> pointings = 
            pointage['Pointages'] as List<Map<String, dynamic>>? ?? [];

        final weightedMetrics =
            pointage['weightedMetrics'] as Map<String, dynamic>?;
        final double expectedWeight =
            _toDouble(weightedMetrics?['expectedWeight']);
        final double realizedWeight =
            _toDouble(weightedMetrics?['realizedWeight']);
        final double performance = weightedMetrics != null
            ? _toDouble(weightedMetrics['performance'])
            : (expectedWeight <= 0 ? 0.0 : (realizedWeight * 100.0 / expectedWeight));

        // Supervisor name
        sheet.getRangeByIndex(rowIndex, 1).setText(
          "${superviseur.firstName} ${superviseur.lastName}"
        );
        sheet.getRangeByIndex(rowIndex, 1).columnWidth = 20;
        sheet.getRangeByIndex(rowIndex, 1).cellStyle = rowStyle;

        // Expected weight
        sheet.getRangeByIndex(rowIndex, 2).setText(_formatWeight(expectedWeight));
        sheet.getRangeByIndex(rowIndex, 2).cellStyle = rowStyle;

        // Realized weight
        sheet.getRangeByIndex(rowIndex, 3).setText(_formatWeight(realizedWeight));
        sheet.getRangeByIndex(rowIndex, 3).cellStyle = rowStyle;

        // Performance
        sheet.getRangeByIndex(rowIndex, 4).setValue("${performance.toStringAsFixed(2)}%");
        sheet.getRangeByIndex(rowIndex, 4).cellStyle = rowStyle;

        // Number of sites
        sheet.getRangeByIndex(rowIndex, 5).setValue(nbSite);
        sheet.getRangeByIndex(rowIndex, 5).cellStyle = rowStyle;

        // Daily pointages
        for (Map<String, dynamic> point in pointings) {
          final int nbPointage = (point['nbPointage'] ?? 0) as int;
          sheet.getRangeByIndex(rowIndex, colIdx).setValue(nbPointage);
          sheet.getRangeByIndex(rowIndex, colIdx).cellStyle = rowStyle;
          colIdx++;
        }
      }

      // Save to bytes
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error generating supervisor Excel: $e');
      rethrow;
    }
  }

  /// Generate Excel file for site report
  /// Based on existing RapportPointage.printMonthlySiteReportToExcel implementation
  Future<Uint8List> _generateSiteExcel(
    List<Map<String, dynamic>> reportData,
  ) async {
    try {
      if (reportData.isEmpty) {
        throw PointageException.invalidInput(
          message: 'Aucune donnée à exporter',
        );
      }

      // Sort by number of pointages (descending)
      reportData.sort((p1, p2) {
        final n1 = (p1['nbPointage'] ?? 0) as int;
        final n2 = (p2['nbPointage'] ?? 0) as int;
        return n2.compareTo(n1);
      });

      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.showGridlines = true;

      // Create header style
      final Style headerStyle = workbook.styles.add('hdr');
      headerStyle.borders.all.lineStyle = LineStyle.thin;
      headerStyle.borders.all.color = '#000000';
      headerStyle.fontSize = 12;
      headerStyle.bold = true;
      headerStyle.backColor = "#B0C4DE";

      // Create row style
      final Style rowStyle = workbook.styles.add('row');
      rowStyle.borders.all.lineStyle = LineStyle.thin;
      rowStyle.borders.all.color = '#000000';
      rowStyle.fontSize = 10;
      rowStyle.bold = false;

      // Title
      final String periode = reportData.first['date'] as String? ?? '';
      sheet.getRangeByIndex(1, 1).setText("Pointages site du $periode");
      sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 18;
      sheet.getRangeByIndex(1, 1).cellStyle.bold = true;

      // Header columns
      sheet.getRangeByIndex(2, 1).setText("Sites");
      sheet.getRangeByIndex(2, 1).cellStyle = headerStyle;

      sheet.getRangeByIndex(2, 2).setText("Superviseur 1");
      sheet.getRangeByIndex(2, 2).cellStyle = headerStyle;

      sheet.getRangeByIndex(2, 3).setText("Superviseur 2");
      sheet.getRangeByIndex(2, 3).cellStyle = headerStyle;

      sheet.getRangeByIndex(2, 4).setText("Nombre de visite");
      sheet.getRangeByIndex(2, 4).cellStyle = headerStyle;

      // Data rows
      int rowIndex = 2;
      for (final pointage in reportData) {
        rowIndex++;
        final Site site = pointage['site'] as Site;
        final int nbPointage = (pointage['nbPointage'] ?? 0) as int;

        // Site name
        sheet.getRangeByIndex(rowIndex, 1).setText(site.name);
        sheet.getRangeByIndex(rowIndex, 1).cellStyle = rowStyle;

        // Supervisor 1
        sheet.getRangeByIndex(rowIndex, 2).setText(
          "${site.supervisor?.firstName ?? ''} ${site.supervisor?.lastName ?? ''}"
        );
        sheet.getRangeByIndex(rowIndex, 2).cellStyle = rowStyle;

        // Supervisor 2
        sheet.getRangeByIndex(rowIndex, 3).setText(
          "${site.supervisor_2?.firstName ?? ''} ${site.supervisor_2?.lastName ?? ''}"
        );
        sheet.getRangeByIndex(rowIndex, 3).cellStyle = rowStyle;

        // Number of visits
        sheet.getRangeByIndex(rowIndex, 4).setValue(nbPointage);
        sheet.getRangeByIndex(rowIndex, 4).cellStyle = rowStyle;
      }

      // Save to bytes
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error generating site Excel: $e');
      rethrow;
    }
  }

  /// Build filename for supervisor report
  String _buildSupervisorFilename(DateTime startDate, DateTime endDate, ReportFormat format) {
    final start = '${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}';
    final end = '${endDate.year}${endDate.month.toString().padLeft(2, '0')}${endDate.day.toString().padLeft(2, '0')}';
    return 'PointageSuperviseur_${start}_$end.${format.extension}';
  }

  /// Build filename for site report
  String _buildSiteFilename(DateTime startDate, DateTime endDate, ReportFormat format) {
    final start = '${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}';
    final end = '${endDate.year}${endDate.month.toString().padLeft(2, '0')}${endDate.day.toString().padLeft(2, '0')}';
    return 'PointageSite_${start}_$end.${format.extension}';
  }

  /// Generate PDF file for supervisor report
  Future<Uint8List> _generateSupervisorPdf(
    List<Map<String, dynamic>> reportData,
  ) async {
    try {
      if (reportData.isEmpty) {
        throw PointageException.invalidInput(
          message: 'Aucune donnée à exporter',
        );
      }

      final pdf = pw.Document();

      final List<Map<String, dynamic>> firstPointings =
          reportData.first['Pointages'] as List<Map<String, dynamic>>? ?? [];

      // Get title date
      DateTime? titreDate;
      if (firstPointings.isNotEmpty) {
        titreDate = firstPointings.first['date'] as DateTime?;
      }
      final titre = titreDate != null
          ? "Pointages du ${titreDate.month}/${titreDate.year}"
          : "Pointages";

      // Build table data
      final List<List<String>> tableData = [];
      
      // Header row
      final headerRow = ['Superviseurs', 'Poids attendu', 'Poids réalisé', 'Perf.', 'Sites'];
      for (var p in firstPointings) {
        DateTime date = p['date'] as DateTime;
        headerRow.add('${date.day}');
      }
      tableData.add(headerRow);

      // Data rows
      for (Map<String, dynamic> pointage in reportData) {
        final Supervisor superviseur = pointage['supervisor'] as Supervisor;
        final int nbSite = (pointage['nbSite'] ?? 0) as int;
        final List<Map<String, dynamic>> pointings =
            pointage['Pointages'] as List<Map<String, dynamic>>? ?? [];
        final weightedMetrics =
            pointage['weightedMetrics'] as Map<String, dynamic>?;
        final double expectedWeight =
            _toDouble(weightedMetrics?['expectedWeight']);
        final double realizedWeight =
            _toDouble(weightedMetrics?['realizedWeight']);
        final double performance = weightedMetrics != null
            ? _toDouble(weightedMetrics['performance'])
            : (expectedWeight <= 0 ? 0.0 : (realizedWeight * 100.0 / expectedWeight));

        final row = [
          "${superviseur.firstName} ${superviseur.lastName}",
          _formatWeight(expectedWeight),
          _formatWeight(realizedWeight),
          "${performance.toStringAsFixed(1)}%",
          nbSite.toString(),
        ];

        // Add daily pointages
        for (Map<String, dynamic> point in pointings) {
          final int nbPointage = (point['nbPointage'] ?? 0) as int;
          row.add(nbPointage.toString());
        }
        
        tableData.add(row);
      }

      // Create PDF page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Title
              pw.Header(
                level: 0,
                child: pw.Text(
                  titre,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Table
              pw.Table.fromTextArray(
                context: context,
                data: tableData,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: 9,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                },
              ),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      debugPrint('Error generating supervisor PDF: $e');
      rethrow;
    }
  }

  /// Generate PDF file for site report
  Future<Uint8List> _generateSitePdf(
    List<Map<String, dynamic>> reportData,
  ) async {
    try {
      if (reportData.isEmpty) {
        throw PointageException.invalidInput(
          message: 'Aucune donnée à exporter',
        );
      }

      // Sort by number of pointages (descending)
      reportData.sort((p1, p2) {
        final n1 = (p1['nbPointage'] ?? 0) as int;
        final n2 = (p2['nbPointage'] ?? 0) as int;
        return n2.compareTo(n1);
      });

      final pdf = pw.Document();
      
      // Get period
      final String periode = reportData.first['date'] as String? ?? '';
      
      // Build table data
      final List<List<String>> tableData = [];
      
      // Header row
      tableData.add(['Sites', 'Superviseur 1', 'Superviseur 2', 'Visites']);

      // Data rows
      for (final pointage in reportData) {
        final Site site = pointage['site'] as Site;
        final int nbPointage = (pointage['nbPointage'] ?? 0) as int;

        tableData.add([
          site.name,
          "${site.supervisor?.firstName ?? ''} ${site.supervisor?.lastName ?? ''}".trim(),
          "${site.supervisor_2?.firstName ?? ''} ${site.supervisor_2?.lastName ?? ''}".trim(),
          nbPointage.toString(),
        ]);
      }

      // Create PDF page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Title
              pw.Header(
                level: 0,
                child: pw.Text(
                  "Pointages site du $periode",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Summary
              pw.Text(
                'Total: ${reportData.length} sites',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              
              // Table
              pw.Table.fromTextArray(
                context: context,
                data: tableData,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                },
              ),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      debugPrint('Error generating site PDF: $e');
      rethrow;
    }
  }

  /// Generate zone member report with progress tracking
  /// 
  /// Requirements: 2.1, 2.2, 2.3, 2.4
  Future<ReportResult> generateZoneMemberReport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? zoneMemberIds,
    ReportFormat format = ReportFormat.excel,
    Function(double progress, String currentStep)? onProgress,
  }) async {
    _resetCancellation();
    final startTime = DateTime.now();
    
    try {
      // Import zone member service
      final zoneMemberService = ZoneMemberService();
      
      // Step 1: Fetch zone members (10% progress)
      onProgress?.call(0.1, 'Chargement des chefs de zone...');
      _checkCancellation();
      
      List<ZoneMember> zoneMembers;
      if (zoneMemberIds != null && zoneMemberIds.isNotEmpty) {
        zoneMembers = [];
        for (var id in zoneMemberIds) {
          final zoneMember = await zoneMemberService.one(id);
          if (zoneMember != null) {
            zoneMembers.add(zoneMember);
          }
        }
      } else {
        zoneMembers = await zoneMemberService.allActifAsModel();
      }

      if (zoneMembers.isEmpty) {
        throw PointageException.dataNotFound(
          message: 'Aucun chef de zone trouvé',
        );
      }

      // Step 2: Generate list of days in the period (15% progress)
      onProgress?.call(0.15, 'Calcul de la période...');
      _checkCancellation();
      
      final days = _generateDaysList(startDate, endDate);
      final zoneMemberUids = zoneMembers.map((zm) => zm.UID).toList();

      // Step 3: Fetch zone sites for each zone member (25% progress)
      onProgress?.call(0.25, 'Chargement des sites par zone...');
      _checkCancellation();

      final Map<String, List<Site>> zoneSitesByMember = {};
      for (var zoneMember in zoneMembers) {
        if (zoneMember.zone != null) {
          zoneSitesByMember[zoneMember.UID] =
              await _siteService.allByZone(zoneMember.zone!);
        } else {
          zoneSitesByMember[zoneMember.UID] = <Site>[];
        }
      }

      // Step 4: Aggregate daily counts + load raw pointings (60% progress)
      onProgress?.call(0.4, 'Agrégation des pointages...');
      _checkCancellation();

      final results = await Future.wait([
        _aggregationService.aggregateByZoneMemberAndDay(
          zoneMemberIds: zoneMemberUids,
          days: days,
        ),
        _getZonePointingDocsForPeriod(startDate: startDate, endDate: endDate),
      ]);

      final aggregatedData = results[0] as Map<String, Map<DateTime, int>>;
      final zonePointingDocs = results[1] as List<Map<String, dynamic>>;
      final int periodDays = days.length;

      // Step 5: Build report data structure (75% progress)
      onProgress?.call(0.75, 'Construction du rapport...');
      _checkCancellation();

      final List<Map<String, dynamic>> reportData = [];
      int totalPointages = 0;

      for (var zoneMember in zoneMembers) {
        final zoneMemberData = aggregatedData[zoneMember.UID] ?? {};
        final zoneSites = zoneSitesByMember[zoneMember.UID] ?? const <Site>[];
        final nbSite = zoneSites.length;

        // Build daily pointages list
        final List<Map<String, dynamic>> dailyPointages = [];
        int zoneMemberTotal = 0;

        for (var day in days) {
          final count = zoneMemberData[day] ?? 0;
          dailyPointages.add({
            'date': day,
            'nbPointage': count,
            'count': count,
          });
          zoneMemberTotal += count;
        }

        final weighted = await PointageWeightedEngine.computeForZonePointings(
          allSites: zoneSites,
          pointingDocs: zonePointingDocs,
          zoneMemberUid: zoneMember.UID,
          periodDays: periodDays,
        );

        totalPointages += zoneMemberTotal;

        reportData.add({
          'zoneMember': zoneMember,
          'nbSite': nbSite,
          'Pointages': dailyPointages,
          'totalPointages': zoneMemberTotal,
          'weightedMetrics': {
            'realizedWeight': weighted.realizedWeight,
            'expectedWeight': weighted.expectedWeight,
            'performance': weighted.performancePercent,
          },
        });
      }

      // Step 6: Generate file (90% progress)
      final formatName = format == ReportFormat.excel ? 'Excel' : 'PDF';
      onProgress?.call(0.9, 'Génération du fichier $formatName...');
      _checkCancellation();
      
      final Uint8List bytes;
      if (format == ReportFormat.pdf) {
        bytes = await _generateZoneMemberPdf(reportData);
      } else {
        bytes = await _generateZoneMemberExcel(reportData);
      }

      // Step 7: Complete (100% progress)
      onProgress?.call(1.0, 'Terminé');
      
      final generationTime = DateTime.now().difference(startTime);
      final filename = _buildZoneMemberFilename(startDate, endDate, format);

      return ReportResult(
        fileBytes: bytes,
        filename: filename,
        format: format,
        metadata: ReportMetadata(
          startDate: startDate,
          endDate: endDate,
          totalRecords: totalPointages,
          generationTime: generationTime,
          filters: {
            'zoneMemberIds': zoneMemberIds,
            'type': 'zoneMember',
          },
        ),
      );
    } on PointageException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Error in generateZoneMemberReport: $e');
      throw PointageException.reportGeneration(
        message: 'Erreur lors de la génération du rapport chef de zone',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Preview zone member report data before generation
  /// 
  /// Requirements: 2.1
  Future<ReportPreview> previewZoneMemberReport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? zoneMemberIds,
  }) async {
    try {
      // Import zone member service
      final zoneMemberService = ZoneMemberService();
      
      // Fetch zone members
      List<ZoneMember> zoneMembers;
      if (zoneMemberIds != null && zoneMemberIds.isNotEmpty) {
        zoneMembers = [];
        for (var id in zoneMemberIds) {
          final zoneMember = await zoneMemberService.one(id);
          if (zoneMember != null) {
            zoneMembers.add(zoneMember);
          }
        }
      } else {
        zoneMembers = await zoneMemberService.allActifAsModel();
      }

      // Calculate period days
      final days = _generateDaysList(startDate, endDate);
      final periodDays = days.length;

      // Estimate records (zone members × days)
      final estimatedRecords = zoneMembers.length * periodDays;
      
      // Estimate pages (assuming ~30 rows per page)
      final estimatedPages = (zoneMembers.length / 30).ceil();
      
      // Estimate generation time (rough estimate: 100ms per zone member + 50ms per day)
      final estimatedTimeMs = (zoneMembers.length * 100) + (periodDays * 50);
      final estimatedTime = Duration(milliseconds: estimatedTimeMs.toInt());

      // Build summary
      final summary = {
        'zoneMemberCount': zoneMembers.length,
        'periodDays': periodDays,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      return ReportPreview(
        totalRecords: estimatedRecords,
        estimatedPages: estimatedPages,
        estimatedGenerationTime: estimatedTime,
        summary: summary,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in previewZoneMemberReport: $e');
      throw PointageException.unknown(
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Build filename for zone member report
  String _buildZoneMemberFilename(DateTime startDate, DateTime endDate, ReportFormat format) {
    final start = '${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}';
    final end = '${endDate.year}${endDate.month.toString().padLeft(2, '0')}${endDate.day.toString().padLeft(2, '0')}';
    return 'PointageChefZone_${start}_$end.${format.extension}';
  }

  /// Generate Excel file for zone member report
  Future<Uint8List> _generateZoneMemberExcel(
    List<Map<String, dynamic>> reportData,
  ) async {
    try {
      if (reportData.isEmpty) {
        throw PointageException.invalidInput(
          message: 'Aucune donnée à exporter',
        );
      }

      // Get first row pointings (for dynamic day headers)
      final List<Map<String, dynamic>> firstPointings =
          reportData.first['Pointages'] as List<Map<String, dynamic>>? ?? [];

      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.showGridlines = true;

      // Create header style
      final Style headerStyle = workbook.styles.add('headerStyle');
      headerStyle.borders.all.lineStyle = LineStyle.thin;
      headerStyle.borders.all.color = '#000000';
      headerStyle.fontSize = 12;
      headerStyle.bold = true;
      headerStyle.backColor = "#B0C4DE";

      // Create row style
      final Style rowStyle = workbook.styles.add('rowStyle');
      rowStyle.borders.all.lineStyle = LineStyle.thin;
      rowStyle.borders.all.color = '#000000';
      rowStyle.fontSize = 10;
      rowStyle.bold = false;
      rowStyle.backColor = "#FFFFFF";

      // Title
      DateTime? titreDate;
      if (firstPointings.isNotEmpty) {
        titreDate = firstPointings.first['date'] as DateTime?;
      }
      final titre = titreDate != null 
          ? "Pointages des chefs de zone du ${titreDate.month}/${titreDate.year}" 
          : "Pointages des chefs de zone";
      sheet.getRangeByIndex(1, 1).setText(titre);
      sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 18;
      sheet.getRangeByIndex(1, 1).cellStyle.bold = true;

      // Header columns
      sheet.getRangeByIndex(2, 1).setText("Chefs de zone");
      sheet.getRangeByIndex(2, 1).cellStyle = headerStyle;

      sheet.getRangeByIndex(2, 2).setText("Poids attendu");
      sheet.getRangeByIndex(2, 2).cellStyle = headerStyle;

      sheet.getRangeByIndex(2, 3).setText("Poids réalisé");
      sheet.getRangeByIndex(2, 3).cellStyle = headerStyle;

      sheet.getRangeByIndex(2, 4).setText("Performance");
      sheet.getRangeByIndex(2, 4).cellStyle = headerStyle;

      sheet.getRangeByIndex(2, 5).setText("Zone");
      sheet.getRangeByIndex(2, 5).cellStyle = headerStyle;

      // Day headers
      int colIndex = 6;
      for (Map<String, dynamic> p in firstPointings) {
        DateTime date = p['date'] as DateTime;
        sheet.getRangeByIndex(2, colIndex).setValue(date.day);
        sheet.getRangeByIndex(2, colIndex).cellStyle = headerStyle;
        colIndex++;
      }

      // Data rows
      int rowIndex = 2;
      for (Map<String, dynamic> pointage in reportData) {
        rowIndex++;
        int colIdx = 6;
        
        final ZoneMember zoneMember = pointage['zoneMember'] as ZoneMember;
        final int nbSite = (pointage['nbSite'] ?? 0) as int;
        final List<Map<String, dynamic>> pointings =
            pointage['Pointages'] as List<Map<String, dynamic>>? ?? [];
        final weightedMetrics =
            pointage['weightedMetrics'] as Map<String, dynamic>?;
        final double expectedWeight =
            _toDouble(weightedMetrics?['expectedWeight']);
        final double realizedWeight =
            _toDouble(weightedMetrics?['realizedWeight']);
        final double performance = weightedMetrics != null
            ? _toDouble(weightedMetrics['performance'])
            : (expectedWeight <= 0 ? 0.0 : (realizedWeight * 100.0 / expectedWeight));

        // Zone member name
        sheet.getRangeByIndex(rowIndex, 1).setText(
          "${zoneMember.firstName} ${zoneMember.lastName}"
        );
        sheet.getRangeByIndex(rowIndex, 1).columnWidth = 20;
        sheet.getRangeByIndex(rowIndex, 1).cellStyle = rowStyle;

        // Expected weight
        sheet.getRangeByIndex(rowIndex, 2).setText(_formatWeight(expectedWeight));
        sheet.getRangeByIndex(rowIndex, 2).cellStyle = rowStyle;

        // Realized weight
        sheet.getRangeByIndex(rowIndex, 3).setText(_formatWeight(realizedWeight));
        sheet.getRangeByIndex(rowIndex, 3).cellStyle = rowStyle;

        // Performance
        sheet.getRangeByIndex(rowIndex, 4).setValue("${performance.toStringAsFixed(2)}%");
        sheet.getRangeByIndex(rowIndex, 4).cellStyle = rowStyle;

        // Zone name and site count
        sheet.getRangeByIndex(rowIndex, 5).setText(
          "${zoneMember.zone?.name ?? 'N/A'} ($nbSite sites)"
        );
        sheet.getRangeByIndex(rowIndex, 5).cellStyle = rowStyle;

        // Daily pointages
        for (Map<String, dynamic> point in pointings) {
          final int nbPointage = (point['nbPointage'] ?? 0) as int;
          sheet.getRangeByIndex(rowIndex, colIdx).setValue(nbPointage);
          sheet.getRangeByIndex(rowIndex, colIdx).cellStyle = rowStyle;
          colIdx++;
        }
      }

      // Save to bytes
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error generating zone member Excel: $e');
      rethrow;
    }
  }

  /// Generate PDF file for zone member report
  Future<Uint8List> _generateZoneMemberPdf(
    List<Map<String, dynamic>> reportData,
  ) async {
    try {
      if (reportData.isEmpty) {
        throw PointageException.invalidInput(
          message: 'Aucune donnée à exporter',
        );
      }

      final pdf = pw.Document();

      // Get first row pointings (for dynamic day headers)
      final List<Map<String, dynamic>> firstPointings =
          reportData.first['Pointages'] as List<Map<String, dynamic>>? ?? [];

      // Get title date
      DateTime? titreDate;
      if (firstPointings.isNotEmpty) {
        titreDate = firstPointings.first['date'] as DateTime?;
      }
      final titre = titreDate != null 
          ? "Pointages des chefs de zone du ${titreDate.month}/${titreDate.year}" 
          : "Pointages des chefs de zone";

      // Build table data
      final List<List<String>> tableData = [];
      
      // Header row
      final headerRow = ['Chefs de zone', 'Poids attendu', 'Poids réalisé', 'Perf.', 'Zone'];
      for (var p in firstPointings) {
        DateTime date = p['date'] as DateTime;
        headerRow.add('${date.day}');
      }
      tableData.add(headerRow);

      // Data rows
      for (Map<String, dynamic> pointage in reportData) {
        final ZoneMember zoneMember = pointage['zoneMember'] as ZoneMember;
        final int nbSite = (pointage['nbSite'] ?? 0) as int;
        final List<Map<String, dynamic>> pointings =
            pointage['Pointages'] as List<Map<String, dynamic>>? ?? [];
        final weightedMetrics =
            pointage['weightedMetrics'] as Map<String, dynamic>?;
        final double expectedWeight =
            _toDouble(weightedMetrics?['expectedWeight']);
        final double realizedWeight =
            _toDouble(weightedMetrics?['realizedWeight']);
        final double performance = weightedMetrics != null
            ? _toDouble(weightedMetrics['performance'])
            : (expectedWeight <= 0 ? 0.0 : (realizedWeight * 100.0 / expectedWeight));

        final row = [
          "${zoneMember.firstName} ${zoneMember.lastName}",
          _formatWeight(expectedWeight),
          _formatWeight(realizedWeight),
          "${performance.toStringAsFixed(1)}%",
          "${zoneMember.zone?.name ?? 'N/A'} ($nbSite sites)",
        ];

        // Add daily pointages
        for (Map<String, dynamic> point in pointings) {
          final int nbPointage = (point['nbPointage'] ?? 0) as int;
          row.add(nbPointage.toString());
        }
        
        tableData.add(row);
      }

      // Create PDF page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Title
              pw.Header(
                level: 0,
                child: pw.Text(
                  titre,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Table
              pw.Table.fromTextArray(
                context: context,
                data: tableData,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: 9,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerLeft,
                },
              ),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      debugPrint('Error generating zone member PDF: $e');
      rethrow;
    }
  }

  /// Generate HR Summary Report for supervisors
  /// 
  /// Columns: Superviseur, Manager, Sites assignés, Nombre visite, Attendu, Diff, 
  /// Nbre visites non effectués, Commentaire
  /// With optional conditional formatting (green/yellow/orange/red)
  Future<ReportResult> generateHRSummaryReport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? supervisorIds,
    bool enableColors = true,
    Function(double progress, String currentStep)? onProgress,
  }) async {
    _resetCancellation();
    final startTime = DateTime.now();
    
    try {
      // Step 1: Fetch supervisors (10% progress)
      onProgress?.call(0.1, 'Chargement des superviseurs...');
      _checkCancellation();
      
      List<Supervisor> supervisors;
      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        supervisors = [];
        for (var id in supervisorIds) {
          final supervisor = await _supervisorService.one(id);
          if (supervisor != null) {
            supervisors.add(supervisor);
          }
        }
      } else {
        supervisors = await _supervisorService.allFuture();
      }

      if (supervisors.isEmpty) {
        throw PointageException.dataNotFound(
          message: 'Aucun superviseur trouvé',
        );
      }

      // Step 2: Generate list of days in the period (15% progress)
      onProgress?.call(0.15, 'Calcul de la période...');
      _checkCancellation();
      
      final days = _generateDaysList(startDate, endDate);
      final nbDays = days.length;
      final supervisorUids = supervisors.map((s) => s.UID).toList();

      // Step 3: Fetch site counts for each supervisor (25% progress)
      onProgress?.call(0.25, 'Chargement des sites...');
      _checkCancellation();
      
      final Map<String, int> siteCounts = {};
      for (var supervisor in supervisors) {
        final count = await _siteService.allSitesCountBySupervisor(supervisor);
        siteCounts[supervisor.UID] = count ?? 0;
      }

      // Step 4: Aggregate pointages by supervisor and day (60% progress)
      onProgress?.call(0.4, 'Agrégation des pointages...');
      _checkCancellation();
      
      final aggregatedData = await _aggregationService.aggregateBySupervisorAndDay(
        supervisorIds: supervisorUids,
        days: days,
      );

      // Step 5: Build HR summary data (75% progress)
      onProgress?.call(0.75, 'Construction du résumé RH...');
      _checkCancellation();
      
      final List<Map<String, dynamic>> summaryData = [];

      for (var supervisor in supervisors) {
        final supervisorData = aggregatedData[supervisor.UID] ?? {};
        final int assignedSites = siteCounts[supervisor.UID] ?? 0;
        
        // Calculate total visits
        int completedVisits = 0;
        for (var day in days) {
          completedVisits += supervisorData[day] ?? 0;
        }

        // Calculations according to HR rules
        final int expected = assignedSites * nbDays;
        final int difference = expected - completedVisits;
        final int missedVisits = difference > 0 ? difference : 0;
        final int daysBehind = assignedSites > 0 ? (difference / assignedSites).floor() : 0;
        final int daysBehindClamped = daysBehind < 0 ? 0 : daysBehind;

        // Generate comment
        String comment;
        if (difference <= 0) {
          comment = "Objectif atteint";
        } else if (daysBehindClamped == 0) {
          comment = "Objectif atteint";
        } else if (daysBehindClamped == 1) {
          comment = "Moins d'un jour de l'objectif";
        } else {
          comment = "Moins de $daysBehindClamped jours de l'objectif";
        }

        summaryData.add({
          'supervisor': supervisor,
          'manager': supervisor.department?.label ?? '-',
          'assignedSites': assignedSites,
          'completedVisits': completedVisits,
          'expected': expected,
          'difference': difference,
          'missedVisits': missedVisits,
          'daysBehind': daysBehindClamped,
          'comment': comment,
        });
      }

      // Sort by difference descending (highest delay first)
      summaryData.sort((a, b) {
        final diffA = a['difference'] as int;
        final diffB = b['difference'] as int;
        return diffB.compareTo(diffA);
      });

      // Step 6: Generate Excel file (90% progress)
      onProgress?.call(0.9, 'Génération du fichier Excel...');
      _checkCancellation();
      
      final bytes = await _generateHRSummaryExcel(summaryData, startDate, endDate, enableColors);

      // Step 7: Complete (100% progress)
      onProgress?.call(1.0, 'Terminé');
      
      final generationTime = DateTime.now().difference(startTime);
      final filename = _buildHRSummaryFilename(startDate, endDate);

      return ReportResult(
        fileBytes: bytes,
        filename: filename,
        format: ReportFormat.excel,
        metadata: ReportMetadata(
          startDate: startDate,
          endDate: endDate,
          totalRecords: summaryData.length,
          generationTime: generationTime,
          filters: {
            'supervisorIds': supervisorIds,
            'type': 'hr_summary',
          },
        ),
      );
    } on PointageException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Error in generateHRSummaryReport: $e');
      throw PointageException.reportGeneration(
        message: 'Erreur lors de la génération du rapport résumé RH',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Generate Excel file for HR Summary report with optional conditional formatting
  Future<Uint8List> _generateHRSummaryExcel(
    List<Map<String, dynamic>> summaryData,
    DateTime startDate,
    DateTime endDate,
    bool enableColors,
  ) async {
    try {
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Résumé RH';
      sheet.showGridlines = true;

      // Header style
      final Style headerStyle = workbook.styles.add('headerStyle');
      headerStyle.borders.all.lineStyle = LineStyle.thin;
      headerStyle.borders.all.color = '#000000';
      headerStyle.fontSize = 11;
      headerStyle.bold = true;
      headerStyle.backColor = "#4472C4";
      headerStyle.fontColor = "#FFFFFF";
      headerStyle.hAlign = HAlignType.center;

      // Default row style (no colors)
      final Style defaultRowStyle = workbook.styles.add('defaultRowStyle');
      defaultRowStyle.borders.all.lineStyle = LineStyle.thin;
      defaultRowStyle.borders.all.color = '#000000';
      defaultRowStyle.fontSize = 10;
      defaultRowStyle.backColor = "#FFFFFF";
      defaultRowStyle.fontColor = "#000000";

      // Conditional formatting styles (only used if enableColors is true)
      final Style greenStyle = workbook.styles.add('greenStyle');
      greenStyle.borders.all.lineStyle = LineStyle.thin;
      greenStyle.borders.all.color = '#000000';
      greenStyle.fontSize = 10;
      greenStyle.backColor = enableColors ? "#C6EFCE" : "#FFFFFF";
      greenStyle.fontColor = enableColors ? "#006100" : "#000000";

      final Style yellowStyle = workbook.styles.add('yellowStyle');
      yellowStyle.borders.all.lineStyle = LineStyle.thin;
      yellowStyle.borders.all.color = '#000000';
      yellowStyle.fontSize = 10;
      yellowStyle.backColor = enableColors ? "#FFEB9C" : "#FFFFFF";
      yellowStyle.fontColor = enableColors ? "#9C5700" : "#000000";

      final Style orangeStyle = workbook.styles.add('orangeStyle');
      orangeStyle.borders.all.lineStyle = LineStyle.thin;
      orangeStyle.borders.all.color = '#000000';
      orangeStyle.fontSize = 10;
      orangeStyle.backColor = enableColors ? "#FFCC99" : "#FFFFFF";
      orangeStyle.fontColor = enableColors ? "#974706" : "#000000";

      final Style redStyle = workbook.styles.add('redStyle');
      redStyle.borders.all.lineStyle = LineStyle.thin;
      redStyle.borders.all.color = '#000000';
      redStyle.fontSize = 10;
      redStyle.backColor = enableColors ? "#FFC7CE" : "#FFFFFF";
      redStyle.fontColor = enableColors ? "#9C0006" : "#000000";

      // Title
      final dateRange = "${startDate.day.toString().padLeft(2, '0')} au ${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}";
      sheet.getRangeByIndex(1, 1, 1, 8).merge();
      sheet.getRangeByIndex(1, 1).setText("Rapport des visites des Superviseurs du $dateRange");
      sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 14;
      sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(1, 1).cellStyle.hAlign = HAlignType.center;

      // Subtitle (SECURITE)
      sheet.getRangeByIndex(2, 1, 2, 8).merge();
      sheet.getRangeByIndex(2, 1).setText("SECURITE");
      sheet.getRangeByIndex(2, 1).cellStyle.fontSize = 12;
      sheet.getRangeByIndex(2, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(2, 1).cellStyle.hAlign = HAlignType.center;

      // Headers (row 3)
      final headers = [
        'Superviseurs',
        'Manager',
        'Sites assignés',
        'Nombre visite',
        'Attendu',
        'Diff',
        'Nbre visites non effectués',
        'Commentaire'
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(3, i + 1).setText(headers[i]);
        sheet.getRangeByIndex(3, i + 1).cellStyle = headerStyle;
        // Set column widths
        if (i == 0 || i == 7) {
          sheet.getRangeByIndex(3, i + 1).columnWidth = 22;
        } else if (i == 6) {
          sheet.getRangeByIndex(3, i + 1).columnWidth = 20;
        } else {
          sheet.getRangeByIndex(3, i + 1).columnWidth = 14;
        }
      }

      // Data rows
      int rowIndex = 3;
      for (var data in summaryData) {
        rowIndex++;

        final Supervisor supervisor = data['supervisor'] as Supervisor;
        final int daysBehind = data['daysBehind'] as int;
        final int difference = data['difference'] as int;

        // Determine row style based on delay
        Style rowStyle;
        if (difference <= 0) {
          rowStyle = greenStyle;
        } else if (daysBehind <= 1) {
          rowStyle = yellowStyle;
        } else if (daysBehind <= 4) {
          rowStyle = orangeStyle;
        } else {
          rowStyle = redStyle;
        }

        // Superviseur
        sheet.getRangeByIndex(rowIndex, 1).setText("${supervisor.firstName} ${supervisor.lastName}");
        sheet.getRangeByIndex(rowIndex, 1).cellStyle = rowStyle;

        // Manager
        sheet.getRangeByIndex(rowIndex, 2).setText(data['manager'] as String);
        sheet.getRangeByIndex(rowIndex, 2).cellStyle = rowStyle;

        // Sites assignés
        sheet.getRangeByIndex(rowIndex, 3).setNumber((data['assignedSites'] as int).toDouble());
        sheet.getRangeByIndex(rowIndex, 3).cellStyle = rowStyle;
        sheet.getRangeByIndex(rowIndex, 3).cellStyle.hAlign = HAlignType.center;

        // Nombre visite
        sheet.getRangeByIndex(rowIndex, 4).setNumber((data['completedVisits'] as int).toDouble());
        sheet.getRangeByIndex(rowIndex, 4).cellStyle = rowStyle;
        sheet.getRangeByIndex(rowIndex, 4).cellStyle.hAlign = HAlignType.center;

        // Attendu
        sheet.getRangeByIndex(rowIndex, 5).setNumber((data['expected'] as int).toDouble());
        sheet.getRangeByIndex(rowIndex, 5).cellStyle = rowStyle;
        sheet.getRangeByIndex(rowIndex, 5).cellStyle.hAlign = HAlignType.center;

        // Diff
        sheet.getRangeByIndex(rowIndex, 6).setNumber((data['difference'] as int).toDouble());
        sheet.getRangeByIndex(rowIndex, 6).cellStyle = rowStyle;
        sheet.getRangeByIndex(rowIndex, 6).cellStyle.hAlign = HAlignType.center;

        // Nbre visites non effectués
        sheet.getRangeByIndex(rowIndex, 7).setNumber((data['missedVisits'] as int).toDouble());
        sheet.getRangeByIndex(rowIndex, 7).cellStyle = rowStyle;
        sheet.getRangeByIndex(rowIndex, 7).cellStyle.hAlign = HAlignType.center;

        // Commentaire
        sheet.getRangeByIndex(rowIndex, 8).setText(data['comment'] as String);
        sheet.getRangeByIndex(rowIndex, 8).cellStyle = rowStyle;
      }

      // Save to bytes
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error generating HR Summary Excel: $e');
      rethrow;
    }
  }

  /// Build filename for HR Summary report
  String _buildHRSummaryFilename(DateTime startDate, DateTime endDate) {
    final start = '${startDate.day.toString().padLeft(2, '0')}.${startDate.month.toString().padLeft(2, '0')}';
    final end = '${endDate.day.toString().padLeft(2, '0')}.${endDate.month.toString().padLeft(2, '0')}.${endDate.year.toString().substring(2)}';
    return 'Rapport_visites_Superviseurs_${start}_au_$end.xlsx';
  }
}
