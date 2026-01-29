import '../../domain/models/user_model.dart';

/// Abstract repository for authentication operations
abstract class AuthRepository {
  /// Get current authenticated user
  UserModel? getCurrentUser();

  /// Sign in with email and password
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign in with Google
  Future<UserModel> signInWithGoogle();

  /// Sign out current user
  Future<void> signOut();

  /// Send password reset email
  Future<void> resetPassword(String email);

  /// Stream of authentication state changes
  Stream<UserModel?> get authStateChanges;
}
