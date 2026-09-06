import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import 'auth_providers.dart';

/// Whether a sign-out is in flight. The one piece of state a sign-out has.
enum SignOutPhase { idle, inProgress }

/// The single owner of sign-out.
///
/// Sign-out is offered from two places — the Settings hub and the account
/// screen — and both must behave identically: one request per gesture, the
/// session providers cleared only on a real success, and the failure handed
/// back to the caller rather than swallowed. Duplicating that in two widgets
/// is how the two drift, so neither widget owns it.
///
/// The duplicate-tap guard lives here rather than in a widget's `setState`
/// because a second tap can arrive from the *other* entry point, or from a
/// rebuilt widget, and a guard held in one widget's state cannot see it.
class SignOutController extends Notifier<SignOutPhase> {
  @override
  SignOutPhase build() => SignOutPhase.idle;

  /// Signs the session out.
  ///
  /// Returns the repository's answer, or `null` when a sign-out was already
  /// running — the second call is dropped, not queued. On success the session
  /// providers are invalidated, which is what actually clears the
  /// authenticated state: `capabilitiesProvider` falls back to
  /// `Capabilities.none` and the router's auth gate turns the app's protected
  /// routes off.
  Future<Result<void>?> signOut() async {
    if (state == SignOutPhase.inProgress) return null;
    state = SignOutPhase.inProgress;
    try {
      final result = await ref.read(authRepositoryProvider).signOut();
      if (result.isSuccess) {
        // The base, not the derived view — see `currentUserResultProvider`.
        ref.invalidate(currentUserResultProvider);
        ref.invalidate(sessionsProvider);
      }
      return result;
    } finally {
      state = SignOutPhase.idle;
    }
  }
}

final signOutControllerProvider =
    NotifierProvider<SignOutController, SignOutPhase>(SignOutController.new);
