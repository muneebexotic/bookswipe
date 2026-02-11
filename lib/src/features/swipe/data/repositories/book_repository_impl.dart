import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/book.dart';
import 'book_repository.dart';

/// Supabase implementation of BookRepository
class BookRepositoryImpl implements BookRepository {
  final SupabaseClient _client;

  BookRepositoryImpl(this._client);

  @override
  Future<List<Book>> fetchUnswipedBooks({int limit = 10}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Step 1: Get ISBNs the user has already swiped on
    final swipedResponse =
        await _client.from('user_books').select('isbn').eq('user_id', userId);
    final swipedIsbns =
        (swipedResponse as List).map((e) => e['isbn'] as String).toList();

    // Step 2: Fetch enriched books excluding already-swiped ones
    var query = _client.from('books').select().eq('is_enriched', 1);

    if (swipedIsbns.isNotEmpty) {
      query = query.not('isbn', 'in', swipedIsbns);
    }

    final response =
        await query.order('popularity_score', ascending: false).limit(limit);

    return (response as List)
        .map((json) => Book.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> recordSwipe({
    required String isbn,
    required String status,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('user_books').upsert({
      'user_id': userId,
      'isbn': isbn,
      'status': status,
      'swiped_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,isbn');
  }
}
