import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/enums/auth_status.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form.dart';
import '../widgets/social_login_buttons.dart';
import '../../../../theme/app_theme.dart';

/// Sign up screen for new user registration
class SignupScreen extends ConsumerWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        authController.clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Logo/Icon placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.coralPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 40,
                  color: AppTheme.coralPrimary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Join BookSwipe',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.charcoal,
                      fontSize: 32,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Start swiping through amazing books',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.darkGray,
                      fontSize: 16,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SocialLoginButtons(
                onGooglePressed: () async {
                  await authController.signInWithGoogle();
                },
                isLoading: authState.status == AuthStatus.loading,
              ),
              const SizedBox(height: 32),
              AuthForm(
                submitButtonText: 'Create Account',
                showDisplayName: true,
                onSubmit: ({
                  required email,
                  required password,
                  displayName,
                }) async {
                  await authController.signUpWithEmail(
                    email: email,
                    password: password,
                    displayName: displayName,
                  );
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: AppTheme.darkGray,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
