import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../swipe/domain/models/book.dart';

part 'library_providers.g.dart';

/// Provider for the user's liked/saved books
@riverpod
Future<List<Book>> userLibrary(UserLibraryRef ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  // Fetch books that user has liked, joined with book details
  final response = await supabase
      .from('user_books')
      .select('isbn, status, books(*)')
      .eq('user_id', userId)
      .eq('status', 'liked')
      .order('swiped_at', ascending: false);

  final books = <Book>[];
  for (final row in (response as List)) {
    final bookData = row['books'];
    if (bookData != null) {
      books.add(Book.fromJson(bookData as Map<String, dynamic>));
    }
  }
  return books;
}
