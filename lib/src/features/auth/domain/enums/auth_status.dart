/// Authentication status enum
enum AuthStatus {
  /// User is authenticated
  authenticated,

  /// User is not authenticated
  unauthenticated,

  /// Authentication state is being checked
  loading,

  /// Authentication error occurred
  error,
}
