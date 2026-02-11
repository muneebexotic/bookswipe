---
inclusion: always
---

# 🗄️ Supabase Integration Best Practices

> Professional patterns for Supabase with Flutter

## Setup & Configuration

### 1. Environment Variables

```dart
// .env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

// lib/src/config/supabase_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await dotenv.load();
    
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
}
```

### 2. Provider Setup

```dart
// lib/src/core/providers/supabase_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_provider.g.dart';

@riverpod
SupabaseClient supabaseClient(SupabaseClientRef ref) {
  return Supabase.instance.client;
}
```

## Authentication Patterns

### 1. Email/Password Auth

```dart
// Data Source
class SupabaseAuthDataSource {
  final SupabaseClient _client;
  
  const SupabaseAuthDataSource(this._client);
  
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw AuthException('Sign in failed');
      }
      
      return response.user!;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  Future<User> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
      
      if (response.user == null) {
        throw AuthException('Sign up failed');
      }
      
      return response.user!;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
}
```

### 2. OAuth (Google, Apple, etc.)

```dart
Future<User> signInWithGoogle() async {
  try {
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.bookswipe://login-callback',
    );
    
    if (!response) {
      throw AuthException('Google sign in cancelled');
    }
    
    // Wait for auth state change
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('Google sign in failed');
    }
    
    return user;
  } on AuthException catch (e) {
    throw _handleAuthException(e);
  }
}
```

### 3. Auth State Listening

```dart
@riverpod
Stream<AuthState> authStateChanges(AuthStateChangesRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  
  return supabase.auth.onAuthStateChange.map((event) {
    final session = event.session;
    final user = session?.user;
    
    if (user != null) {
      return AuthState.authenticated(user: UserModel.fromSupabaseUser(user));
    } else {
      return const AuthState.unauthenticated();
    }
  });
}
```

## Database Operations

### 1. CRUD Operations

```dart
class SupabaseBookDataSource {
  final SupabaseClient _client;
  
  const SupabaseBookDataSource(this._client);
  
  // Create
  Future<Book> createBook(Book book) async {
    try {
      final response = await _client
          .from('books')
          .insert(book.toJson())
          .select()
          .single();
      
      return Book.fromJson(response);
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e);
    }
  }
  
  // Read (single)
  Future<Book> getBookById(String id) async {
    try {
      final response = await _client
          .from('books')
          .select()
          .eq('id', id)
          .single();
      
      return Book.fromJson(response);
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e);
    }
  }
  
  // Read (list with filters)
  Future<List<Book>> getBooks({
    String? genre,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('books').select();
      
      if (genre != null) {
        query = query.eq('genre', genre);
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return (response as List)
          .map((json) => Book.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e);
    }
  }
  
  // Update
  Future<Book> updateBook(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _client
          .from('books')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      
      return Book.fromJson(response);
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e);
    }
  }
  
  // Delete
  Future<void> deleteBook(String id) async {
    try {
      await _client.from('books').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e);
    }
  }
}
```

### 2. Complex Queries with Joins

```dart
Future<List<BookWithAuthor>> getBooksWithAuthors() async {
  try {
    final response = await _client
        .from('books')
        .select('*, authors(*)')
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => BookWithAuthor.fromJson(json))
        .toList();
  } on PostgrestException catch (e) {
    throw _handlePostgrestException(e);
  }
}
```

### 3. Full-Text Search

```dart
Future<List<Book>> searchBooks(String query) async {
  try {
    final response = await _client
        .from('books')
        .select()
        .textSearch('title', query, config: 'english')
        .limit(20);
    
    return (response as List)
        .map((json) => Book.fromJson(json))
        .toList();
  } on PostgrestException catch (e) {
    throw _handlePostgrestException(e);
  }
}
```

## Real-Time Subscriptions

### 1. Basic Subscription

```dart
@riverpod
Stream<List<Message>> chatMessages(ChatMessagesRef ref, String chatId) {
  final supabase = ref.watch(supabaseClientProvider);
  
  return supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('chat_id', chatId)
      .order('created_at')
      .map((data) => data.map((json) => Message.fromJson(json)).toList());
}
```

### 2. Filtered Subscription

```dart
@riverpod
Stream<List<Notification>> userNotifications(
  UserNotificationsRef ref,
  String userId,
) {
  final supabase = ref.watch(supabaseClientProvider);
  
  return supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .eq('read', false)
      .order('created_at', ascending: false)
      .map((data) => 
        data.map((json) => Notification.fromJson(json)).toList()
      );
}
```

## Storage Operations

### 1. Upload File

```dart
Future<String> uploadBookCover(String bookId, File imageFile) async {
  try {
    final fileName = '$bookId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'book-covers/$fileName';
    
    await _client.storage.from('public').upload(
      path,
      imageFile,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: false,
      ),
    );
    
    final publicUrl = _client.storage.from('public').getPublicUrl(path);
    return publicUrl;
  } on StorageException catch (e) {
    throw _handleStorageException(e);
  }
}
```

### 2. Download File

```dart
Future<Uint8List> downloadBookCover(String path) async {
  try {
    final bytes = await _client.storage.from('public').download(path);
    return bytes;
  } on StorageException catch (e) {
    throw _handleStorageException(e);
  }
}
```

### 3. Delete File

```dart
Future<void> deleteBookCover(String path) async {
  try {
    await _client.storage.from('public').remove([path]);
  } on StorageException catch (e) {
    throw _handleStorageException(e);
  }
}
```

## Error Handling

```dart
Exception _handleAuthException(AuthException e) {
  switch (e.statusCode) {
    case '400':
      return const AuthFailure.invalidCredentials();
    case '422':
      return const AuthFailure.emailAlreadyInUse();
    case '429':
      return const AuthFailure.tooManyRequests();
    default:
      return AuthFailure.serverError(e.message);
  }
}

Exception _handlePostgrestException(PostgrestException e) {
  if (e.code == 'PGRST116') {
    return const DataFailure.notFound();
  } else if (e.code == '23505') {
    return const DataFailure.duplicateEntry();
  } else {
    return DataFailure.serverError(e.message);
  }
}

Exception _handleStorageException(StorageException e) {
  if (e.statusCode == '404') {
    return const StorageFailure.fileNotFound();
  } else if (e.statusCode == '413') {
    return const StorageFailure.fileTooLarge();
  } else {
    return StorageFailure.serverError(e.message);
  }
}
```

## Row Level Security (RLS)

### Best Practices

1. **Always enable RLS on tables**
2. **Create policies for each operation (SELECT, INSERT, UPDATE, DELETE)**
3. **Use auth.uid() for user-specific data**
4. **Test policies thoroughly**

### Example Policies

```sql
-- Users can only read their own profile
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
USING (auth.uid() = user_id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = user_id);

-- Anyone can read public books
CREATE POLICY "Anyone can view books"
ON books FOR SELECT
USING (true);

-- Only authenticated users can like books
CREATE POLICY "Authenticated users can like books"
ON book_likes FOR INSERT
WITH CHECK (auth.uid() = user_id);
```

## Performance Optimization

### 1. Use Indexes

```sql
-- Index for frequently queried columns
CREATE INDEX idx_books_genre ON books(genre);
CREATE INDEX idx_books_author_id ON books(author_id);
CREATE INDEX idx_book_likes_user_id ON book_likes(user_id);

-- Composite index for common query patterns
CREATE INDEX idx_books_genre_created ON books(genre, created_at DESC);
```

### 2. Pagination

```dart
Future<List<Book>> getBooksPaginated({
  required int page,
  required int pageSize,
}) async {
  final offset = page * pageSize;
  
  final response = await _client
      .from('books')
      .select()
      .range(offset, offset + pageSize - 1)
      .order('created_at', ascending: false);
  
  return (response as List)
      .map((json) => Book.fromJson(json))
      .toList();
}
```

### 3. Select Only Needed Columns

```dart
// ❌ BAD: Fetching all columns
final response = await _client.from('books').select();

// ✅ GOOD: Fetching only needed columns
final response = await _client
    .from('books')
    .select('id, title, author_id, cover_url');
```

### 4. Use Count for Pagination Metadata

```dart
Future<PaginatedResult<Book>> getBooksWithCount({
  required int page,
  required int pageSize,
}) async {
  final offset = page * pageSize;
  
  final response = await _client
      .from('books')
      .select('*', const FetchOptions(count: CountOption.exact))
      .range(offset, offset + pageSize - 1);
  
  final books = (response.data as List)
      .map((json) => Book.fromJson(json))
      .toList();
  
  return PaginatedResult(
    data: books,
    total: response.count ?? 0,
    page: page,
    pageSize: pageSize,
  );
}
```

## Testing with Supabase

### 1. Mock Supabase Client

```dart
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockPostgrestClient extends Mock implements PostgrestClient {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late SupabaseAuthDataSource dataSource;
  
  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    dataSource = SupabaseAuthDataSource(mockSupabase);
  });
  
  test('signIn returns user on success', () async {
    final mockUser = User(id: '123', email: 'test@example.com');
    final mockResponse = AuthResponse(user: mockUser, session: null);
    
    when(() => mockAuth.signInWithPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => mockResponse);
    
    final result = await dataSource.signInWithEmail(
      email: 'test@example.com',
      password: 'password123',
    );
    
    expect(result.id, '123');
    expect(result.email, 'test@example.com');
  });
}
```

---

> **Security Note**: Never commit .env files. Always use .env.example as template.
