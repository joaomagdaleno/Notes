/// Consolidated service tests for Notes
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';

// Use distinct prefixes to avoid any potential shadowing
import 'auth_service.suite.dart' as auth;
import 'services/autocomplete_service.suite.dart' as autocomplete;
import 'services/backup_service.suite.dart' as backup;
import 'services/encryption_service.suite.dart' as encryption;
import 'services/event_replayer.suite.dart' as event_replayer;
import 'services/export_service.suite.dart' as export_svc;
import 'services/firebase_service_unit.suite.dart' as firebase;
import 'services/history_grouper.suite.dart' as history_grouper;
import 'services/read_aloud_service.suite.dart' as read_aloud;
import 'services/reading_bookmarks_service.suite.dart' as bookmarks;
import 'services/reading_interaction_service.suite.dart' as reading_interaction;
import 'services/reading_plan_service.suite.dart' as reading_plan;
import 'services/reading_stats_service.suite.dart' as reading_stats;
import 'services/security_service.suite.dart' as security;
import 'services/sync_service.suite.dart' as sync_service;
import 'services/tag_suggestion_service.suite.dart' as tag_suggestion;
import 'services/template_service.suite.dart' as template;
import 'services/theme_service.suite.dart' as theme;
import 'services/tracing_service.suite.dart' as tracing;
import 'services/update_service.suite.dart' as update;
import 'services/word_lookup_service.suite.dart' as word_lookup;

void main() {
  auth.main();
  autocomplete.main();
  backup.main();
  encryption.main();
  event_replayer.main();
  export_svc.main();
  firebase.main();
  history_grouper.main();
  read_aloud.main();
  bookmarks.main();
  reading_interaction.main();
  reading_plan.main();
  reading_stats.main();
  security.main();
  sync_service.main();
  tag_suggestion.main();
  template.main();
  theme.main();
  tracing.main();
  update.main();
  word_lookup.main();
}
