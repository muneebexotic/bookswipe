import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/splash_controller.dart';

/// Splash screen with animated logo and app branding.
/// Automatically navigates to the next screen after initialization.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  /// Handle navigation after splash initialization
  Future<void> _handleNavigation() async {
    // Wait for splash controller to complete
    final isComplete = await ref.read(splashControllerProvider.future);

    if (!isComplete || !mounted) return;

    // Get next route from controller
    final nextRoute = await ref.read(splashControllerProvider.notifier).getNextRoute();

    if (mounted) {
      context.go(nextRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.splashGradient,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAnimatedLogo(),
              const SizedBox(height: AppSizes.space32),
              _buildAppTitle(theme),
              const SizedBox(height: AppSizes.space12),
              _buildTagline(theme),
              const SizedBox(height: AppSizes.space64),
              _buildLoadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  /// Animated logo widget with scale and fade effects
  Widget _buildAnimatedLogo() {
    return Container(
      width: AppSizes.logoLarge,
      height: AppSizes.logoLarge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
        child: Image.asset(
          'assets/images/bookswipe_logo.png',
          fit: BoxFit.cover,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        )
        .then(delay: 200.ms)
        .shimmer(
          duration: 1500.ms,
          color: Colors.white.withValues(alpha: 0.3),
        );
  }

  /// App title with fade and slide animation
  Widget _buildAppTitle(ThemeData theme) {
    return Text(
      'BookSwipe',
      style: theme.textTheme.displayMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(2, 4),
            blurRadius: 8,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 500.ms)
        .slideY(begin: 0.3, end: 0, delay: 400.ms, duration: 500.ms);
  }

  /// Tagline with fade animation
  Widget _buildTagline(ThemeData theme) {
    return Text(
      'Discover your next read',
      style: theme.textTheme.titleMedium?.copyWith(
        color: Colors.white.withValues(alpha: 0.9),
        fontWeight: FontWeight.w400,
        letterSpacing: 1,
      ),
    ).animate().fadeIn(delay: 700.ms, duration: 500.ms);
  }

  /// Subtle loading indicator
  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: AppSizes.loadingIndicatorMedium,
      height: AppSizes.loadingIndicatorMedium,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withValues(alpha: 0.7),
        ),
      ),
    ).animate().fadeIn(delay: 1000.ms, duration: 400.ms);
  }
}
