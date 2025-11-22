import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:universal_notes_flutter/models/coverage_report.dart';

class CoverageDetailScreen extends StatefulWidget {
  CoverageDetailScreen({
    super.key,
    required this.fileCoverage,
    http.Client? client,
  }) : client = client ?? http.Client();

  final FileCoverage fileCoverage;
  final http.Client client;

  @override
  State<CoverageDetailScreen> createState() => _CoverageDetailScreenState();
}

class _CoverageDetailScreenState extends State<CoverageDetailScreen> {
  late Future<String> _sourceCode;

  @override
  void initState() {
    super.initState();
    _sourceCode = _fetchSourceCode();
  }

  Future<String> _fetchSourceCode() async {
    // Construct the raw URL for the file on the main branch
    final url =
        'https://raw.githubusercontent.com/joaomagdaleno/Notes/main/${widget.fileCoverage.file}';
    final response = await widget.client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load source code for ${widget.fileCoverage.file}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileCoverage.file),
      ),
      body: FutureBuilder<String>(
        future: _sourceCode,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final codeLines = snapshot.data!.split('\n');
            final lineHits = { for (var v in widget.fileCoverage.lines.details) v.line : v.hit };

            return ListView.builder(
              itemCount: codeLines.length,
              itemBuilder: (context, index) {
                final lineNumber = index + 1;
                final lineCode = codeLines[index];
                Color? highlightColor;

                if (lineHits.containsKey(lineNumber)) {
                  highlightColor = lineHits[lineNumber]! > 0
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3);
                }

                return Container(
                  color: highlightColor,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        padding: const EdgeInsets.only(right: 8.0),
                        alignment: Alignment.centerRight,
                        child: Text(
                          lineNumber.toString(),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            lineCode,
                            style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('Could not load source code.'));
          }
        },
      ),
    );
  }
}
