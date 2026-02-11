import '../../constants/app_strings.dart';

/// Centralized form validators.
///
/// Usage: `validator: Validators.email`
class Validators {
  Validators._();

  /// Validates an email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.emailRequired;
    }
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return AppStrings.emailInvalid;
    }
    return null;
  }

  /// Validates a password (minimum 6 characters).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }
    if (value.length < 6) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  /// Validates that two passwords match.
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return AppStrings.passwordRequired;
      }
      if (value != password) {
        return AppStrings.passwordsDoNotMatch;
      }
      return null;
    };
  }

  /// Validates that a field is not empty.
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    return null;
  }
}
