---
inclusion: always
---

# 🔄 Riverpod State Management Patterns

> Professional patterns for Riverpod 2.x with code generation

## Provider Types & When to Use

### 1. Provider (Immutable, Sync)

Use for: Constants, configurations, simple computed values

```dart
@riverpod
String apiBaseUrl(ApiBaseUrlRef ref) {
  return dotenv.env['API_URL'] ?? 'https://api.example.com';
}

@riverpod
ThemeMode themeMode(ThemeModeRef ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.themeMode;
}
```

### 2. FutureProvider (Async, Read-only)

Use for: One-time async data fetching, initialization

```dart
@riverpod
Future<User> currentUser(CurrentUserRef ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUser();
}

@riverpod
Future<AppConfig> appConfig(AppConfigRef ref) async {
  final configService = ref.watch(configServiceProvider);
  return configService.loadConfig();
}
```

### 3. StreamProvider (Async Stream, Read-only)

Use for: Real-time data, subscriptions, continuous updates

```dart
@riverpod
Stream<List<Message>> chatMessages(ChatMessagesRef ref, String chatId) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('chat_id', chatId)
      .map((data) => data.map((json) => Message.fromJson(json)).toList());
}

@riverpod
Stream<AuthState> authStateChanges(AuthStateChangesRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.onAuthStateChange.map((event) {
    return AuthState.fromSupabaseAuthState(event);
  });
}
```

### 4. NotifierProvider (Stateful, Sync)

Use for: Mutable state, synchronous state updates

```dart
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

@riverpod
class SwipeStack extends _$SwipeStack {
  @override
  List<Book> build() => [];

  void addBooks(List<Book> books) {
    state = [...state, ...books];
  }

  void removeTop() {
    if (state.isNotEmpty) {
      state = state.sublist(1);
    }
  }

  void undo(Book book) {
    state = [book, ...state];
  }
}
```

### 5. AsyncNotifierProvider (Stateful, Async)

Use for: Async state with mutations, CRUD operations

```dart
@riverpod
class BookList extends _$BookList {
  @override
  Future<List<Book>> build() async {
    final repository = ref.watch(bookRepositoryProvider);
    return repository.fetchBooks();
  }

  Future<void> addBook(Book book) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(bookRepositoryProvider);
      await repository.addBook(book);
      return [...state.value ?? [], book];
    });
  }

  Future<void> deleteBook(String bookId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(bookRepositoryProvider);
      await repository.deleteBook(bookId);
      return state.value?.where((b) => b.id != bookId).toList() ?? [];
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(bookRepositoryProvider);
      return repository.fetchBooks();
    });
  }
}
```

## Advanced Patterns

### 1. Family Providers (Parameterized)

```dart
// Single parameter
@riverpod
Future<Book> bookDetail(BookDetailRef ref, String bookId) async {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getBookById(bookId);
}

// Multiple parameters
@riverpod
Future<List<Book>> booksByGenre(
  BooksByGenreRef ref, {
  required String genre,
  required int limit,
}) async {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getBooksByGenre(genre, limit: limit);
}

// Usage in UI
final book = ref.watch(bookDetailProvider('book-123'));
final sciFiBooks = ref.watch(booksByGenreProvider(genre: 'sci-fi', limit: 10));
```

### 2. Dependent Providers

```dart
@riverpod
Future<User> currentUser(CurrentUserRef ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUser();
}

@riverpod
Future<UserProfile> userProfile(UserProfileRef ref) async {
  // Depends on currentUser
  final user = await ref.watch(currentUserProvider.future);
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfile(user.id);
}

@riverpod
Future<List<Book>> recommendedBooks(RecommendedBooksRef ref) async {
  // Depends on userProfile
  final profile = await ref.watch(userProfileProvider.future);
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getRecommendations(profile.preferences);
}
```

### 3. Combining Multiple Providers

```dart
@riverpod
Future<DashboardData> dashboardData(DashboardDataRef ref) async {
  // Fetch multiple data sources in parallel
  final results = await Future.wait([
    ref.watch(currentUserProvider.future),
    ref.watch(userStatsProvider.future),
    ref.watch(recentBooksProvider.future),
  ]);

  return DashboardData(
    user: results[0] as User,
    stats: results[1] as UserStats,
    recentBooks: results[2] as List<Book>,
  );
}
```

### 4. Caching & Auto-Dispose

```dart
// Keep alive for 5 minutes
@Riverpod(keepAlive: true)
Future<AppConfig> appConfig(AppConfigRef ref) async {
  final timer = Timer(const Duration(minutes: 5), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);
  
  final configService = ref.watch(configServiceProvider);
  return configService.loadConfig();
}

// Auto-dispose when no longer watched
@riverpod
Future<List<Book>> searchResults(SearchResultsRef ref, String query) async {
  // Automatically disposed when widget is unmounted
  final repository = ref.watch(bookRepositoryProvider);
  return repository.search(query);
}
```

### 5. Listening to Providers

```dart
// In a widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Listen for side effects
  ref.listen<AsyncValue<AuthState>>(
    authControllerProvider,
    (previous, next) {
      next.whenData((authState) {
        if (authState.status == AuthStatus.authenticated) {
          context.go('/home');
        } else if (authState.status == AuthStatus.unauthenticated) {
          context.go('/login');
        }
      });
    },
  );

  return Scaffold(/* ... */);
}
```

### 6. Error Handling Patterns

```dart
@riverpod
class BookList extends _$BookList {
  @override
  Future<List<Book>> build() async {
    return _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    try {
      final repository = ref.read(bookRepositoryProvider);
      return await repository.fetchBooks();
    } on NetworkException {
      throw const BookFailure.networkError();
    } on ServerException catch (e) {
      throw BookFailure.serverError(e.message);
    } catch (e) {
      throw BookFailure.unknown(e.toString());
    }
  }

  Future<void> retry() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchBooks);
  }
}

// In UI
ref.watch(bookListProvider).when(
  data: (books) => BookListView(books),
  loading: () => const LoadingIndicator(),
  error: (error, stack) {
    if (error is BookFailure) {
      return error.when(
        networkError: () => NetworkErrorView(
          onRetry: () => ref.read(bookListProvider.notifier).retry(),
        ),
        serverError: (msg) => ServerErrorView(message: msg),
        unknown: (msg) => GenericErrorView(message: msg),
      );
    }
    return GenericErrorView(message: error.toString());
  },
);
```

## UI Integration Patterns

### 1. ConsumerWidget (Simple)

```dart
class BookListScreen extends ConsumerWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(bookListProvider);
    
    return booksAsync.when(
      data: (books) => ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) => BookCard(books[index]),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorView(error: error),
    );
  }
}
```

### 2. ConsumerStatefulWidget (With State)

```dart
class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(swipeStackProvider);
    
    return PageView.builder(
      controller: _pageController,
      itemCount: books.length,
      itemBuilder: (context, index) => SwipeCard(books[index]),
    );
  }
}
```

### 3. Consumer (Scoped)

```dart
class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.bookId});
  final String bookId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Details')),
      body: Consumer(
        builder: (context, ref, child) {
          final bookAsync = ref.watch(bookDetailProvider(bookId));
          
          return bookAsync.when(
            data: (book) => BookDetailView(book),
            loading: () => const LoadingIndicator(),
            error: (error, stack) => ErrorView(error: error),
          );
        },
      ),
    );
  }
}
```

## Testing Patterns

### 1. Provider Override

```dart
void main() {
  testWidgets('displays book list', (tester) async {
    final mockRepository = MockBookRepository();
    when(() => mockRepository.fetchBooks()).thenAnswer(
      (_) async => [Book(id: '1', title: 'Test Book')],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const MaterialApp(home: BookListScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Test Book'), findsOneWidget);
  });
}
```

### 2. Testing Notifiers

```dart
void main() {
  test('Counter increments correctly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(counterProvider), 0);
    
    container.read(counterProvider.notifier).increment();
    expect(container.read(counterProvider), 1);
    
    container.read(counterProvider.notifier).increment();
    expect(container.read(counterProvider), 2);
  });

  test('BookList fetches and adds books', () async {
    final mockRepository = MockBookRepository();
    when(() => mockRepository.fetchBooks()).thenAnswer(
      (_) async => [Book(id: '1', title: 'Book 1')],
    );

    final container = ProviderContainer(
      overrides: [
        bookRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);

    // Wait for initial load
    await container.read(bookListProvider.future);
    
    final books = container.read(bookListProvider).value!;
    expect(books.length, 1);
    expect(books[0].title, 'Book 1');
  });
}
```

## Common Pitfalls & Solutions

### ❌ DON'T: Read providers in build without watch

```dart
// BAD: Won't rebuild on changes
@override
Widget build(BuildContext context, WidgetRef ref) {
  final count = ref.read(counterProvider); // ❌
  return Text('$count');
}
```

### ✅ DO: Use watch for reactive updates

```dart
// GOOD: Rebuilds when counter changes
@override
Widget build(BuildContext context, WidgetRef ref) {
  final count = ref.watch(counterProvider); // ✅
  return Text('$count');
}
```

### ❌ DON'T: Use watch in event handlers

```dart
// BAD: watch should not be in callbacks
ElevatedButton(
  onPressed: () {
    final notifier = ref.watch(counterProvider.notifier); // ❌
    notifier.increment();
  },
  child: const Text('Increment'),
)
```

### ✅ DO: Use read in event handlers

```dart
// GOOD: read is for one-time access
ElevatedButton(
  onPressed: () {
    ref.read(counterProvider.notifier).increment(); // ✅
  },
  child: const Text('Increment'),
)
```

### ❌ DON'T: Mutate state directly

```dart
@riverpod
class BookList extends _$BookList {
  @override
  List<Book> build() => [];

  void addBook(Book book) {
    state.add(book); // ❌ Mutating state directly
  }
}
```

### ✅ DO: Create new state instances

```dart
@riverpod
class BookList extends _$BookList {
  @override
  List<Book> build() => [];

  void addBook(Book book) {
    state = [...state, book]; // ✅ New list instance
  }
}
```

## Performance Optimization

### 1. Select Specific Values

```dart
// Instead of watching entire object
final user = ref.watch(userProvider);
final name = user.name;

// Watch only what you need
final name = ref.watch(userProvider.select((user) => user.name));
```

### 2. Use keepAlive Strategically

```dart
// Expensive computation that should be cached
@Riverpod(keepAlive: true)
Future<ProcessedData> expensiveComputation(ExpensiveComputationRef ref) async {
  // This will be computed once and cached
  return await heavyProcessing();
}
```

### 3. Debounce User Input

```dart
@riverpod
class SearchQuery extends _$SearchQuery {
  Timer? _debounceTimer;

  @override
  String build() => '';

  void updateQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = query;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

@riverpod
Future<List<Book>> searchResults(SearchResultsRef ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  
  final repository = ref.watch(bookRepositoryProvider);
  return repository.search(query);
}
```

---

> **Pro Tip**: Use Riverpod's DevTools extension to debug provider state and dependencies in real-time.
