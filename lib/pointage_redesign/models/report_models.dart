import 'dart:typed_data';

/// Format options for report generation
enum ReportFormat {
  excel,
  pdf,
  csv;

  String get extension {
    switch (this) {
      case ReportFormat.excel:
        return 'xlsx';
      case ReportFormat.pdf:
        return 'pdf';
      case ReportFormat.csv:
        return 'csv';
    }
  }

  String get mimeType {
    switch (this) {
      case ReportFormat.excel:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case ReportFormat.pdf:
        return 'application/pdf';
      case ReportFormat.csv:
        return 'text/csv';
    }
  }
}

/// Metadata for a generated report
class ReportMetadata {
  final DateTime startDate;
  final DateTime endDate;
  final int totalRecords;
  final Duration generationTime;
  final Map<String, dynamic> filters;
  final String? generatedBy;
  final DateTime generatedAt;

  ReportMetadata({
    required this.startDate,
    required this.endDate,
    required this.totalRecords,
    required this.generationTime,
    required this.filters,
    this.generatedBy,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  /// Get the number of days in the report period
  int get periodDays => endDate.difference(startDate).inDays + 1;

  /// Get average records per day
  double get averageRecordsPerDay {
    if (periodDays == 0) return 0.0;
    return totalRecords / periodDays;
  }

  /// Format generation time as human-readable string
  String get formattedGenerationTime {
    if (generationTime.inSeconds < 1) {
      return '${generationTime.inMilliseconds}ms';
    } else if (generationTime.inMinutes < 1) {
      return '${generationTime.inSeconds}s';
    } else {
      return '${generationTime.inMinutes}m ${generationTime.inSeconds % 60}s';
    }
  }

  /// Convert to JSON for storage/logging
  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalRecords': totalRecords,
      'generationTimeMs': generationTime.inMilliseconds,
      'filters': filters,
      'generatedBy': generatedBy,
      'generatedAt': generatedAt.toIso8601String(),
      'periodDays': periodDays,
    };
  }

  factory ReportMetadata.fromJson(Map<String, dynamic> json) {
    return ReportMetadata(
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalRecords: json['totalRecords'],
      generationTime: Duration(milliseconds: json['generationTimeMs']),
      filters: json['filters'] ?? {},
      generatedBy: json['generatedBy'],
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }

  @override
  String toString() {
    return 'ReportMetadata(period: ${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}, records: $totalRecords, time: $formattedGenerationTime)';
  }
}

/// Result of a report generation operation
class ReportResult {
  final Uint8List fileBytes;
  final String filename;
  final ReportFormat format;
  final ReportMetadata metadata;

  ReportResult({
    required this.fileBytes,
    required this.filename,
    required this.format,
    required this.metadata,
  });

  /// Get file size in bytes
  int get fileSizeBytes => fileBytes.length;

  /// Get file size in KB
  double get fileSizeKB => fileSizeBytes / 1024;

  /// Get file size in MB
  double get fileSizeMB => fileSizeKB / 1024;

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSizeMB >= 1) {
      return '${fileSizeMB.toStringAsFixed(2)} MB';
    } else if (fileSizeKB >= 1) {
      return '${fileSizeKB.toStringAsFixed(2)} KB';
    } else {
      return '$fileSizeBytes bytes';
    }
  }

  /// Get full filename with extension
  String get fullFilename {
    if (filename.endsWith('.${format.extension}')) {
      return filename;
    }
    return '$filename.${format.extension}';
  }

  /// Create a summary string for logging
  String get summary {
    return 'Report: $fullFilename ($formattedFileSize) - ${metadata.totalRecords} records in ${metadata.formattedGenerationTime}';
  }

  @override
  String toString() {
    return 'ReportResult(filename: $fullFilename, format: $format, size: $formattedFileSize, metadata: $metadata)';
  }
}

/// Preview data for a report before generation
class ReportPreview {
  final int totalRecords;
  final int estimatedPages;
  final Duration estimatedGenerationTime;
  final Map<String, dynamic> summary;

  ReportPreview({
    required this.totalRecords,
    required this.estimatedPages,
    required this.estimatedGenerationTime,
    required this.summary,
  });

  /// Get formatted estimated time
  String get formattedEstimatedTime {
    if (estimatedGenerationTime.inSeconds < 1) {
      return 'less than 1 second';
    } else if (estimatedGenerationTime.inMinutes < 1) {
      return '${estimatedGenerationTime.inSeconds} seconds';
    } else {
      return '${estimatedGenerationTime.inMinutes} minutes';
    }
  }

  /// Check if generation might take a long time
  bool get isLongGeneration => estimatedGenerationTime.inSeconds > 30;

  @override
  String toString() {
    return 'ReportPreview(records: $totalRecords, pages: $estimatedPages, estimatedTime: $formattedEstimatedTime)';
  }
}
