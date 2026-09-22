import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// The platform seam ships with google_sign_in; tests replace it so the real
// SDK client runs without asking a host platform to render account UI.
// ignore: depend_on_referenced_packages
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:mtm/features/auth/data/google_identity_gateway.dart';

/// Scripted stand-in for the Android/iOS plugin behind google_sign_in 7.x.
class _FakeGooglePlatform extends GoogleSignInPlatform {
  final List<Object> initErrors = [];
  Object? authError;
  String? idToken = 'sdk-id-token';
  bool supported = true;
  int initCalls = 0;

  @override
  Future<void> init(InitParameters params) async {
    initCalls++;
    if (initErrors.isNotEmpty) throw initErrors.removeAt(0);
  }

  @override
  bool supportsAuthenticate() => supported;

  @override
  Future<AuthenticationResults> authenticate(
      AuthenticateParameters params) async {
    if (authError case final Object error) throw error;
    return AuthenticationResults(
      user: const GoogleSignInUserData(email: 'a@example.test', id: 'g-1'),
      authenticationTokens: AuthenticationTokenData(idToken: idToken),
    );
  }

  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(
          AttemptLightweightAuthenticationParameters params) =>
      null;

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
          ClientAuthorizationTokensForScopesParameters params) async =>
      null;

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
          ServerAuthorizationTokensForScopesParameters params) async =>
      null;

  @override
  Future<void> signOut(SignOutParams params) async {}

  @override
  Future<void> disconnect(DisconnectParams params) async {}
}

class _Client implements GoogleIdentityTokenClient {
  _Client(
      {this.configured = true, this.token = 'provider-id-token', this.error});

  @override
  final bool configured;
  final String token;
  final Object? error;
  int calls = 0;

  @override
  Future<String> obtainIdToken() async {
    calls++;
    if (error case final Object value) throw value;
    return token;
  }
}

void main() {
  group('production Google gateway', () {
    test('exchanges only the opaque ID token and never prints it', () async {
      final client = _Client(token: 'top-secret-google-token');
      final result = await GoogleSdkIdentityGateway(client).signIn();

      expect(result, isA<GoogleSignInObtained>());
      final assertion = (result as GoogleSignInObtained).assertion;
      expect(assertion.idToken, 'top-secret-google-token');
      expect(assertion.toString(), isNot(contains('top-secret-google-token')));
      expect(client.calls, 1);
    });

    test('missing external configuration fails closed before SDK UI', () async {
      final client = _Client(configured: false);
      expect(
        await GoogleSdkIdentityGateway(client).signIn(),
        isA<GoogleSignInUnavailable>(),
      );
      expect(client.calls, 0);
    });

    for (final entry in <GoogleTokenClientFailure, Type>{
      GoogleTokenClientFailure.cancelled: GoogleSignInCancelled,
      GoogleTokenClientFailure.unavailable: GoogleSignInUnavailable,
      GoogleTokenClientFailure.network: GoogleSignInNetworkFailure,
      GoogleTokenClientFailure.failed: GoogleSignInFailed,
    }.entries) {
      test('${entry.key.name} is mapped without a raw provider code', () async {
        final client = _Client(error: GoogleTokenClientException(entry.key));
        final result = await GoogleSdkIdentityGateway(client).signIn();
        expect(result.runtimeType, entry.value);
        expect(result.toString(), isNot(contains('provider')));
      });
    }

    test('unexpected SDK exceptions become a generic retryable failure',
        () async {
      final result = await GoogleSdkIdentityGateway(
        _Client(error: StateError('raw-provider-secret')),
      ).signIn();
      expect(result, isA<GoogleSignInFailed>());
      expect(result.toString(), isNot(contains('raw-provider-secret')));
    });
  });

  // The SDK client keeps process-wide initialization state (the plugin is a
  // singleton), so these cases share one server client id and run in order.
  group('google_sign_in 7.x SDK client', () {
    late _FakeGooglePlatform platform;
    GoogleIdentityGateway gateway([String id = 'server-client.test']) =>
        GoogleSdkIdentityGateway(
            GoogleSdkIdentityTokenClient(serverClientId: id));

    setUp(
        () => GoogleSignInPlatform.instance = platform = _FakeGooglePlatform());

    test('a failed initialize is retried on the next attempt, not memoized',
        () async {
      platform.initErrors.add(PlatformException(code: 'sign_in_failed'));
      expect(await gateway().signIn(), isA<GoogleSignInFailed>());

      final retry = await gateway().signIn();
      expect(retry, isA<GoogleSignInObtained>());
      expect((retry as GoogleSignInObtained).assertion.idToken, 'sdk-id-token');
      expect(platform.initCalls, 2);
    });

    test('SDK exception codes map to the four generic outcomes', () async {
      const cases = <GoogleSignInExceptionCode, Type>{
        GoogleSignInExceptionCode.canceled: GoogleSignInCancelled,
        GoogleSignInExceptionCode.clientConfigurationError:
            GoogleSignInUnavailable,
        GoogleSignInExceptionCode.providerConfigurationError:
            GoogleSignInUnavailable,
        GoogleSignInExceptionCode.uiUnavailable: GoogleSignInUnavailable,
        GoogleSignInExceptionCode.interrupted: GoogleSignInFailed,
        GoogleSignInExceptionCode.userMismatch: GoogleSignInFailed,
        GoogleSignInExceptionCode.unknownError: GoogleSignInFailed,
      };
      for (final entry in cases.entries) {
        platform.authError = GoogleSignInException(
            code: entry.key, description: 'raw-sdk-description');
        final result = await gateway().signIn();
        expect(result.runtimeType, entry.value, reason: entry.key.name);
        expect(result.toString(), isNot(contains('raw-sdk-description')));
      }
    });

    test('network transport failure and unsupported platform', () async {
      platform.authError = PlatformException(code: 'network_error');
      expect(await gateway().signIn(), isA<GoogleSignInNetworkFailure>());

      platform
        ..authError = null
        ..supported = false;
      expect(await gateway().signIn(), isA<GoogleSignInUnavailable>());
    });

    test('a missing ID token is a failure, never an empty assertion', () async {
      platform.idToken = null;
      expect(await gateway().signIn(), isA<GoogleSignInFailed>());
    });

    test('a second server client id in one process fails closed', () async {
      expect(await gateway('another-client.test').signIn(),
          isA<GoogleSignInUnavailable>());
    });
  });
}
