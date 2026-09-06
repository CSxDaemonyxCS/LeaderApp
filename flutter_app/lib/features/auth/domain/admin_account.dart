/// How the signed-in account's grant reads on the account screen.
///
/// **Nothing here decides access.** This is a description of a grant,
/// produced for one read-only summary, and it deliberately lives with the
/// account feature rather than in `core/access/` so it cannot be mistaken for
/// a check. Access is decided in exactly one place — `Capabilities.canIn` —
/// and the account screen gates its own controls through the same
/// `CapabilityGate` / `ref.whenCan` as every other screen.
///
/// **There is no Main Admin flag to read.** `UserRole` was removed on
/// 2026-09-02 (`CAPABILITIES.md` §0/§1) and `AuthUser` carries no `role`
/// property — `API_CONTRACT.md` says so in as many words. Presets are a
/// grant-time convenience, and a live grant "may match no preset at all"
/// afterwards, so matching one back to a preset name and calling the holder a
/// Main Admin would be inventing a fact the server never sent. What can be
/// said truthfully is what the grant contains, and that is what this says.
library;

import '../../../core/access/capability.dart';

enum AdminAccessLevel {
  /// Holds every capability this build knows, organisation-wide. In practice
  /// the organisation's root administrator — but stated as what it is, a full
  /// grant, not as a role the server did not send.
  full,

  /// Holds organisation-level capabilities, but not all of them.
  organisation,

  /// No organisation-level grant; capabilities are confined to named
  /// detachments.
  detachmentScoped,

  /// Signed in with nothing granted. A real state — an account created and
  /// not yet given anything.
  none,
}

class AdminAccountSummary {
  const AdminAccountSummary({
    required this.level,
    required this.managesAdmins,
    required this.editsOrganisation,
    required this.detachmentCount,
  });

  final AdminAccessLevel level;

  /// Holds `admin.manage` — may administer the other admin accounts. This is
  /// the closest the domain comes to the Main Admin distinction, and it is
  /// reported as the capability it is rather than as a rank.
  final bool managesAdmins;

  /// Holds `org.edit`.
  final bool editsOrganisation;

  /// How many detachments carry a grant for this account. Zero for an
  /// organisation-wide grant, which needs no per-detachment entry.
  final int detachmentCount;

  factory AdminAccountSummary.of(Capabilities caps) {
    final scopedCount = caps.visibleDetachmentIds.length;
    final AdminAccessLevel level;
    if (caps.global.isEmpty && scopedCount == 0) {
      level = AdminAccessLevel.none;
    } else if (caps.global.containsAll(Cap.all)) {
      level = AdminAccessLevel.full;
    } else if (caps.global.isNotEmpty) {
      level = AdminAccessLevel.organisation;
    } else {
      level = AdminAccessLevel.detachmentScoped;
    }
    return AdminAccountSummary(
      level: level,
      managesAdmins: caps.can(Cap.adminManage),
      editsOrganisation: caps.can(Cap.orgEdit),
      detachmentCount: scopedCount,
    );
  }
}
