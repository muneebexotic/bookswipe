import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/enums/auth_status.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form.dart';
import '../widgets/social_login_buttons.dart';
import '../../../../theme/app_theme.dart';
import '../../../../routing/routes.dart';

/// Login screen for email and social authentication
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);

    // Show error message if present
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
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
                'Welcome Back',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.charcoal,
                      fontSize: 32,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to discover your next favorite book',
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
                submitButtonText: 'Sign In',
                onSubmit: ({
                  required email,
                  required password,
                  displayName,
                }) async {
                  await authController.signInWithEmail(
                    email: email,
                    password: password,
                  );
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    context.push(Routes.forgotPassword);
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: AppTheme.darkGray,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push(Routes.signup);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text('Sign Up'),
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
