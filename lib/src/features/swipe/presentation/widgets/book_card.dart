import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../constants/app_assets.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/book.dart';

/// A single book card displayed in the swipe stack
class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width * 0.9,
      height: size.height * 0.7,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image
            _buildCoverImage(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.35, 0.55, 1.0],
                ),
              ),
            ),

            // Book info at bottom
            Positioned(
              left: AppSizes.space24,
              right: AppSizes.space24,
              bottom: AppSizes.space24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    book.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.space4),

                  // Author
                  Text(
                    book.author ?? 'Unknown Author',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppSizes.space12),

                  // Hook / description
                  if (book.generatedHook != null)
                    Text(
                      book.generatedHook!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: AppSizes.space16),

                  // Spice rating + mood chips row
                  Row(
                    children: [
                      // Spice rating
                      if (book.spiceRating != null) ...[
                        _buildSpiceRating(book.spiceRating!),
                        const SizedBox(width: AppSizes.space12),
                      ],

                      // Page count
                      if (book.pageCount != null)
                        _buildInfoChip(
                          AppAssets.pages,
                          '${book.pageCount}p',
                          colorScheme,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Trope chips
                  if (book.tropes.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: book.tropes
                          .take(3)
                          .map((trope) => _buildTropeChip(trope, colorScheme))
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    if (book.coverUrl != null && book.coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: book.coverUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppTheme.charcoal,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholderCover(),
      );
    }
    return _buildPlaceholderCover();
  }

  Widget _buildPlaceholderCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.coralPrimary, AppTheme.coralDark],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppAssets.bookPlaceholder,
                size: 64, color: Colors.white54),
            const SizedBox(height: AppSizes.space16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.space32),
              child: Text(
                book.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpiceRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? AppAssets.spice : AppAssets.spiceOutlined,
          color: index < rating ? AppTheme.coralPrimary : Colors.white38,
          size: 18,
        );
      }),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.space8, vertical: AppSizes.space4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: AppSizes.space4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTropeChip(String trope, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.space12, vertical: AppSizes.space4 + 1),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        trope,
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
