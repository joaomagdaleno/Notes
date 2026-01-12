import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:notes_hub/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke test: app launches successfully', (tester) async {
    // Pump the app bootstrap
    await tester.pumpWidget(const AppBootstrap());

    // Allow async initialization to complete
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 2));

    // Verify app has rendered something (not blank)
    expect(find.byType(AppBootstrap), findsOneWidget);
  });
}
