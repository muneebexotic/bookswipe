import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';

/// Initialize app dependencies and services
Future<void> bootstrap() async {
  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await initializeSupabase();

  // Add other initialization here (e.g., Firebase, analytics, etc.)
}
