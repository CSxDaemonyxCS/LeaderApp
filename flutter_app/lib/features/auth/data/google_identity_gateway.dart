/// Production Google identity acquisition for Point 17C.
///
/// The SDK returns one short-lived OpenID Connect ID token. Flutter neither
/// decodes its claims nor derives an MTM role, tenant or capability from it;
/// it is exchanged once through `OnboardingRepository`, whose backend answer
/// remains canonical. The token is never persisted or logged.
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/onboarding_models.dart' show GoogleIdentityAssertion;

/// Android needs the OAuth web/server client id so the SDK can mint an ID
/// token for the MTM backend audience. No identifier is committed here.
const String googleServerClientId =
    String.fromEnvironment('MTM_GOOGLE_SERVER_CLIENT_ID');

sealed class GoogleSignInAttempt {
  const GoogleSignInAttempt();
}

final class GoogleSignInObtained extends GoogleSignInAttempt {
  const GoogleSignInObtained(this.assertion);
  final GoogleIdentityAssertion assertion;
}

/// User dismissal is intentionally silent in the UI.
final class GoogleSignInCancelled extends GoogleSignInAttempt {
  const GoogleSignInCancelled();
}

/// Missing/misconfigured provider or a platform that cannot show the picker.
final class GoogleSignInUnavailable extends GoogleSignInAttempt {
  const GoogleSignInUnavailable();
}

/// Provider transport failure. The UI uses its offline/retry treatment and
/// never sees the SDK's platform code or description.
final class GoogleSignInNetworkFailure extends GoogleSignInAttempt {
  const GoogleSignInNetworkFailure();
}

/// Interrupted or unknown provider failure; generic and retryable.
final class GoogleSignInFailed extends GoogleSignInAttempt {
  const GoogleSignInFailed();
}

abstract class GoogleIdentityGateway {
  Future<GoogleSignInAttempt> signIn();
}

enum GoogleTokenClientFailure { cancelled, unavailable, network, failed }

class GoogleTokenClientException implements Exception {
  const GoogleTokenClientException(this.failure);

  final GoogleTokenClientFailure failure;

  @override
  String toString() => 'GoogleTokenClientException(${failure.name})';
}

/// Small injectable boundary around the Flutter plugin. Tests exercise the
/// gateway without asking a host platform to render account UI.
abstract class GoogleIdentityTokenClient {
  bool get configured;

  Future<String> obtainIdToken();
}

class GoogleSdkIdentityTokenClient implements GoogleIdentityTokenClient {
  GoogleSdkIdentityTokenClient({required this.serverClientId});

  final String serverClientId;

  static Future<void>? _initialization;
  static String? _initializedFor;

  @override
  bool get configured => serverClientId.trim().isNotEmpty;

  @override
  Future<String> obtainIdToken() async {
    if (!configured) {
      throw const GoogleTokenClientException(
          GoogleTokenClientFailure.unavailable);
    }
    final signIn = GoogleSignIn.instance;
    try {
      final initializedFor = _initializedFor;
      if (initializedFor != null && initializedFor != serverClientId) {
        throw const GoogleTokenClientException(
            GoogleTokenClientFailure.unavailable);
      }
      _initializedFor = serverClientId;
      final initialization =
          _initialization ??= signIn.initialize(serverClientId: serverClientId);
      try {
        await initialization;
      } catch (_) {
        // A failed initialization must not be memoized: the next tap retries
        // it instead of reporting "unavailable" until the process restarts.
        if (identical(_initialization, initialization)) {
          _initialization = null;
          _initializedFor = null;
        }
        rethrow;
      }
      if (!signIn.supportsAuthenticate()) {
        throw const GoogleTokenClientException(
            GoogleTokenClientFailure.unavailable);
      }
      final account = await signIn.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.trim().isEmpty) {
        throw const GoogleTokenClientException(GoogleTokenClientFailure.failed);
      }
      return token;
    } on GoogleSignInException catch (error) {
      throw GoogleTokenClientException(switch (error.code) {
        GoogleSignInExceptionCode.canceled =>
          GoogleTokenClientFailure.cancelled,
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError ||
        GoogleSignInExceptionCode.uiUnavailable =>
          GoogleTokenClientFailure.unavailable,
        GoogleSignInExceptionCode.interrupted ||
        GoogleSignInExceptionCode.userMismatch ||
        GoogleSignInExceptionCode.unknownError =>
          GoogleTokenClientFailure.failed,
      });
    } on PlatformException catch (error) {
      // Plugin implementations do not expose one cross-platform network enum.
      // Recognise only the established transport spellings; every other code
      // is deliberately collapsed to a generic provider failure.
      final code = error.code.toLowerCase();
      final network = code == 'network_error' ||
          code == 'networkerror' ||
          code == '7'; // Android CommonStatusCodes.NETWORK_ERROR.
      throw GoogleTokenClientException(network
          ? GoogleTokenClientFailure.network
          : GoogleTokenClientFailure.failed);
    } on MissingPluginException {
      throw const GoogleTokenClientException(
          GoogleTokenClientFailure.unavailable);
    } on UnsupportedError {
      throw const GoogleTokenClientException(
          GoogleTokenClientFailure.unavailable);
    }
  }
}

class GoogleSdkIdentityGateway implements GoogleIdentityGateway {
  const GoogleSdkIdentityGateway(this._client);

  final GoogleIdentityTokenClient _client;

  @override
  Future<GoogleSignInAttempt> signIn() async {
    if (!_client.configured) return const GoogleSignInUnavailable();
    try {
      final token = await _client.obtainIdToken();
      return GoogleSignInObtained(GoogleIdentityAssertion(token));
    } on GoogleTokenClientException catch (error) {
      return switch (error.failure) {
        GoogleTokenClientFailure.cancelled => const GoogleSignInCancelled(),
        GoogleTokenClientFailure.unavailable => const GoogleSignInUnavailable(),
        GoogleTokenClientFailure.network => const GoogleSignInNetworkFailure(),
        GoogleTokenClientFailure.failed => const GoogleSignInFailed(),
      };
    } catch (_) {
      // No exception text or provider code crosses this boundary.
      return const GoogleSignInFailed();
    }
  }
}

final googleIdentityGatewayProvider = Provider<GoogleIdentityGateway>((ref) {
  return GoogleSdkIdentityGateway(
    GoogleSdkIdentityTokenClient(serverClientId: googleServerClientId),
  );
});
