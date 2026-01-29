import 'package:bookswipe/src/config/app_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for Supabase authentication operations
class SupabaseAuthDataSource {
  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;

  SupabaseAuthDataSource(this._client);

  /// Initialize Google Sign-In
  Future<void> _initializeGoogleSignIn() async {
    if (_isInitialized) return;

    final config = AppConfig.current;

    await _googleSignIn.initialize(
      // Web Client ID from GCP Console (for backend verification)
      serverClientId: config.googleWebClientId,
      // iOS Client ID (only needed for iOS)
      clientId: config.googleIosClientId.isNotEmpty 
          ? config.googleIosClientId 
          : null,
    );

    _isInitialized = true;
  }

  /// Get current user
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );
  }

  /// Sign in with Google (Native In-App Flow)
  /// Shows native Google account picker on device
  Future<AuthResponse> signInWithGoogle() async {
    // Initialize Google Sign-In if not already done
    await _initializeGoogleSignIn();

    // 1. Trigger native Google Sign-In UI (shows account picker)
    final googleUser = await _googleSignIn.authenticate();

    // 2. Get authentication tokens from Google
    final idToken = googleUser.authentication.idToken;

    if (idToken == null) {
      throw Exception('Failed to get ID token from Google');
    }

    // 3. Sign in to Supabase with Google tokens
    // Supabase will verify the idToken with Google using the Web Client ID
    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    return response;
  }

  /// Sign out
  Future<void> signOut() async {
    // Sign out from both Supabase and Google
    await Future.wait([
      _client.auth.signOut(),
      if (_isInitialized) _googleSignIn.signOut(),
    ]);
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }
}
