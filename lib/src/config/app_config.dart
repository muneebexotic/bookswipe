/// Application configuration for different environments
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

  /// Development configuration
  static const development = AppConfig(
    supabaseUrl: String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://fesfjydwfglefqgpkovm.supabase.co',
    ),
    supabaseAnonKey: String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZlc2ZqeWR3ZmdsZWZxZ3Brb3ZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyMzg5OTksImV4cCI6MjA4MzgxNDk5OX0.gBAnjqqNPvTIfhIDolBkZiJnTxmC1AlSFwZyE6i9UiE',
    ),
    googleWebClientId: String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue: '510985846589-43tc1jnepnkc0h25154tkbvl54i0fijs.apps.googleusercontent.com',
    ),
    googleIosClientId: String.fromEnvironment(
      'GOOGLE_IOS_CLIENT_ID',
      defaultValue: '',
    ),
    environment: 'development',
  );

  /// Production configuration
  static const production = AppConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    googleWebClientId: String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    googleIosClientId: String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
    environment: 'production',
  );

  /// Get current config based on environment
  static AppConfig get current {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    return env == 'production' ? production : development;
  }
}
