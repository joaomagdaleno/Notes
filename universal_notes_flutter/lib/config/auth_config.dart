/// Centralized configuration for Authentication providers.
/// 
/// To make Google login work 100%:
/// 1. Replace [googleClientId] with your Web Client ID from Firebase Console.
/// Found in Firebase Console > Project Settings > User and accounts > 
/// Google Cloud Platform (GCP) Resource ID > Client IDs for Web.
class AuthConfig {
  /// Google Web Client ID (Required for Windows and some mobile flows).
  static const String googleClientId =
      '542251776386-v8rki7fl7i4vm9pmmrja9qvu8323o694.'
      'apps.googleusercontent.com';
}
