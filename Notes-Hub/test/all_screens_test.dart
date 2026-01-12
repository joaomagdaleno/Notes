/// Consolidated screen tests for Notes
@Tags(['widget'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'screens/about_screen.suite.dart' as about;
import 'screens/note_editor_screen.suite.dart' as editor;
import 'screens/settings_screen.suite.dart' as settings;

void main() {
  about.main();
  editor.main();
  settings.main();
}
