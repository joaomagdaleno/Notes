import 'package:flutter/material.dart';
import 'package:flutter_syntax_view/flutter_syntax_view.dart';
import 'package:http/http.dart' as http;
import 'package:universal_notes_flutter/models/coverage_report.dart';

class CoverageDetailScreen extends StatefulWidget {
  const CoverageDetailScreen({
    super.key,
    required this.fileCoverage,
    http.Client? client,
  }) : client = client ?? const http.Client();

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
            final code = snapshot.data!;
            final lineHits = { for (var v in widget.fileCoverage.lines.details) v.line : v.hit };

            return SyntaxView(
              code: code,
              syntax: Syntax.DART,
              syntaxTheme: SyntaxTheme.vscodeDark(),
              expanded: true,
              withLinesCount: true,
              lineCountColor: Colors.white,
              lineCountBackground: Colors.grey[800],
              lineHighlighter: (int line) {
                if (lineHits.containsKey(line)) {
                  return lineHits[line]! > 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3);
                }
                return null; // No highlight
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
