import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/supabase_provider.dart';
import '../data/repositories/book_repository.dart';
import '../data/repositories/book_repository_impl.dart';
import '../domain/models/book.dart';

part 'swipe_providers.g.dart';

/// Provider for BookRepository
@riverpod
BookRepository bookRepository(BookRepositoryRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return BookRepositoryImpl(supabase);
}

/// Provider for the book feed (list of unswiped books)
@riverpod
class BookFeed extends _$BookFeed {
  @override
  Future<List<Book>> build() async {
    final repository = ref.watch(bookRepositoryProvider);
    return repository.fetchUnswipedBooks(limit: 20);
  }

  /// Remove the top card after a swipe
  void removeTopCard() {
    final currentBooks = state.valueOrNull;
    if (currentBooks != null && currentBooks.isNotEmpty) {
      state = AsyncData(currentBooks.sublist(1));

      // Prefetch more books when running low
      if (currentBooks.length <= 3) {
        _prefetchBooks();
      }
    }
  }

  /// Prefetch more books
  Future<void> _prefetchBooks() async {
    final repository = ref.read(bookRepositoryProvider);
    final moreBooks = await repository.fetchUnswipedBooks(limit: 20);
    final currentBooks = state.valueOrNull ?? [];
    state = AsyncData([...currentBooks, ...moreBooks]);
  }

  /// Record a swipe and remove the card
  Future<void> swipe({
    required String isbn,
    required String status,
  }) async {
    final repository = ref.read(bookRepositoryProvider);
    await repository.recordSwipe(isbn: isbn, status: status);
    removeTopCard();
  }
}
