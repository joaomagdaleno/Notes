@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_hub/services/security_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SecurityService', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isLockEnabled should return false by default', () async {
      final enabled = await SecurityService.instance.isLockEnabled();
      expect(enabled, false);
    });

    test('setLockEnabled should update the lock state', () async {
      await SecurityService.instance.setLockEnabled(enabled: true);
      final enabled = await SecurityService.instance.isLockEnabled();
      expect(enabled, true);

      await SecurityService.instance.setLockEnabled(enabled: false);
      final enabledAgain = await SecurityService.instance.isLockEnabled();
      expect(enabledAgain, false);
    });

    test('singleton instance should be shared', () {
      final instance1 = SecurityService.instance;
      final instance2 = SecurityService.instance;
      expect(instance1, same(instance2));
    });
  });
}
