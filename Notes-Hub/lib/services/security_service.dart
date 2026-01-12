import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service for handling biometric authentication and app locking.
class SecurityService {
  SecurityService._();

  /// The singleton instance of [SecurityService].
  static final SecurityService instance = SecurityService._();

  final LocalAuthentication _auth = LocalAuthentication();
  static const String _lockEnabledKey = 'biometric_lock_enabled';

  /// Checks if biometric authentication is available on this device.
  Future<bool> isBiometricAvailable() async {
    final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final canAuthenticate =
        canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  /// Authenticates the user using biometrics.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access your notes',
        persistAcrossBackgrounding: true,
      );
    } on Exception {
      return false;
    }
  }

  /// Checks if the biometric lock is enabled.
  Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockEnabledKey) ?? false;
  }

  /// Sets whether the biometric lock is enabled.
  Future<void> setLockEnabled({required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, enabled);
  }
}
