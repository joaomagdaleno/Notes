/// Consolidated service tests - reduces startup overhead from 21 files → 1
/// Run with: flutter test test/all_services_test.dart
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';

// Import all service tests
import 'services/autocomplete_service_test.dart' as autocomplete;
import 'services/backup_service_test.dart' as backup;
import 'services/encryption_service_test.dart' as encryption;
import 'services/event_replayer_test.dart' as event_replayer;
import 'services/export_service_test.dart' as export_svc;
import 'services/firebase_service_unit_test.dart' as firebase;
import 'services/history_grouper_test.dart' as history;
import 'services/read_aloud_service_test.dart' as read_aloud;
import 'services/reading_bookmarks_service_test.dart' as bookmarks;
import 'services/reading_interaction_service_test.dart' as interaction;
import 'services/reading_plan_service_test.dart' as plan;
import 'services/reading_stats_service_test.dart' as stats;
import 'services/security_service_test.dart' as security;
import 'services/sync_service_test.dart' as sync_svc;
import 'services/tag_suggestion_service_test.dart' as tag_suggestion;
import 'services/template_service_test.dart' as template;
import 'services/theme_service_test.dart' as theme;
import 'services/tracing_service_test.dart' as tracing;
import 'services/update_service_test.dart' as update_svc;
import 'services/word_lookup_service_test.dart' as word_lookup;

void main() {
  // Run all service tests in a single process
  autocomplete.main();
  backup.main();
  encryption.main();
  event_replayer.main();
  export_svc.main();
  firebase.main();
  history.main();
  read_aloud.main();
  bookmarks.main();
  interaction.main();
  plan.main();
  stats.main();
  security.main();
  sync_svc.main();
  tag_suggestion.main();
  template.main();
  theme.main();
  tracing.main();
  update_svc.main();
  word_lookup.main();
}
