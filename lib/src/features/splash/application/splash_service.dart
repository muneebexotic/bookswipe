import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_service.g.dart';

/// Service for managing splash screen logic
@riverpod
class SplashService extends _$SplashService {
  @override
  Future<void> build() async {
    // Initialize any required services here
    await _initializeApp();
  }

  /// Initialize application services
  Future<void> _initializeApp() async {
    // Simulate initialization delay
    await Future.delayed(const Duration(seconds: 2));

    // Add actual initialization logic here:
    // - Check authentication status
    // - Load user preferences
    // - Initialize analytics
    // - Preload critical data
  }

  /// Get the splash screen display duration
  Duration get splashDuration => const Duration(seconds: 3);
}
