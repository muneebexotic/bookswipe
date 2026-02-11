/// Centralized UI strings for consistent copy throughout the app.
///
/// All user-facing text should reference these constants
/// instead of being hardcoded inline.
class AppStrings {
  AppStrings._();

  // ── App ──────────────────────────────────────────────
  static const String appName = 'BookSwipe';

  // ── Navigation ───────────────────────────────────────
  static const String navDiscover = 'Discover';
  static const String navLibrary = 'Library';
  static const String navProfile = 'Profile';

  // ── Auth ─────────────────────────────────────────────
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String nameLabel = 'Full Name';
  static const String noAccountPrompt = "Don't have an account?";
  static const String hasAccountPrompt = 'Already have an account?';
  static const String resetPasswordPrompt =
      'Enter your email and we\'ll send you a reset link.';
  static const String passwordResetSent =
      'Password reset email sent. Check your inbox.';
  static const String continueWithGoogle = 'Continue with Google';

  // ── Swipe ────────────────────────────────────────────
  static const String swipeLike = 'LIKE';
  static const String swipePass = 'PASS';
  static const String allBooksSeen = "You've seen all the books!";
  static const String checkBackLater =
      'Check back later for new recommendations';
  static const String refresh = 'Refresh';

  // ── Library ──────────────────────────────────────────
  static const String myLibrary = 'My Library';
  static const String noBooks = 'No books yet';
  static const String noBooksHint =
      'Swipe right on books you like\nand they\'ll show up here!';

  // ── Profile ──────────────────────────────────────────
  static const String profile = 'Profile';
  static const String signOutConfirm = 'Are you sure you want to sign out?';

  // ── Errors ───────────────────────────────────────────
  static const String genericError = 'Something went wrong';
  static const String networkError = 'No internet connection';
  static const String tryAgain = 'Try Again';
  static const String retry = 'Retry';
  static const String failedToLoad = 'Failed to load';
  static const String failedToLoadLibrary = 'Failed to load library';

  // ── Validation ───────────────────────────────────────
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String fieldRequired = 'This field is required';

  // ── Misc ─────────────────────────────────────────────
  static const String unknownAuthor = 'Unknown';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
}
