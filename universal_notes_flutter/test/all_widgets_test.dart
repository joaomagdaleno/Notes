/// Consolidated widget tests - reduces startup overhead from 13 files → 1
/// Run with: flutter test test/all_widgets_test.dart
@Tags(['widget'])
library;

import 'package:flutter_test/flutter_test.dart';

// Import all widget tests (excluding goldens and mocks)
import 'widgets/context_menu_helper_test.dart' as context_menu;
import 'widgets/empty_state_test.dart' as empty_state;
import 'widgets/fluent_note_card_test.dart' as fluent_card;
import 'widgets/note_card_test.dart' as note_card;
import 'widgets/note_simple_list_tile_test.dart' as list_tile;
import 'widgets/quick_note_editor_test.dart' as quick_editor;
import 'widgets/read_aloud_controls_test.dart' as read_aloud_controls;
import 'widgets/reading_mode_settings_test.dart' as reading_settings;
import 'widgets/reading_outline_navigator_test.dart' as outline_nav;
import 'widgets/sidebar_test.dart' as sidebar;

void main() {
  // Run all widget tests in a single process
  context_menu.main();
  empty_state.main();
  fluent_card.main();
  note_card.main();
  list_tile.main();
  quick_editor.main();
  read_aloud_controls.main();
  reading_settings.main();
  outline_nav.main();
  sidebar.main();
}
