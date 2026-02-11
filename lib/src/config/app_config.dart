import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration loaded from .env file
class AppConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String googleWebClientId;
  final String googleIosClientId;
  final String environment;

  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.googleWebClientId,
    this.googleIosClientId = '',
    required this.environment,
  });

  /// Load configuration from .env file
  static AppConfig get current {
    return AppConfig(
      supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
      supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      googleWebClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '',
      googleIosClientId: dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '',
      environment: dotenv.env['ENV'] ?? 'development',
    );
  }
}
