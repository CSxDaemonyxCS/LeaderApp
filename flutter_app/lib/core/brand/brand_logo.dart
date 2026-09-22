import '../../l10n/strings.dart';

/// The three approved Leader marks, as one closed type.
///
/// The product shipped three concepts from the same lockup — the ليدر
/// wordmark inside an L-shaped glass tile — and all three are offered to the
/// user. They differ only in the light they are lit with: teal, gold, blue.
///
/// **Filenames stay here.** Every surface that draws the mark asks a
/// [BrandLogo] for its [asset]; nothing else in the app spells an
/// `assets/brand/...` path, so re-exporting the artwork is one edit.
///
/// **[cleanLayer] is the default, and it is also the launcher icon.** The
/// home-screen icon is fixed for everyone (`mipmap-anydpi-v26/ic_launcher.xml`)
/// and is deliberately *not* derived from this preference: Android can only
/// swap a launcher icon by toggling activity-aliases, which drops the user's
/// placed shortcut and their widget. This enum governs the in-app mark only.
///
/// **Cosmetic only.** It reaches no authorization, tenant, plan, demo or
/// wire decision — it picks a picture.
enum BrandLogo {
  /// `06 · Clean Layer` — the teal mark. The product default, the launcher
  /// icon, and the mark the Login screen's palette was derived from.
  cleanLayer(
    'assets/brand/leader_logo_clean_layer.png',
    S.brandLogoCleanLayer,
  ),

  /// `14 · Elegant Curve` — the same lockup lit gold.
  elegantCurve(
    'assets/brand/leader_logo_elegant_curve.png',
    S.brandLogoElegantCurve,
  ),

  /// `07 · Depth` — the same lockup lit blue.
  depth(
    'assets/brand/leader_logo_depth.png',
    S.brandLogoDepth,
  );

  const BrandLogo(this.asset, this.label);

  /// Bundled asset path. Declared under `assets/brand/` in `pubspec.yaml`.
  final String asset;

  /// Arabic display name. Never a filename — the picker shows the artwork
  /// and this line, and nothing else.
  final String label;

  /// What a fresh install draws, and the fallback for anything unreadable.
  static const BrandLogo fallback = BrandLogo.cleanLayer;

  /// Restores a stored name. Persisted by **name**, never by index, so
  /// reordering this enum cannot silently re-point a saved preference; an
  /// unknown, missing or malformed value resolves to [fallback] rather than
  /// throwing on the launch path.
  static BrandLogo fromName(Object? name) => BrandLogo.values.firstWhere(
        (v) => v.name == name,
        orElse: () => fallback,
      );

  /// Whether this is the mark the product ships on.
  bool get isDefault => this == fallback;
}
