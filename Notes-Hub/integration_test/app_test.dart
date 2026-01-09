import 'package:flutter_test/flutter_test.dart';
import 'package:notes_hub/main.dart'; // Adjust import based on your app structure
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'smoke test: app launches and shows title',
    (PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());

      // Basic Smoke Test
      // Adjust finders based on your actual UI
      // Assuming a standard Material/Fluent App structure

      // Verify app is settled
      expect($('Universal Notes'), findsOneWidget);
    },
  );
}
