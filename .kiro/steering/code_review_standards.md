---
inclusion: manual
---

# 📋 Code Review Standards & Checklist

> Facebook-level code review guidelines for BookSwipe

## Pre-Review Checklist (Author)

### Code Quality
- [ ] Code follows project architecture (Feature-First + Clean Architecture)
- [ ] SOLID principles applied
- [ ] No business logic in presentation layer
- [ ] All public APIs documented with dartdoc
- [ ] No TODO comments without tracking issue
- [ ] No commented-out code
- [ ] No debug print statements
- [ ] Proper error handling implemented

### Testing
- [ ] Unit tests added for business logic (80%+ coverage)
- [ ] Widget tests for new UI components
- [ ] All tests pass locally (`flutter test`)
- [ ] Integration tests for critical flows (if applicable)

### Code Style
- [ ] Code formatted (`dart format .`)
- [ ] No linting errors (`flutter analyze`)
- [ ] Naming conventions followed
- [ ] Const constructors used where possible
- [ ] No magic numbers (use constants)

### Performance
- [ ] ListView.builder used for long lists
- [ ] Images optimized (CachedNetworkImage with size limits)
- [ ] No expensive operations in build methods
- [ ] Proper use of const widgets

### Security
- [ ] No hardcoded secrets or API keys
- [ ] Input validation implemented
- [ ] Sensitive data stored securely
- [ ] RLS policies reviewed (if database changes)

## Reviewer Checklist

### Architecture & Design
- [ ] Changes align with project architecture
- [ ] Proper layer separation maintained
- [ ] Dependencies flow in correct direction
- [ ] Feature is self-contained
- [ ] No circular dependencies

### Code Quality
- [ ] Code is readable and self-documenting
- [ ] Complex logic has explanatory comments
- [ ] No code duplication (DRY principle)
- [ ] Functions are small and focused
- [ ] Proper abstraction levels

### State Management
- [ ] Correct Riverpod provider type used
- [ ] Providers properly scoped
- [ ] No unnecessary rebuilds
- [ ] AsyncValue handled correctly
- [ ] Error states properly managed

### Error Handling
- [ ] All async operations wrapped in try-catch
- [ ] Typed errors using sealed classes
- [ ] User-friendly error messages
- [ ] Errors logged appropriately
- [ ] Retry mechanisms where appropriate

### Testing
- [ ] Tests are meaningful and test behavior
- [ ] Edge cases covered
- [ ] Mocks used appropriately
- [ ] Tests follow AAA pattern
- [ ] Test names are descriptive

### Performance
- [ ] No performance regressions
- [ ] Efficient algorithms used
- [ ] Proper use of const
- [ ] No memory leaks
- [ ] Lazy loading implemented where needed

### Security
- [ ] No security vulnerabilities introduced
- [ ] Input sanitized and validated
- [ ] Authentication/authorization checked
- [ ] Sensitive data protected

### UI/UX
- [ ] UI matches design specifications
- [ ] Responsive on different screen sizes
- [ ] Loading states implemented
- [ ] Error states user-friendly
- [ ] Accessibility considered

## Review Comments Guidelines

### Severity Levels

**🔴 BLOCKER**: Must be fixed before merge
- Security vulnerabilities
- Breaking changes without migration
- Critical bugs
- Architecture violations

**🟡 MAJOR**: Should be fixed before merge
- Performance issues
- Missing error handling
- Incomplete tests
- Code quality issues

**🟢 MINOR**: Can be fixed in follow-up
- Code style improvements
- Documentation enhancements
- Refactoring suggestions
- Nice-to-have features

**💡 SUGGESTION**: Optional improvements
- Alternative approaches
- Future optimizations
- Learning opportunities

### Comment Examples

#### ❌ Bad Comments
```
// This is wrong
// Fix this
// Why did you do this?
```

#### ✅ Good Comments
```
// 🔴 BLOCKER: This exposes user passwords in logs
// Consider using a secure logging library that masks sensitive data

// 🟡 MAJOR: Missing error handling
// What happens if the network request fails? 
// Wrap this in try-catch and show user-friendly error

// 🟢 MINOR: Consider extracting this widget
// This build method is getting large. Consider extracting 
// _buildBookCard() into a separate widget for better readability

// 💡 SUGGESTION: Performance optimization opportunity
// For large lists, consider using ListView.builder instead of 
// ListView with children. This will improve scroll performance
```

## Common Issues & Solutions

### 1. Business Logic in Widgets

❌ **Bad**:
```dart
class BookListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(bookListProvider);
    
    // ❌ Business logic in widget
    final filteredBooks = books.where((b) => 
      b.rating > 4.0 && b.genre == 'Fiction'
    ).toList();
    
    return ListView(children: filteredBooks.map(...));
  }
}
```

✅ **Good**:
```dart
// In controller/service
@riverpod
List<Book> filteredBooks(FilteredBooksRef ref) {
  final books = ref.watch(bookListProvider);
  final filters = ref.watch(bookFiltersProvider);
  
  return books.where((b) => 
    b.rating > filters.minRating && 
    b.genre == filters.genre
  ).toList();
}

// In widget
class BookListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(filteredBooksProvider);
    return ListView(children: books.map(...));
  }
}
```

### 2. Missing Error Handling

❌ **Bad**:
```dart
Future<void> loadBooks() async {
  final books = await repository.fetchBooks(); // ❌ No error handling
  state = books;
}
```

✅ **Good**:
```dart
Future<void> loadBooks() async {
  state = const AsyncValue.loading();
  state = await AsyncValue.guard(() async {
    try {
      return await repository.fetchBooks();
    } on NetworkException {
      throw const BookFailure.networkError();
    } on ServerException catch (e) {
      throw BookFailure.serverError(e.message);
    }
  });
}
```

### 3. Not Using Const

❌ **Bad**:
```dart
return Padding(
  padding: EdgeInsets.all(16), // ❌ Not const
  child: Text('Hello'), // ❌ Not const
);
```

✅ **Good**:
```dart
return const Padding(
  padding: EdgeInsets.all(16), // ✅ Const
  child: Text('Hello'), // ✅ Const
);
```

### 4. Inefficient List Building

❌ **Bad**:
```dart
ListView(
  children: books.map((book) => BookCard(book)).toList(), // ❌
)
```

✅ **Good**:
```dart
ListView.builder(
  itemCount: books.length,
  itemBuilder: (context, index) => BookCard(books[index]), // ✅
)
```

## Approval Criteria

### Required for Merge
1. ✅ All blockers resolved
2. ✅ All major issues resolved or have follow-up tickets
3. ✅ At least 2 approvals from team members
4. ✅ All CI checks passing
5. ✅ No merge conflicts
6. ✅ Documentation updated

### Optional but Recommended
- Minor issues resolved
- Suggestions considered
- Performance benchmarks run
- Manual testing completed

## Post-Merge Actions

### Author Responsibilities
- [ ] Monitor production for issues
- [ ] Create follow-up tickets for deferred items
- [ ] Update documentation if needed
- [ ] Notify stakeholders of changes

### Team Responsibilities
- [ ] Review production metrics
- [ ] Update team knowledge base
- [ ] Share learnings in team meeting

---

> **Remember**: Code reviews are about learning and improving, not criticizing. Be kind, be constructive, be thorough.
