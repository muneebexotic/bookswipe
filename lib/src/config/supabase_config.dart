import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';

/// Initialize Supabase client
Future<void> initializeSupabase() async {
  final config = AppConfig.current;

  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}

/// Global Supabase client instance
SupabaseClient get supabase => Supabase.instance.client;
