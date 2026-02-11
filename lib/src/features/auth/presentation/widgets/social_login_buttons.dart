import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Social login buttons widget
class SocialLoginButtons extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final bool isLoading;

  const SocialLoginButtons({
    super.key,
    required this.onGooglePressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Google Sign In Button
        OutlinedButton(
          onPressed: isLoading ? null : onGooglePressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: AppTheme.lightGray, width: 1.5),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.coralPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.g_mobiledata,
                            size: 20,
                            color: AppTheme.darkGray,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    const Text('Continue with Google'),
                  ],
                ),
        ),
        const SizedBox(height: 24),
        // Divider with "OR"
        Row(
          children: [
            const Expanded(
              child: Divider(
                color: AppTheme.lightGray,
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: AppTheme.darkGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Expanded(
              child: Divider(
                color: AppTheme.lightGray,
                thickness: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
