import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/supabase_provider.dart';
import '../data/data_sources/supabase_auth_data_source.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/models/user_model.dart';

part 'auth_service.g.dart';

/// Provider for AuthRepository
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final dataSource = SupabaseAuthDataSource(supabase);
  return AuthRepositoryImpl(dataSource);
}

/// Provider for current user
@riverpod
Stream<UserModel?> authStateChanges(AuthStateChangesRef ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
}

/// Provider for current user (synchronous)
@riverpod
UserModel? currentUser(CurrentUserRef ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getCurrentUser();
}
