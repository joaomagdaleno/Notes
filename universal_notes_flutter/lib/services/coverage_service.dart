import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:universal_notes_flutter/models/coverage_report.dart';

class CoverageService {
  final http.Client client;
  static const String _url = 'https://raw.githubusercontent.com/joaomagdaleno/Notes/coverage-data/coverage.json';

  CoverageService({http.Client? client}) : client = client ?? http.Client();

  Future<CoverageReport> getCoverageReport() async {
    final response = await client.get(Uri.parse(_url));

    if (response.statusCode == 200) {
      // The response is a single json object
      final Map<String, dynamic> jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      return CoverageReport.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to load coverage report');
    }
  }
}
