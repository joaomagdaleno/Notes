
import 'dart:io';

void main() {
  final dir = Directory('.');
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('_test.dart')) {
      final content = file.readAsStringSync();
      if (file.path.contains('add_tags.dart') ||
          file.path.contains('coverage_report.dart') ||
          file.path.contains('retag.dart') ||
          file.path.contains('test_helper.dart')) {
        continue;
      }

      var tag = 'unit';
      if (content.contains('testWidgets')) {
        tag = 'widget';
      }
      if (file.path.contains('golden')) {
        tag = 'golden';
      }

      // Replace or Add @Tags
      final tagRegex = RegExp(r'@Tags\(\[.*?\]\)');
      final newTag = "@Tags(['$tag'])";

      String newContent;
      if (tagRegex.hasMatch(content)) {
        newContent = content.replaceFirst(tagRegex, newTag);
      } else {
        newContent = '$newTag\nlibrary;\n\n$content';
      }

      file.writeAsStringSync(newContent);
    }
  }
}
