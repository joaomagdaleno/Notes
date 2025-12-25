/// Consolidated service tests for Notes
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';

// Use distinct prefixes to avoid any potential shadowing
import 'auth_service_test.dart' as auth_test;
import 'services/firebase_service_unit_test.dart' as firebase_test;
// import 'services/storage_service_test.dart' as storage_test; // File does not exist
import 'services/encryption_service_test.dart' as encryption_test;
import 'services/sync_service_test.dart' as sync_test;
import 'services/reading_bookmarks_service_test.dart' as bookmarks_test;

void main() {
  auth_test.main();
  firebase_test.main();
  // storage_test.main();
  encryption_test.main();
  sync_test.main();
  bookmarks_test.main();
}
