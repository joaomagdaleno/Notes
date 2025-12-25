/// Consolidated model tests for Notes - reduces startup overhead (15 files → 1)
/// Run with: flutter test test/all_models_test.dart
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';

// Import all model tests
import 'models/document_model.suite.dart' as document;
import 'models/folder.suite.dart' as folder;
import 'models/misc_models.suite.dart' as misc;
import 'models/note_event.suite.dart' as note_event;
import 'models/note.suite.dart' as note;
import 'models/note_version.suite.dart' as note_version;
import 'models/paper_config.suite.dart' as paper;
import 'models/reading_bookmark.suite.dart' as reading_bookmark;
import 'models/reading_highlight.suite.dart' as reading_highlight;
import 'models/reading_plan_model.suite.dart' as reading_plan;
import 'models/reading_settings.suite.dart' as reading_settings;
import 'models/snippet.suite.dart' as snippet;
import 'models/stroke.suite.dart' as stroke;
import 'models/sync_conflict.suite.dart' as sync_conflict;
import 'models/tag.suite.dart' as tag;

void main() {
  // Run all model tests in a single process
  document.main();
  folder.main();
  misc.main();
  note_event.main();
  note.main();
  note_version.main();
  paper.main();
  reading_bookmark.main();
  reading_highlight.main();
  reading_plan.main();
  reading_settings.main();
  snippet.main();
  stroke.main();
  sync_conflict.main();
  tag.main();
}
