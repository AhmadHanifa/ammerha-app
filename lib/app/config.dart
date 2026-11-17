/// Backend settings, passed at build time:
/// `flutter run --dart-define-from-file=env.json` (see env.example.json).
/// Without them the app runs on sample data and sends nothing.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// How long a server call may take on a slow connection before the app
  /// gives up and offers to try again.
  static const requestTimeout = Duration(seconds: 12);

  static bool get hasBackend => supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Firebase app settings for push (Project settings > Your apps > Android).
  /// Without them the app runs without notifications.
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseSenderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

  static bool get hasPush =>
      hasBackend &&
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;
}
