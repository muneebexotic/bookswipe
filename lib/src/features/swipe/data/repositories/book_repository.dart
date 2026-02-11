import '../../domain/models/book.dart';

/// Abstract repository for book operations
abstract class BookRepository {
  /// Fetch a batch of unswiped books for the current user
  Future<List<Book>> fetchUnswipedBooks({int limit = 10});

  /// Record a swipe action (like or pass)
  Future<void> recordSwipe({
    required String isbn,
    required String status,
  });
}
