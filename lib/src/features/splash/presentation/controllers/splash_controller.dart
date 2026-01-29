import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../application/splash_service.dart';

part 'splash_controller.g.dart';

/// Controller for splash screen navigation logic
@riverpod
class SplashController extends _$SplashController {
  @override
  Future<bool> build() async {
    // Wait for splash service initialization
    await ref.watch(splashServiceProvider.future);

    // Add additional delay for splash animation
    await Future.delayed(const Duration(seconds: 1));

    // Return true to indicate splash is complete
    return true;
  }

  /// Check if splash screen should navigate to login or home
  Future<String> getNextRoute() async {
    // TODO: Check authentication status
    // final authState = await ref.read(authServiceProvider.future);
    // return authState.isAuthenticated ? '/home' : '/login';

    // For now, always navigate to login
    return '/login';
  }
}
