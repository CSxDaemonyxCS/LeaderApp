import 'dart:math';

import '../../../core/result/result.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository();

  AuthUser? _me;
  final _rand = Random(7);

  Future<void> _latency() => Future<void>.delayed(
        Duration(milliseconds: 400 + _rand.nextInt(400)),
      );

  @override
  Future<Result<AuthUser>> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    await _latency();
    if (password.length < 4) {
      return const Failure('كلمة المرور قصيرة جدا.');
    }
    _me = const AuthUser(
      id: 'u_1',
      name: 'ليلى ياسين',
      email: 'l.yaseen@mtm.org',
      role: UserRole.mainAdmin,
      orgName: 'فريق الإسعاف التطوعي · دمشق',
      avatarInitials: 'لي',
    );
    return Success(_me!);
  }

  @override
  Future<Result<MfaSetupData>> beginMfaSetup() async {
    await _latency();

    // TODO(backend): secret and otpauth URI must come from the server.
    // Never generate a TOTP secret on the client.
    //
    // The values below are FIXTURES for the mock only — they are not
    // computed here and must not be treated as a valid TOTP secret.
    // The real repository implementation will delegate this call to
    // POST /api/v1/mfa/setup and return the server's response verbatim.
    // Backup codes follow the same rule: issued by the server, never
    // generated on the device.
    const serverIssuedFixture = MfaSetupData(
      otpauthUrl:
          'otpauth://totp/MTM:l.yaseen@mtm.org?secret=JBSWY3DPEHPK3PXP&issuer=MTM',
      manualSecret: 'JBSWY3DPEHPK3PXP',
      backupCodes: [
        'F7K2-9QLM',
        'W3RA-B0VC',
        '8ZP4-JDN1',
        'HYX9-5MKT',
        '2QCS-EL7B',
        'V0RE-YH6U',
        'M9NA-6WFP',
        'X1TB-KO4J',
      ],
    );
    return const Success(serverIssuedFixture);
  }

  @override
  Future<Result<void>> verifyMfa(String code) async {
    await _latency();
    if (code.length != 6) return const Failure('الرمز يجب أن يكون ٦ أرقام.');
    return const Success(null);
  }

  @override
  Future<Result<void>> requestPasswordReset(String email) async {
    await _latency();
    return const Success(null);
  }

  @override
  Future<Result<void>> verifyResetOtp(String email, String code) async {
    await _latency();
    if (code.length != 6) return const Failure('الرمز غير صحيح.');
    return const Success(null);
  }

  @override
  Future<Result<void>> setNewPassword(String password) async {
    await _latency();
    if (password.length < 8) {
      return const Failure('٨ أحرف على الأقل.');
    }
    return const Success(null);
  }

  @override
  Future<Result<AuthUser?>> currentUser() async {
    await _latency();
    return Success(_me);
  }

  @override
  Future<Result<void>> confirmNewDevice({required bool itsMe}) async {
    await _latency();
    return const Success(null);
  }

  @override
  Future<Result<void>> signOut() async {
    await _latency();
    _me = null;
    return const Success(null);
  }

  @override
  Future<Result<List<Session>>> listSessions() async {
    await _latency();
    final now = DateTime.now();
    return Success([
      Session(
        id: 's_cur',
        device: 'iPhone 15 · Safari',
        ipMasked: '176.29.xx.xx',
        locationLabel: 'دمشق, سوريا',
        startedAt: now.subtract(const Duration(hours: 1, minutes: 12)),
        current: true,
      ),
      Session(
        id: 's_2',
        device: 'MacBook Pro · Chrome',
        ipMasked: '176.29.xx.xx',
        locationLabel: 'دمشق, سوريا',
        startedAt: now.subtract(const Duration(days: 1, hours: 4)),
        current: false,
      ),
      Session(
        id: 's_3',
        device: 'Samsung Galaxy · MTM App',
        ipMasked: '82.137.xx.xx',
        locationLabel: 'حمص, سوريا',
        startedAt: now.subtract(const Duration(days: 3)),
        current: false,
      ),
    ]);
  }

  @override
  Future<Result<void>> revokeSession(String id) async {
    await _latency();
    return const Success(null);
  }
}
