import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:universal_notes_flutter/models/coverage_report.dart';
import 'package:universal_notes_flutter/screens/coverage_detail_screen.dart';
import 'package:universal_notes_flutter/services/coverage_service.dart';

class CoverageReportScreen extends StatefulWidget {
  CoverageReportScreen({super.key, CoverageService? service})
      : service = service ?? CoverageService();

  final CoverageService service;

  @override
  State<CoverageReportScreen> createState() => _CoverageReportScreenState();
}

class _CoverageReportScreenState extends State<CoverageReportScreen> {
  late Future<CoverageReport> _coverageReport;

  @override
  void initState() {
    super.initState();
    _coverageReport = widget.service.getCoverageReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Code Coverage Report'),
      ),
      body: FutureBuilder<CoverageReport>(
        future: _coverageReport,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final report = snapshot.data!;
            return Column(
              children: [
                _buildSummaryCard(report.overallCoverage),
                Expanded(
                  child: ListView.builder(
                    itemCount: report.files.length,
                    itemBuilder: (context, index) {
                      final file = report.files[index];
                      return _buildFileCoverageTile(file);
                    },
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: Text('No coverage data available.'));
          }
        },
      ),
    );
  }

  Widget _buildSummaryCard(double overallCoverage) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Overall Coverage', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${overallCoverage.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16.0),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: overallCoverage / 100,
                    strokeWidth: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCoverageTile(FileCoverage file) {
    return ListTile(
      title: Text(file.file),
      subtitle: LinearProgressIndicator(
        value: file.fileCoveragePercentage / 100,
      ),
      trailing: Text('${file.fileCoveragePercentage.toStringAsFixed(2)}%'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoverageDetailScreen(
              fileCoverage: file,
              client: widget.service.client,
            ),
          ),
        );
      },
    );
  }
}
