import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/enums/auth_status.dart';
import '../domain/models/user_model.dart';

part 'auth_state.freezed.dart';

/// Authentication state
@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    required AuthStatus status,
    UserModel? user,
    String? errorMessage,
  }) = _AuthState;

  /// Initial state
  factory AuthState.initial() => const AuthState(
        status: AuthStatus.loading,
      );

  /// Authenticated state
  factory AuthState.authenticated(UserModel user) => AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );

  /// Unauthenticated state
  factory AuthState.unauthenticated() => const AuthState(
        status: AuthStatus.unauthenticated,
      );

  /// Error state
  factory AuthState.error(String message) => AuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );
}
