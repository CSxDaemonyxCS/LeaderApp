import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/problem/problem.dart';
import '../../../core/result/result.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';
import 'mock_auth_repository.dart';

/// Swap this override in a real build to plug in a network-backed repo.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

/// The session exactly as the repository reported it.
///
/// This is the base; [currentUserProvider] is the collapsed view of it. The
/// distinction matters in two places and nowhere else: the account screen and
/// the router's auth gate need to tell "no session" from "the session
/// expired" from "we are offline with no cached copy", and collapsing all
/// three to `null` throws that away. Every capability check only ever needed
/// the collapsed form, so that stays the provider the rest of the app reads.
///
/// Invalidate **this** one to force a re-read of the session — invalidating
/// the derived provider alone re-awaits this cached future and gets the same
/// answer back.
final currentUserResultProvider =
    FutureProvider<Result<AuthUser?>>((ref) async {
  return ref.read(authRepositoryProvider).currentUser();
});

/// The signed-in account, or `null`.
///
/// Failure and offline-without-cache both read as "no account" here, which is
/// the correct answer for a capability check: deny. A screen that has to
/// explain *why* there is no account reads [currentUserResultProvider].
final currentUserProvider = FutureProvider<AuthUser?>((ref) async {
  final r = await ref.watch(currentUserResultProvider.future);
  return r.when(
    success: (data, {stale = false}) => data,
    failure: (_, __) => null,
    offline: (cached) => cached,
  );
});

/// What the router may conclude about the session.
///
/// TODO(security): a UX gate, like every other client-side access decision in
/// this app — see the contract at the top of `core/access/capability.dart`.
/// It keeps a signed-out person off a screen that would fail; the backend
/// rejects the request regardless.
enum AuthGate {
  /// Not yet known. The session is still being read, or the read failed in a
  /// way that is not evidence of anything — a transport error, or an offline
  /// device with no cached copy. **Never redirects.** A cold start spends its
  /// first frames here, and an app that bounced an offline user to the login
  /// screen would be broken for exactly the field conditions this app is
  /// built for.
  unknown,

  signedIn,

  /// The repository answered, definitively, that there is no session.
  signedOut,

  /// There was a session and it is no longer valid — `authentication_expired`.
  /// Distinct from [signedOut] because it lands on its own screen.
  expired,
}

final authGateProvider = Provider<AuthGate>((ref) {
  final result = ref.watch(currentUserResultProvider).valueOrNull;
  if (result == null) return AuthGate.unknown;
  return result.when(
    success: (user, {stale = false}) =>
        user == null ? AuthGate.signedOut : AuthGate.signedIn,
    failure: (_, code) =>
        ProblemCode.parse(code) == ProblemCode.authenticationExpired
            ? AuthGate.expired
            : AuthGate.unknown,
    // A cached account is still an account: offline-first means the app keeps
    // working from what it already has.
    offline: (cached) => cached == null ? AuthGate.unknown : AuthGate.signedIn,
  );
});

final sessionsProvider = FutureProvider<Result<List<Session>>>((ref) async {
  return ref.read(authRepositoryProvider).listSessions();
});
