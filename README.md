# BookSwipe

A Tinder-like book discovery app built with Flutter and Supabase.

## Features

- 📚 Swipe through book recommendations
- 🔐 Email & Google authentication
- 💾 Save liked books to your library
- 📖 Create custom reading lists
- 🎯 Personalized recommendations based on preferences

## Setup

### Prerequisites

- Flutter SDK (>=3.0.0)
- Supabase account

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up environment variables:
   - Copy `.env.example` to `.env`
   - Add your Supabase credentials

4. Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

This project follows the Feature-First Architecture with Clean Architecture principles:

```
lib/src/
├── config/          # App configuration
├── core/            # Core utilities and providers
├── features/        # Feature modules
│   └── auth/        # Authentication feature
│       ├── data/           # Data layer
│       ├── domain/         # Domain layer
│       ├── application/    # Business logic
│       └── presentation/   # UI layer
```

## Architecture

- **State Management**: Riverpod with code generation
- **Backend**: Supabase (Postgres + Auth + Storage)
- **Code Generation**: Freezed for immutable models
- **Navigation**: MaterialApp with named routes (will migrate to GoRouter)

## Development

### Code Generation

Run this command whenever you modify files with `@freezed` or `@riverpod` annotations:

```bash
dart run build_runner watch
```

### Testing

```bash
flutter test
```

## License

MIT
