import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../application/auth_service.dart';
import '../../application/auth_state.dart';
import '../../domain/enums/auth_status.dart';

part 'auth_controller.g.dart';

/// Controller for authentication operations
@riverpod
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    // Listen to auth state changes
    ref.listen(authStateChangesProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            state = AuthState.authenticated(user);
          } else {
            state = AuthState.unauthenticated();
          }
        },
        loading: () => state = AuthState.initial(),
        error: (error, _) => state = AuthState.error(error.toString()),
      );
    });

    // Check initial auth state
    final user = ref.read(currentUserProvider);
    if (user != null) {
      return AuthState.authenticated(user);
    }

    return AuthState.unauthenticated();
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = AuthState.initial();

    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.signInWithEmail(
        email: email,
        password: password,
      );
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = AuthState.initial();

    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = AuthState.initial();

    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.signInWithGoogle();
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signOut();
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.resetPassword(email);
    } catch (e) {
      state = AuthState.error(e.toString());
      rethrow;
    }
  }

  /// Clear error state
  void clearError() {
    if (state.status == AuthStatus.error) {
      state = AuthState.unauthenticated();
    }
  }
}
