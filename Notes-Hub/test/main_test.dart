@Tags(['widget'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_hub/services/sync_service.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => setupTestEnvironment());
  setUp(() async => setupTest());
  tearDown(() async => SyncService.instance.reset());

  testWidgets('NotesScreen sanity check', (WidgetTester tester) async {
    await pumpNotesScreen(tester);
    expect(find.text('All Notes'), findsAtLeastNWidgets(1));
  });
}
