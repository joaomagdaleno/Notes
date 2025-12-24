@Tags(['widget'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => await setupTestEnvironment());
  setUp(() async => await setupTest());
  tearDown(() async => await SyncService.instance.reset());

  testWidgets('NotesScreen sanity check', (WidgetTester tester) async {
    await pumpNotesScreen(tester);
    expect(find.text('All Notes'), findsAtLeastNWidgets(1));
  });
}
