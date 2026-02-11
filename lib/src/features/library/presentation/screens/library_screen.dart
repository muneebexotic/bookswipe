import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../constants/app_assets.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_strings.dart';
import '../../../../theme/app_theme.dart';
import '../../application/library_providers.dart';
import '../../../swipe/domain/models/book.dart';

/// Library screen showing the user's liked books
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final library = ref.watch(userLibraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myLibrary),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(userLibraryProvider),
            icon: const Icon(AppAssets.refresh),
          ),
        ],
      ),
      body: library.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.space32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppAssets.error, size: 48, color: colorScheme.error),
                const SizedBox(height: AppSizes.space16),
                Text(AppStrings.failedToLoadLibrary,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSizes.space8),
                Text(error.toString(),
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSizes.space16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(userLibraryProvider),
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
        data: (books) {
          if (books.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.space32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppAssets.bookPlaceholder,
                        size: 80, color: colorScheme.primary.withOpacity(0.3)),
                    const SizedBox(height: AppSizes.space24),
                    Text(AppStrings.noBooks,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSizes.space8),
                    Text(AppStrings.noBooksHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSizes.space16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: AppSizes.space12,
              mainAxisSpacing: AppSizes.space12,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) => _BookTile(book: books[index]),
          );
        },
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final Book book;
  const _BookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.overlayLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image
            Expanded(
              flex: 3,
              child: _buildCover(colorScheme),
            ),

            // Book info
            Expanded(
              flex: 2,
              child: Container(
                color: theme.cardTheme.color ?? theme.scaffoldBackgroundColor,
                padding: const EdgeInsets.all(AppSizes.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author ?? AppStrings.unknownAuthor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    // Spice rating
                    if (book.spiceRating != null)
                      Row(
                        children: List.generate(
                            5,
                            (i) => Icon(
                                  i < book.spiceRating!
                                      ? Icons.local_fire_department
                                      : Icons.local_fire_department_outlined,
                                  size: 14,
                                  color: i < book.spiceRating!
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant
                                          .withOpacity(0.3),
                                )),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(ColorScheme colorScheme) {
    if (book.coverUrl != null && book.coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: book.coverUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => _placeholderCover(colorScheme),
      );
    }
    return _placeholderCover(colorScheme);
  }

  Widget _placeholderCover(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary.withOpacity(0.15),
      child: Center(
        child: Icon(AppAssets.bookPlaceholder,
            size: 36, color: colorScheme.primary.withOpacity(0.5)),
      ),
    );
  }
}
