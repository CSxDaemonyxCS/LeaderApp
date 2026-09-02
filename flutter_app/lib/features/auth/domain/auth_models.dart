/// Every model is immutable and has [fromJson] + [toJson] even though
/// only mock data exists — this is the wire format the real API will use.
library;

import '../../../core/access/capability.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.capabilities,
    required this.orgName,
    this.avatarInitials,
  });

  final String id;
  final String name;
  final String email;

  /// What this session may do.
  ///
  /// This replaced `enum UserRole { superAdmin, mainAdmin, simpleAdmin,
  /// volunteer }` on 2026-09-02. Capabilities are runtime data the server
  /// grants per user, so two Main Admins can differ; a role enum cannot
  /// express that. Roles survive only as presets at grant time — see
  /// `core/access/capability_presets.dart` and `CAPABILITIES.md`.
  final Capabilities capabilities;

  final String orgName;
  final String? avatarInitials;

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        capabilities: Capabilities.fromJson(
          (j['capabilities'] as Map<String, dynamic>?) ?? const {},
        ),
        orgName: j['orgName'] as String,
        avatarInitials: j['avatarInitials'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'capabilities': capabilities.toJson(),
        'orgName': orgName,
        if (avatarInitials != null) 'avatarInitials': avatarInitials,
      };
}

class MfaSetupData {
  const MfaSetupData({
    required this.otpauthUrl,
    required this.manualSecret,
    required this.backupCodes,
  });

  final String otpauthUrl;
  final String manualSecret;
  final List<String> backupCodes;

  factory MfaSetupData.fromJson(Map<String, dynamic> j) => MfaSetupData(
        otpauthUrl: j['otpauthUrl'] as String,
        manualSecret: j['manualSecret'] as String,
        backupCodes: (j['backupCodes'] as List).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'otpauthUrl': otpauthUrl,
        'manualSecret': manualSecret,
        'backupCodes': backupCodes,
      };
}

class Session {
  const Session({
    required this.id,
    required this.device,
    required this.ipMasked,
    required this.locationLabel,
    required this.startedAt,
    required this.current,
  });

  final String id;
  final String device;
  final String ipMasked;
  final String locationLabel;
  final DateTime startedAt;
  final bool current;

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        id: j['id'] as String,
        device: j['device'] as String,
        ipMasked: j['ipMasked'] as String,
        locationLabel: j['locationLabel'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        current: j['current'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'device': device,
        'ipMasked': ipMasked,
        'locationLabel': locationLabel,
        'startedAt': startedAt.toIso8601String(),
        'current': current,
      };
}
