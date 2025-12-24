/// Consolidated model tests for Notes - reduces startup overhead (15 files → 1)
/// Run with: flutter test test/all_models_test.dart
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';

// Import all model tests
import 'models/document_model_test.dart' as document;
import 'models/folder_test.dart' as folder;
import 'models/misc_models_test.dart' as misc;
import 'models/note_event_test.dart' as note_event;
import 'models/note_test.dart' as note;
import 'models/note_version_test.dart' as note_version;
import 'models/paper_config_test.dart' as paper;
import 'models/reading_bookmark_test.dart' as reading_bookmark;
import 'models/reading_highlight_test.dart' as reading_highlight;
import 'models/reading_plan_model_test.dart' as reading_plan;
import 'models/reading_settings_test.dart' as reading_settings;
import 'models/snippet_test.dart' as snippet;
import 'models/stroke_test.dart' as stroke;
import 'models/sync_conflict_test.dart' as sync_conflict;
import 'models/tag_test.dart' as tag;

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
