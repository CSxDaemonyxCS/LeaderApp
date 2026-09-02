import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';
import 'mock_auth_repository.dart';

/// Swap this override in a real build to plug in a network-backed repo.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final currentUserProvider = FutureProvider<AuthUser?>((ref) async {
  final r = await ref.read(authRepositoryProvider).currentUser();
  return r.when(
    success: (data, {stale = false}) => data,
    failure: (_, __) => null,
    offline: (cached) => cached,
  );
});

final sessionsProvider = FutureProvider<Result<List<Session>>>((ref) async {
  return ref.read(authRepositoryProvider).listSessions();
});
