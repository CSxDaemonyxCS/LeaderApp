/// Identity of *this build* of the app: what version is installed, what the
/// mark looks like, and the header a future API layer sends so the server can
/// answer the one question this file exists for — is this build still
/// supported?
///
/// Deliberately a plain constant class and not a repository: none of it is
/// fetched, none of it changes at runtime, and the forced-upgrade screen has
/// to be able to render the installed version even when nothing can be
/// reached.
abstract final class AppInfo {
  /// The installed **display** version, `major.minor.patch`.
  ///
  /// This is what the user sees on the forced-upgrade screen and what the
  /// API layer sends in [clientVersionHeader]. Mirrors the part of
  /// `version:` in `pubspec.yaml` before `+`;
  /// `test/features/app_version/forced_upgrade_test.dart` fails if the two
  /// drift — the screen must not be able to lie about which build is running.
  static const String version = '1.0.0';

  /// The installed **build identity**, `major.minor.patch+build` — the full
  /// `version:` string from `pubspec.yaml` (Flutter's `versionName+versionCode`).
  ///
  /// Two artefacts can ship the same display [version] and differ only by
  /// build number — a hotfix rebuild, a store-signed re-upload. They are
  /// **different installed binaries**, so anything that must not carry over
  /// from one to another (the persisted forced-upgrade verdict —
  /// `PersistedUpgradeGate`) is keyed on this, not on [version]. The client
  /// never parses or orders it; it is only ever compared for exact equality.
  ///
  /// Held to `pubspec.yaml` by the same drift test as [version]. A shipping
  /// build sources this from build metadata (`package_info_plus`) rather than
  /// a constant — see `FRONTEND-BACKEND-INTEGRATION.md` §1.
  static const String buildIdentity = '1.0.0+1';

  /// Header the API layer will carry the installed [version] in, so the
  /// server can reply `426 Upgrade Required` to any request from a build it
  /// no longer supports. Nothing sends it yet — there is no network layer.
  /// See `FRONTEND-BACKEND-INTEGRATION.md`.
  static const String clientVersionHeader = 'X-Client-Version';

  /// The MTM mark, bundled unmodified.
  ///
  /// Byte-identical copy of `assets/images/mtm_logo_full.png` from the legacy
  /// `medical_team` app — the same artwork MTM already ships under. It is
  /// deliberately NOT the Android launcher icon: `android/.../mipmap-*` still
  /// holds the stock Flutter mark, so naming this file after the launcher
  /// would send whoever replaces that icon to the wrong place.
  static const String logoAsset = 'assets/brand/mtm_logo_full.png';
}
