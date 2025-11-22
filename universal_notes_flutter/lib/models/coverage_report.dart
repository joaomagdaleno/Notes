import 'package:flutter/foundation.dart';

class CoverageReport {
  const CoverageReport({
    required this.totalLines,
    required this.totalHit,
    required this.percentage,
    required this.files,
  });

  final int totalLines;
  final int totalHit;
  final double percentage;
  final List<FileCoverage> files;

  factory CoverageReport.fromJson(Map<String, dynamic> json) {
    return CoverageReport(
      totalLines: json['totalLines'] as int,
      totalHit: json['totalHit'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      files: (json['files'] as List<dynamic>)
          .map((file) => FileCoverage.fromJson(file as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FileCoverage {
  const FileCoverage({
    required this.title,
    required this.file,
    required this.functions,
    required this.lines,
  });

  final String title;
  final String file;
  final CoverageDetails functions;
  final CoverageDetails lines;

  factory FileCoverage.fromJson(Map<String, dynamic> json) {
    return FileCoverage(
      title: json['title'] as String,
      file: json['file'] as String,
      functions: CoverageDetails.fromJson(json['functions'] as Map<String, dynamic>),
      lines: CoverageDetails.fromJson(json['lines'] as Map<String, dynamic>),
    );
  }

  double get fileCoveragePercentage {
    if (lines.found == 0) {
      return 0.0;
    }
    return (lines.hit / lines.found) * 100;
  }
}

class CoverageDetails {
  const CoverageDetails({
    required this.hit,
    required this.found,
    required this.details,
  });

  final int hit;
  final int found;
  final List<LineDetail> details;

  factory CoverageDetails.fromJson(Map<String, dynamic> json) {
    return CoverageDetails(
      hit: json['hit'] as int,
      found: json['found'] as int,
      details: (json['details'] as List<dynamic>)
          .map((detail) => LineDetail.fromJson(detail as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LineDetail {
  const LineDetail({
    required this.line,
    required this.hit,
  });

  final int line;
  final int hit;

  factory LineDetail.fromJson(Map<String, dynamic> json) {
    return LineDetail(
      line: json['line'] as int,
      hit: json['hit'] as int,
    );
  }
}
