import 'package:local_auth/local_auth.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Por favor, autentique-se para ver a nota',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print(e);
      return false;
    }
  }
}
