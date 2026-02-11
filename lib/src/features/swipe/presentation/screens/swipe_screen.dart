import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants/app_assets.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_strings.dart';
import '../../../../theme/app_theme.dart';
import '../../application/swipe_providers.dart';
import '../widgets/book_card.dart';

/// Main swipe screen with Tinder-like card stack
class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;
  bool _isDragging = false;

  late AnimationController _animController;
  late Animation<Offset> _posAnimation;
  late Animation<double> _angleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _posAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _angleAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _dragAngle = _dragOffset.dx / 300 * 0.3; // subtle rotation
    });
  }

  void _onPanEnd(DragEndDetails details, String isbn) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;

    if (_dragOffset.dx.abs() > threshold) {
      // Swipe completed
      final isLike = _dragOffset.dx > 0;
      _animateOut(isLike, isbn);
    } else {
      // Snap back
      _snapBack();
    }
  }

  void _animateOut(bool isLike, String isbn) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = isLike ? screenWidth * 1.5 : -screenWidth * 1.5;

    _posAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, _dragOffset.dy),
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    ));

    _angleAnimation = Tween<double>(
      begin: _dragAngle,
      end: isLike ? 0.3 : -0.3,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    ));

    _animController.forward(from: 0).then((_) {
      ref.read(bookFeedProvider.notifier).swipe(
            isbn: isbn,
            status: isLike ? 'liked' : 'passed',
          );
      _resetDrag();
    });
  }

  void _snapBack() {
    _posAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _angleAnimation = Tween<double>(
      begin: _dragAngle,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _animController.forward(from: 0).then((_) {
      _resetDrag();
    });
  }

  void _resetDrag() {
    setState(() {
      _dragOffset = Offset.zero;
      _dragAngle = 0;
      _isDragging = false;
    });
  }

  void _onActionButton(bool isLike, String isbn) {
    _animateOut(isLike, isbn);
  }

  @override
  Widget build(BuildContext context) {
    final bookFeed = ref.watch(bookFeedProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppAssets.discover, color: colorScheme.primary, size: 28),
            const SizedBox(width: AppSizes.space8),
            Text(
              AppStrings.appName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      body: bookFeed.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.space32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppAssets.error, size: 64, color: colorScheme.error),
                const SizedBox(height: AppSizes.space16),
                Text(
                  AppStrings.genericError,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSizes.space8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSizes.space24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(bookFeedProvider),
                  child: const Text(AppStrings.tryAgain),
                ),
              ],
            ),
          ),
        ),
        data: (books) {
          if (books.isEmpty) {
            return _buildEmptyState(theme, colorScheme);
          }

          return Column(
            children: [
              // Card stack area
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background cards (stacked behind)
                      for (int i = min(2, books.length - 1); i >= 1; i--)
                        Transform.translate(
                          offset: Offset(0, i * -8.0),
                          child: Transform.scale(
                            scale: 1 - (i * 0.04),
                            child: Opacity(
                              opacity: 1 - (i * 0.15),
                              child: BookCard(book: books[i]),
                            ),
                          ),
                        ),

                      // Top card (draggable)
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          final offset =
                              _isDragging || !_animController.isAnimating
                                  ? _dragOffset
                                  : _posAnimation.value;
                          final angle =
                              _isDragging || !_animController.isAnimating
                                  ? _dragAngle
                                  : _angleAnimation.value;

                          return Transform.translate(
                            offset: offset,
                            child: Transform.rotate(
                              angle: angle,
                              child: child,
                            ),
                          );
                        },
                        child: GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: (details) =>
                              _onPanEnd(details, books[0].isbn),
                          child: Stack(
                            children: [
                              BookCard(book: books[0]),
                              // Like/Pass overlay indicators
                              if (_isDragging) ...[
                                // LIKE indicator
                                Positioned(
                                  top: 40,
                                  left: 24,
                                  child: Opacity(
                                    opacity:
                                        (_dragOffset.dx / 100).clamp(0.0, 1.0),
                                    child: Transform.rotate(
                                      angle: -0.3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSizes.space12,
                                          vertical: AppSizes.space8,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppTheme.likeGreen,
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              AppSizes.radiusSmall),
                                        ),
                                        child: Text(
                                          AppStrings.swipeLike,
                                          style: TextStyle(
                                            color: AppTheme.likeGreen,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // PASS indicator
                                Positioned(
                                  top: 40,
                                  right: 24,
                                  child: Opacity(
                                    opacity:
                                        (-_dragOffset.dx / 100).clamp(0.0, 1.0),
                                    child: Transform.rotate(
                                      angle: 0.3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSizes.space12,
                                          vertical: AppSizes.space8,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppTheme.passRed,
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              AppSizes.radiusSmall),
                                        ),
                                        child: Text(
                                          AppStrings.swipePass,
                                          style: TextStyle(
                                            color: AppTheme.passRed,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.only(
                    bottom: AppSizes.space24, top: AppSizes.space8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pass button
                    _ActionButton(
                      icon: AppAssets.pass,
                      color: AppTheme.passRed,
                      size: 60,
                      onTap: () => _onActionButton(false, books[0].isbn),
                    ),
                    const SizedBox(width: AppSizes.space32),
                    // Like button
                    _ActionButton(
                      icon: AppAssets.like,
                      color: colorScheme.primary,
                      size: 60,
                      onTap: () => _onActionButton(true, books[0].isbn),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppAssets.bookPlaceholder,
              size: 80,
              color: colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: AppSizes.space24),
            Text(
              AppStrings.allBooksSeen,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.space8),
            Text(
              AppStrings.checkBackLater,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.space32),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(bookFeedProvider),
              icon: const Icon(AppAssets.refresh),
              label: const Text(AppStrings.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular action button for pass/like
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: size * 0.45),
        ),
      ),
    );
  }
}
