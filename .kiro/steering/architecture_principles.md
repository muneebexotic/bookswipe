---
inclusion: always
---

# 🏛️ Architecture Principles & Best Practices

> Enterprise-grade architectural guidelines for BookSwipe

## Core Architectural Principles

### 1. SOLID Principles

#### Single Responsibility Principle (SRP)
- Each class/module has ONE reason to change
- Controllers handle UI state, Services handle business logic, Repositories handle data access
- Example: `AuthController` manages auth UI state, `AuthService` handles auth business logic

#### Open/Closed Principle (OCP)
- Open for extension, closed for modification
- Use abstract classes/interfaces for repositories
- Extend functionality through composition, not modification

#### Liskov Substitution Principle (LSP)
- Implementations must be substitutable for their abstractions
- All `AuthRepository` implementations must honor the contract

#### Interface Segregation Principle (ISP)
- Clients shouldn't depend on interfaces they don't use
- Split large repositories into focused ones (e.g., `UserProfileRepository`, `UserPreferencesRepository`)

#### Dependency Inversion Principle (DIP)
- Depend on abstractions, not concretions
- Controllers depend on repository interfaces, not implementations
- Use Riverpod for dependency injection

### 2. Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Screens, Widgets, Controllers)        │
│  - UI components                        │
│  - User interaction handling            │
│  - State management (Riverpod)          │
└─────────────────────────────────────────┘
              ↓ depends on
┌─────────────────────────────────────────┐
│        Application Layer                │
│     (Services, Use Cases)               │
│  - Business logic orchestration         │
│  - Cross-feature coordination           │
│  - Application-specific rules           │
└─────────────────────────────────────────┘
              ↓ depends on
┌─────────────────────────────────────────┐
│          Domain Layer                   │
│      (Models, Entities, Enums)          │
│  - Core business entities               │
│  - Business rules                       │
│  - NO external dependencies             │
└─────────────────────────────────────────┘
              ↑ used by
┌─────────────────────────────────────────┐
│           Data Layer                    │
│  (Repositories, Data Sources, DTOs)     │
│  - Data access implementation           │
│  - External API communication           │
│  - Data transformation (DTO → Model)    │
└─────────────────────────────────────────┘
```

### 3. Dependency Rule

**CRITICAL**: Dependencies flow INWARD only
- Presentation → Application → Domain ← Data
- Domain layer has ZERO external dependencies
- Data layer depends on Domain for models
- Never import presentation code into data layer

### 4. Feature-First Organization

```
features/
├── auth/           # Self-contained authentication feature
│   ├── data/       # Auth-specific data access
│   ├── domain/     # Auth models & entities
│   ├── application/# Auth business logic
│   └── presentation/# Auth UI
└── books/          # Self-contained books feature
    ├── data/
    ├── domain/
    ├── application/
    └── presentation/
```

**Benefits:**
- High cohesion within features
- Low coupling between features
- Easy to add/remove features
- Parallel development by teams
- Clear ownership boundaries

## Code Quality Standards

### 1. Immutability First

```dart
// ✅ GOOD: Immutable with Freezed
@freezed
class Book with _$Book {
  const factory Book({
    required String id,
    required String title,
    required String author,
  }) = _Book;
}

// ❌ BAD: Mutable class
class Book {
  String id;
  String title;
  String author;
}
```

### 2. Null Safety

```dart
// ✅ GOOD: Explicit null handling
String? getUserName(User? user) {
  return user?.name ?? 'Guest';
}

// ❌ BAD: Force unwrapping
String getUserName(User? user) {
  return user!.name; // Dangerous!
}
```

### 3. Error Handling

```dart
// ✅ GOOD: Typed errors with sealed classes
@freezed
class AuthFailure with _$AuthFailure {
  const factory AuthFailure.invalidCredentials() = _InvalidCredentials;
  const factory AuthFailure.networkError() = _NetworkError;
  const factory AuthFailure.serverError(String message) = _ServerError;
}

// Use Either<Failure, Success> pattern
Future<Either<AuthFailure, User>> signIn(String email, String password);
```

### 4. Async State Management

```dart
// ✅ GOOD: Use AsyncValue for loading states
@riverpod
class BookList extends _$BookList {
  @override
  Future<List<Book>> build() async {
    return _fetchBooks();
  }
}

// In UI
ref.watch(bookListProvider).when(
  data: (books) => BookListView(books),
  loading: () => LoadingIndicator(),
  error: (error, stack) => ErrorView(error),
);
```

## Testing Strategy

### Test Pyramid

```
        ┌─────────────┐
        │   E2E (5%)  │  Integration tests
        ├─────────────┤
        │ Widget (25%)│  UI component tests
        ├─────────────┤
        │  Unit (70%) │  Business logic tests
        └─────────────┘
```

### Coverage Requirements

- **Unit Tests**: 80%+ coverage for business logic
- **Widget Tests**: All reusable components
- **Integration Tests**: Critical user flows

### Test Structure

```dart
// Arrange-Act-Assert pattern
void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockAuthRepository();
      authService = AuthService(mockRepo);
    });

    test('signIn returns user on success', () async {
      // Arrange
      final email = 'test@example.com';
      final password = 'password123';
      final expectedUser = User(id: '1', email: email);
      when(() => mockRepo.signIn(email, password))
          .thenAnswer((_) async => Right(expectedUser));

      // Act
      final result = await authService.signIn(email, password);

      // Assert
      expect(result, Right(expectedUser));
      verify(() => mockRepo.signIn(email, password)).called(1);
    });
  });
}
```

## Performance Best Practices

### 1. Widget Optimization

```dart
// ✅ GOOD: Use const constructors
const Text('Hello World')

// ✅ GOOD: Extract widgets instead of methods
class _BookTitle extends StatelessWidget {
  const _BookTitle(this.title);
  final String title;
  
  @override
  Widget build(BuildContext context) => Text(title);
}

// ❌ BAD: Widget-returning methods
Widget _buildTitle(String title) => Text(title);
```

### 2. List Performance

```dart
// ✅ GOOD: Use builder for long lists
ListView.builder(
  itemCount: books.length,
  itemBuilder: (context, index) => BookCard(books[index]),
)

// ❌ BAD: Creating all widgets upfront
ListView(
  children: books.map((book) => BookCard(book)).toList(),
)
```

### 3. Image Optimization

```dart
// ✅ GOOD: Cached network images
CachedNetworkImage(
  imageUrl: book.coverUrl,
  placeholder: (context, url) => ShimmerLoading(),
  errorWidget: (context, url, error) => PlaceholderImage(),
  memCacheWidth: 300, // Resize for memory efficiency
)
```

## Security Best Practices

### 1. Environment Variables

```dart
// ✅ GOOD: Use environment variables for secrets
final supabaseUrl = dotenv.env['SUPABASE_URL']!;
final supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;

// ❌ BAD: Hardcoded secrets
const supabaseUrl = 'https://xxx.supabase.co';
```

### 2. Input Validation

```dart
// ✅ GOOD: Validate all user input
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) {
    return 'Enter a valid email';
  }
  return null;
}
```

### 3. Secure Storage

```dart
// ✅ GOOD: Use secure storage for sensitive data
final secureStorage = FlutterSecureStorage();
await secureStorage.write(key: 'auth_token', value: token);

// ❌ BAD: SharedPreferences for tokens
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', token); // Not encrypted!
```

## Documentation Standards

### 1. Class Documentation

```dart
/// Service responsible for managing user authentication.
///
/// Handles sign in, sign up, password reset, and session management.
/// Uses [AuthRepository] for data access and emits [AuthState] updates.
///
/// Example:
/// ```dart
/// final authService = ref.watch(authServiceProvider);
/// await authService.signIn(email: 'user@example.com', password: 'pass123');
/// ```
class AuthService {
  // ...
}
```

### 2. Method Documentation

```dart
/// Signs in a user with email and password.
///
/// Returns [Right<User>] on success or [Left<AuthFailure>] on failure.
///
/// Throws [NetworkException] if there's no internet connection.
///
/// Example:
/// ```dart
/// final result = await authService.signIn(
///   email: 'user@example.com',
///   password: 'password123',
/// );
/// result.fold(
///   (failure) => print('Error: $failure'),
///   (user) => print('Welcome ${user.name}'),
/// );
/// ```
Future<Either<AuthFailure, User>> signIn({
  required String email,
  required String password,
}) async {
  // ...
}
```

## Code Review Checklist

### Before Submitting PR

- [ ] All tests pass (`flutter test`)
- [ ] No linting errors (`flutter analyze`)
- [ ] Code formatted (`dart format .`)
- [ ] Documentation added for public APIs
- [ ] No hardcoded values (use constants)
- [ ] Error handling implemented
- [ ] Loading states handled
- [ ] Null safety respected
- [ ] Performance considered (const, builders)
- [ ] Accessibility labels added

### Reviewer Checklist

- [ ] Architecture layers respected
- [ ] SOLID principles followed
- [ ] No business logic in widgets
- [ ] Proper error handling
- [ ] Tests cover edge cases
- [ ] Code is self-documenting
- [ ] No code duplication
- [ ] Security best practices followed

## Git Workflow

### Branch Naming

```
feature/auth-social-login
bugfix/swipe-animation-crash
hotfix/production-login-error
refactor/repository-pattern
```

### Commit Messages

```
feat(auth): add Google sign-in integration

- Implement Google OAuth flow
- Add GoogleSignInButton widget
- Update AuthService with Google provider
- Add unit tests for Google auth

Closes #123
```

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Manual testing completed

## Screenshots (if applicable)

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings
```

---

> **Remember**: Code is read 10x more than it's written. Optimize for readability and maintainability.
