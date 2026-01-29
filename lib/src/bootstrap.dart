import 'config/supabase_config.dart';

/// Initialize app dependencies and services
Future<void> bootstrap() async {
  // Initialize Supabase
  await initializeSupabase();

  // Add other initialization here (e.g., Firebase, analytics, etc.)
}
