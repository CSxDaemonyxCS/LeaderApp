# Handoff: MTM — نظام إدارة فرق الإسعاف التطوعي (Flutter)

## Overview

MTM is an offline-first Arabic-RTL Flutter app for volunteer emergency medical
teams. It coordinates:

- **Detachments** (مفرزات) — regional teams, each running centers
- **Shifts** (شفتات) — time-blocked coverage at a center, with attendance
- **Inventory** (المخزن) — meds/consumables, expiry, movements
- **Workshops** (الورش) — training events with registered members + guests
- **Auth** — login, MFA (server-issued TOTP), password reset, session mgmt

The signature UI elements are:

1. A **floating Apple-style glass bottom nav** (4 destinations) — pill that
   floats over content instead of pushing it, with a `BackdropFilter` blur.
2. A **Lock Window** chip on every shift/attendance surface: `open` (mm:ss
   countdown, pulses when <60s remain), `restricted`, or `sealed`.
3. Three UI-token **palettes** (Slate / Copper / Clay) each with a light and
   dark mode — same colors as the workspace's HTML dashboards.

## About the Design Files

This bundle is a **complete runnable Flutter application** — not an HTML
prototype. The Dart code under `flutter_app/lib/` is the design + the
implementation, mirrored from the HTML mocks that seeded this project
(`flutter_preview.html`, `index.html` + `screens_*.jsx`).

For a developer picking this up:

- If you're extending the Flutter app: `cd flutter_app && flutter pub get && flutter run`.
- If you're re-implementing this design in a different stack (SwiftUI,
  Jetpack Compose, React Native, web), read the **Screens / Views** and
  **Design Tokens** sections below — the Dart files carry the exact color
  hex values, spacing, typography, and animation durations.
- The HTML mocks (`flutter_preview.html`) are useful as a live visual
  reference for the token palette + the LockWindow, glass nav, and hero
  card treatments. They are references, not code to ship.

## Fidelity

**High-fidelity.** Every color, radius, font weight, motion duration, and
curve is a named token. Nothing in the design is "roughly" — the palette hex
values, `AppRadii`, `AppSpacing`, and `MotionTokens` classes are the exact
source of truth. Re-implementations should be pixel-close.

## Screens / Views

### 1. Auth flow

All auth screens share `AuthScaffold` — a single-column form on a plain
`c.bg` background, with a 56×56 primary-tint tile above the title carrying
`Icons.health_and_safety_rounded`.

- **Login** (`/login`) — email/username + password + "نسيت كلمة المرور؟"
  link + `Dخول` FilledButton + secondary outlined "لديّ رمز تحقق ثنائي —
  متابعة". Error surfaces as a `crit`-tinted callout below the fields.

- **MFA Setup** (`/mfa-setup`) — QR code (via `qr_flutter`) rendered on a
  white card (border `c.line`, radius `AppRadii.xl`), followed by the
  manual secret in a small field with a copy button, then an 8-code grid
  of backup codes (2 columns, `c.surface2` tiles) plus a "نسخ" button.
  **SECURITY: the secret + otpauth URI + backup codes come from
  `AuthRepository.beginMfaSetup()` — never generated on device.**

- **MFA Challenge** (`/mfa-challenge`) — 6 boxed digit inputs in an LTR
  row, 46×56, auto-advance on entry, auto-submit when full. Errors show
  in `c.crit` under the boxes.

- **Forgot Password** (`/forgot`) → **OTP** (`/otp`) → **New Password**
  (`/new-password`) — three sequential single-purpose screens. OTP screen
  is a 6-box layout identical to MFA Challenge.

- **Session Expired** (`/session-expired`) — full-bleed warning card in
  `c.warnTint` with `Icons.lock_reset_rounded`, then a FilledButton to
  return to `/login`.

- **New Device** (`/new-device`) — device metadata card ("iPhone 15 ·
  Safari", "دمشق, سوريا", "منذ ٤ دقائق", "176.29.xx.xx") + two buttons:
  "نعم، هذا أنا" (Filled) and "ليس أنا" (Outlined).

### 2. الرئيسية — Home (`/home`)

`Scaffold` with a normal `AppBar` (`الرئيسية` title, bell icon) and body:

- **OfflineBanner** slot (currently hidden — wire to a real connectivity
  stream). When visible, it's a `c.warnTint` strip with `Icons.cloud_off_rounded`
  and "بدون اتصال · تعرض بيانات محلية. آخر تحديث ٤ د".

- **Hero card** (`AppRadii.xl`, `c.line` border, `LinearGradient` from
  `c.primaryTint → c.surface`): eyebrow "شفتك الآن" + center name
  (headline) + LTR mono time range + `LockWindow(state: open, remaining)`
  in the top-right. Below: attendance row ("الحضور  ٧ / ١٠") with a
  themed progress bar (8px, `c.ok` fill on `c.surface3` track, animates
  from 0 → target over 700ms `easeOutCubic`), then a full-width
  `FilledButton` "تسجيل حضور".

- **يحتاج قرارك** (`SectionHeader`) — card containing 3 rows, each with:
  36×36 tinted icon (warn/crit/info), title, subtitle, and a small
  `FilledButton.tonal` action. Rows animate in via `Stagger(index: 1..3)`.

- **لمحة عامة** (`SectionHeader`) — 2-column grid of "secondary stat"
  tiles + one full-width tile. Each has a 32×32 tinted icon square,
  label, and a 20px mono number.

All lists snap-to-value under reduced motion; the `AnimatedCounter` on
the attendance row eases from 0 to its target when full motion is on.

### 3. المفرزة — Detachment

- **List** (`/detachment`) — search field (`Icons.search_rounded`
  prefix), 3 filter chips (الكل / نشطة / مؤرشفة) as pill toggles that
  fill with `c.primary` when active. Below: staggered cards. Each card:
  40×40 `c.primaryTint` flag tile, name (titleMedium), "region · main
  center" subtitle, coverage `StatusChip` right-aligned (ok ≥85%, warn
  ≥70%, crit otherwise). Bottom row of the card: member count + weekly
  shifts as small labels + mono numbers.

- **Detail shell** (`/detachment/:id/*`) — AppBar with the detachment
  name and an edit icon → `/detachment/:id/edit`. Under the AppBar sits
  an `AnimatedTabBar` (persistent, 4 tabs). Tab body is wrapped in
  `TabCrossFade`. Every tab is independently deep-linkable:
  - `/detachment/:id/team` — الفريق وأدواره
  - `/detachment/:id/shifts` — الشفتات
  - `/detachment/:id/storage` — المخزن
  - `/detachment/:id/stats` — الإحصائيات

- **Team tab** (`detachment_team_tab.dart`) — implemented. Member cards
  with 40×40 tinted circular avatars (initials, colored per attendance),
  role chip below name, `StatusChip` for attendance state on the right.
  Tapping a card opens a `SheetScaffold` "تغيير الدور" bottom sheet
  with a role picker (Lead / Medic / Trainee / Volunteer, selected row
  gets `c.primaryTint` background + `c.primary` border and check icon).

- **Shifts / Storage / Stats tabs** and **Create/Edit detachment** — NOT
  built. The router references them; create them from the seed data
  already in `MockShiftRepository` / `MockInventoryRepository` /
  `MockDetachmentRepository.stats()`.

### 4. الورشة — Workshop

- **List** (`/workshop`), **Detail shell** with 3 tabs
  (`/workshop/:id/{team, members, stats}`), **Create/Edit** — NOT built.
  Data layer is complete (`workshop_providers.dart`). Members tab must
  render "الأعضاء المسجّلون" and "الضيوف" as **two visually distinct
  groups**, per the spec.

### 5. المزيد — Settings

Built: a navigation hub plus its nested category screens and account/org
destinations. `/more` is Settings-hub-only — it shows grouped navigation
rows (with a short live summary on the Themes/Performance/Sync rows: active
palette + mode, active motion level + frame rate, sync/needs-review status)
and routes to:

- **Themes** (`/more/themes`) — the six-palette picker, Light/Dark/System
  mode, and eye-protect toggle, unchanged from their original implementation
  and still backed by `themeStateProvider` / `themeControllerProvider`.
- **Performance** (`/more/performance`) — the five-step motion/quality
  picker (`MotionLevel.performance` … `.maximum`, backed by
  `motionLevelProvider`) and the frame-rate picker (backed by
  `frameRateProvider` / `displayCapabilitiesProvider`), each exactly as
  before.
- **Sync** (`/more/sync`) — Manual Sync, pending-operation status, and the
  quiet Needs Review attention row, all still the same `SyncSettingsSection`
  widget and `syncCoordinatorProvider`/outbox wiring.
- **Profile** (`/more/profile`), **Security** (`/more/security`),
  **Notifications** (`/more/notifications`), **Org Info** (`/more/org`) —
  unchanged destination screens, data layer backed by mock repositories.

Sign-out lives at the bottom of the Account group on the hub, calling the
same `authRepositoryProvider.signOut()` as before.

## Interactions & Behavior

### Bottom navigation — the signature interaction

**Component:** `GlassBottomNav` (`lib/core/widgets/glass_bottom_nav.dart`).

- Sits inside a `Stack` in `MainShell`, not the `Scaffold.bottomNavigationBar`
  slot — so it floats over content instead of pushing it up. Screens that
  scroll under it wrap their body in `FloatingNavPadding` (adds 96 +
  safe-area bottom padding).
- The pill is a `Container` with `color: c.surface.withOpacity(0.62)`
  (0.55 in dark) + 1px border at 8% ink (10% white in dark) + two-layer
  drop shadow. It's wrapped in `ClipRRect(pill radius)` → `BackdropFilter(
  blur: 22)` → `Container`.
- Four `_GlassTab` children (home / detachment / workshop / more). Each:
  - `AnimatedContainer` morphs its `color` between transparent and
    `c.primary` (with a matching `boxShadow` when active) over
    `MotionTokens.navPillMorph` (280ms) with `MotionTokens.spring`.
  - The label text is inside `AnimatedAlign(widthFactor: active ? 1 : 0)`
    + `AnimatedOpacity` so it slides + fades in from a 0-width state,
    matching the iOS 17 liquid-glass pattern.
  - `PressScale` gives every tab a 0.97 tap feedback.
- Under `MotionLevel.reduced` **or** `MediaQuery.disableAnimations`,
  `BackdropFilter` is DROPPED entirely; the pill switches to a solid
  `c.surface.withOpacity(0.96)` (0.92 in dark). The blur is the single
  heaviest effect in the app on low-end Android; this is the whole
  reason the setting exists.
- The nav is wrapped in `RepaintBoundary` in both modes so scroll frames
  don't repaint the glass card.

### Page transitions

- Every top-level route uses `SharedAxisPageTransition` (X-axis fade +
  small horizontal slide). Under reduced motion the transition returns
  the child directly, no animation.
- Inner tab switching uses `TabCrossFade` (`AnimatedSwitcher` with a
  fade transition, 200ms).
- The `AnimatedTabBar` indicator (3px pill under the active tab) slides
  with `AnimatedPositionedDirectional` over 280ms `MotionTokens.emphasized`.

### Lock Window

`lib/core/widgets/lock_window.dart`. Three states:

| State        | Background       | Foreground     | Icon                  | Body                              |
|--------------|------------------|----------------|-----------------------|-----------------------------------|
| `open`       | `c.okTint`       | `c.ok`         | `Icons.lock_open`     | Caption "قابل للتعديل" + mm:ss    |
| `restricted` | `c.warnTint`     | `c.warn`       | `Icons.vpn_key`       | Caption "مقيّد" + "تعديل بصلاحية" |
| `sealed`     | `c.mutedTint`    | `c.ink2`       | `Icons.lock`          | Caption "مُثبَّت" + "أضف تصحيحا"  |

When `open` and `remaining.inSeconds < 60`, a `SingleTickerProviderStateMixin`
drives a `reverse: true` `repeat` animation that pulses a colored halo
`BoxShadow` around the chip. Halo animation is skipped under reduced
motion.

### Attendance progress bar

Custom widget in `home_page.dart` — a `TweenAnimationBuilder` easing
`begin: 0 → end: progress` over 700ms `easeOutCubic`. `FractionallySizedBox`
inside a `ClipRRect(pill)` stack. Runs on first paint only; rebuilding
the parent re-animates from 0 (this is intentional — attendance
snapshots are checkpoints, not a live stream).

### Stagger (list entry)

`lib/core/motion/stagger.dart`. Wraps a list item, takes an index. For
indices 0..7 it delays by `index * 34ms`, animates opacity 0→1 and Y
+10px→0 over `240ms + delay`, curve `spring`. Indices ≥8 render
immediately. Under reduced motion the wrapper is a no-op.

### Press feedback

`PressScale` — `AnimatedScale` to 0.97 during pointer-down, 120ms
`MotionTokens.standard`. Applied to every tappable card, chip, and
nav tab. Under reduced motion the scale stays at 1.0.

### Pull-to-refresh

`AppRefreshIndicator` wraps a `RefreshIndicator` themed to `c.primary`.
Displacement 32, stroke 2.4. Consumers pass an `async` callback that
returns the `.future` of the underlying `FutureProvider` (so Riverpod
refetches).

## State Management

**Riverpod 2** only. `NotifierProvider` / `AsyncNotifierProvider` for
mutable state, `FutureProvider.family` for parameterized fetches.

- `themeControllerProvider` — current palette (Slate/Copper/Clay) + ThemeMode
- `motionLevelProvider` (**AsyncNotifierProvider<MotionLevel>**) — the user
  motion setting. Hydrates from `SettingsRepository.motionLevel()`. If the
  repo returns `null` (first launch), the notifier reads
  `WidgetsBinding.instance.platformDispatcher.views.first.platformDispatcher
  .accessibilityFeatures.disableAnimations` and defaults to `reduced` when
  the OS reports reduce-motion. `.set(level)` optimistically updates state
  then persists via `SettingsRepository.updateMotionLevel()`.
- `authRepositoryProvider`, `detachmentRepositoryProvider`, etc. — expose the
  abstract repository interfaces. Swapping to a real (network-backed) impl
  is a one-line `Override` in `ProviderScope`.
- `homeSummaryProvider`, `detachmentListProvider(query)`,
  `teamListProvider(detachmentId)`, ... — `FutureProvider`s that return
  `Result<T>` from the repositories.

Widgets read `Result<T>` and pattern-match with `.when(success, failure,
offline)`. No widget ever `throw`s from a repo boundary.

`MotionScope` is an `InheritedWidget` bound at the app root in `main.dart`.
`reduceMotion(context)` returns true if the OS reports disable-animations
OR `MotionScope.of(context) == MotionLevel.reduced`. Every animated widget
in the app reads through this single function — there are no scattered
`if (reduced)` branches inside individual widgets.

## Design Tokens

### Palettes (`lib/core/theme/app_palette.dart`)

Each palette has a full light + dark variant. All 6 sets ship. Exact hex
values below (Slate — the default; see `app_palette.dart` for Copper and
Clay).

**Slate light:**
```
bg              #ECEAE4    surface       #FFFFFF    surface2   #F5F3EE
surface3        #E4E1D9    ink           #1A1F26    ink2       #4A5058
ink3            #7A8189    line          #DAD6CC    line2      #C7C2B4
primary         #B84A3E    primaryInk    #FFFFFF    primaryPressed #9E3B2F
primaryTint     #F5E4E0    ok            #1F8F5A    okTint     #DFF1E7
warn            #D48806    warnTint      #FBEBCB    crit       #7A241B
critTint        #F0D8D3    info          #1B6C99    infoTint   #DCEBF3
muted           #7C8B92    mutedTint     #E4E7E8    focus      #B84A3E
```

**Slate dark:**
```
bg              #0F1319    surface       #171C24    surface2   #1E242E
surface3        #262D38    ink           #EDECE6    ink2       #B4B7BD
ink3            #7C8189    line          #2B323D    line2      #3A424F
primary         #D26254    primaryInk    #FFFFFF    primaryPressed #B84A3E
primaryTint     #3A1E1A    ok            #3AB878    okTint     #143726
warn            #E8A63D    warnTint      #3A2A0F    crit       #E24E3F
critTint        #3D1A16    info          #4C9BCB    infoTint   #13293A
muted           #8A939B    mutedTint     #2A303A    focus      #D26254
```

Access from any widget: `context.c.primary`, `context.c.warnTint`, etc.

### Spacing (`AppSpacing`)
```
xs 4    sm 8    md 12    lg 16    xl 20    xxl 24    xxxl 32
```

### Radii (`AppRadii`)
```
sm 8    md 10    lg 12    xl 16    xxl 20    pill 999
```

### Typography (`lib/core/theme/app_typography.dart`)

- Family: **IBM Plex Sans Arabic** (bundled — three static TTFs under
  `flutter_app/assets/fonts/`, declared in `pubspec.yaml`). Do NOT swap
  for `google_fonts` — the app is offline-first.
- Weights shipped: **400 Regular**, **500 Medium**, **600 SemiBold**.
- **JetBrains Mono was removed** — it has no Arabic-Indic numeral glyphs,
  which caused silent fallback whenever a counter or stat rendered a
  digit. All numeric styles now use `AppTypography.number(c, size: X)`,
  which is the same family with `fontFeatures: [FontFeature.tabularFigures()]`
  so digits stay aligned.

Scale:
```
displayLarge     — from base, ink, w600
headlineLarge    26 / w600 / 1.2
headlineMedium   22 / w600 / 1.25
titleLarge (titleLg)  20 / w600
titleMedium      17 / w600
titleSmall       13 / w500 / ink2
bodyLarge        16 / normal
bodyMedium (body) 14 / normal / 1.55
bodySmall        12 / normal / ink3 / 1.5
labelLarge (buttonLabel) 15 / w600
number(size)     size / w600 / tabular
eyebrow          12 / w600 / 0.7 letter-spacing / ink3
```

### Motion (`lib/core/motion/motion_tokens.dart`)

Every animation duration in the app comes from here:
```
instant   80ms
micro    120ms
short    200ms
medium   280ms (also navPillMorph)
long     420ms
xLong    600ms

staggerStep      34ms      staggerItem 240ms      staggerMaxItems 8
pressScale       0.97
```

Curves:
```
emphasized  Cubic(0.2, 0, 0, 1)
standard    Cubic(0.4, 0, 0.2, 1)
spring      Cubic(0.34, 1.28, 0.64, 1)
exit        Cubic(0.4, 0, 1, 1)
enter       Cubic(0, 0, 0.2, 1)
```

Helpers `effectiveDuration(context, d)` and `effectiveCurve(context, c)`
return `Duration.zero` / `Curves.linear` under reduced motion. Widgets
should always call these instead of the raw constants when the animation
should respect the setting.

### Shadows

Only two places use `BoxShadow` — everything else relies on hairline
borders + surface tints:

- **Glass bottom nav** — see the exact shadow arrays in
  `glass_bottom_nav.dart`. Two-layer for light mode, three-layer with
  higher opacities in dark mode.
- **Active nav pill** — single soft shadow `c.primary.withOpacity(0.55)`
  blur 12 y+4 spread −2.

## Assets

### Fonts (bundled)
- `flutter_app/assets/fonts/IBMPlexSansArabic-Regular.ttf` — 400 (236 KB)
- `flutter_app/assets/fonts/IBMPlexSansArabic-Medium.ttf` — 500 (242 KB)
- `flutter_app/assets/fonts/IBMPlexSansArabic-SemiBold.ttf` — 600 (244 KB)
- `flutter_app/assets/fonts/OFL.txt` — SIL Open Font License 1.1

Source: [google/fonts on GitHub — ofl/ibmplexsansarabic](https://github.com/google/fonts/tree/main/ofl/ibmplexsansarabic).

### Icons
Material Icons (`Icons.flag_rounded`, `Icons.home_rounded`,
`Icons.school_rounded`, `Icons.more_horiz_rounded`,
`Icons.health_and_safety_rounded`, `Icons.lock_open_rounded`,
`Icons.vpn_key_rounded`, `Icons.lock_rounded`, `Icons.event_busy_rounded`,
`Icons.timer_outlined`, `Icons.person_add_alt_1_rounded`,
`Icons.cloud_off_rounded`, `Icons.hourglass_empty_rounded`,
`Icons.error_outline_rounded`, `Icons.refresh_rounded`,
`Icons.smartphone_rounded`, `Icons.access_time_rounded`,
`Icons.lock_reset_rounded`, `Icons.copy_rounded`,
`Icons.arrow_back_rounded`, `Icons.notifications_none_rounded`,
`Icons.add_rounded`, `Icons.search_rounded`, `Icons.edit_outlined`,
`Icons.workspace_premium_rounded`, `Icons.medical_services_rounded`,
`Icons.school_rounded`, `Icons.volunteer_activism_rounded`,
`Icons.check_rounded`, `Icons.insights_rounded`,
`Icons.group_outlined`). No third-party icon pack needed.

### Images
None. Placeholders use tinted `Container` shapes.

## Files

Everything under `flutter_app/` in this bundle is the primary reference.

### Bootstrap
- `flutter_app/pubspec.yaml` — deps: `flutter_riverpod ^2.5.1`,
  `go_router ^14.2.7`, `intl ^0.19.0`, `qr_flutter ^4.1.0`. Fonts
  declared here.
- `flutter_app/analysis_options.yaml` — strict-casts, strict-raw-types.
- `flutter_app/lib/main.dart` — RTL wrap, `MotionScope`, `ProviderScope`.

### Core
- `flutter_app/lib/core/theme/` — `app_palette.dart`, `app_theme.dart`,
  `app_typography.dart`, `theme_controller.dart`.
- `flutter_app/lib/core/motion/` — `motion_tokens.dart`, `motion_level.dart`,
  `transitions.dart`, `press_scale.dart`, `animated_counter.dart`,
  `stagger.dart`.
- `flutter_app/lib/core/result/result.dart` — sealed `Result<T>` =
  `Success | Failure | Offline`.
- `flutter_app/lib/core/router/app_router.dart` — `StatefulShellRoute`
  with 4 branches and deep-linkable inner tabs for detachment & workshop.
- `flutter_app/lib/core/widgets/` — `glass_bottom_nav.dart`,
  `lock_window.dart`, `skeleton.dart`, `empty_state.dart`,
  `error_state.dart`, `offline_banner.dart` (+ `StaleBadge`),
  `status_chip.dart`, `section_header.dart`, `animated_tab_bar.dart`,
  `sheet_scaffold.dart`, `refresh_indicator.dart`.
- `flutter_app/lib/l10n/strings.dart` — single-source Arabic strings.

### Features (data layer complete for every feature)
- `flutter_app/lib/features/auth/`
- `flutter_app/lib/features/detachment/`
- `flutter_app/lib/features/home/`
- `flutter_app/lib/features/inventory/`
- `flutter_app/lib/features/settings/`
- `flutter_app/lib/features/shift/`
- `flutter_app/lib/features/team/`
- `flutter_app/lib/features/workshop/`
- `flutter_app/lib/features/shell/main_shell.dart`

### Features (presentation — built)
- **All auth screens** — login, mfa_setup, mfa_challenge, forgot_password,
  otp, new_password, session_expired, new_device.
- **Home** — `home_page.dart` (complete, all states).
- **Detachment** — `detachment_list_page.dart`,
  `detachment_detail_shell.dart`, `tabs/detachment_team_tab.dart`.

### Features (presentation — TO BUILD)
The `app_router.dart` references these; create them following the same
patterns (Riverpod `.when` on `Result<T>` + loading/empty/error/offline +
`Stagger` + `PressScale`):

- `detachment/presentation/detachment_edit_page.dart`
- `detachment/presentation/tabs/detachment_shifts_tab.dart`
- `detachment/presentation/tabs/detachment_storage_tab.dart`
- `detachment/presentation/tabs/detachment_stats_tab.dart`
- `workshop/presentation/workshop_list_page.dart`
- `workshop/presentation/workshop_detail_shell.dart`
- `workshop/presentation/workshop_edit_page.dart`
- `workshop/presentation/tabs/workshop_team_tab.dart`
- `workshop/presentation/tabs/workshop_members_tab.dart` — must group
  registered members and guests as two visually distinct sections.
- `workshop/presentation/tabs/workshop_stats_tab.dart`
- `settings/presentation/settings_page.dart` — expose the motion-level
  toggle here (see State Management section above).
- `settings/presentation/profile_page.dart`
- `settings/presentation/security_page.dart` — session list from
  `AuthRepository.listSessions()`, each row has a "إلغاء" action calling
  `revokeSession(id)`.
- `settings/presentation/notifications_page.dart`
- `settings/presentation/org_info_page.dart`

### HTML design references
Kept at the workspace root — treat as visual reference only:
- `flutter_preview.html` — live tokenized preview of the design language.
- `index.html` + `screens_1.jsx`, `screens_2.jsx`, `screens_3.jsx` — full
  screen catalogue that seeded this project.
- `tokens.css` — the CSS mirror of `app_palette.dart` (same hex values).

## Security note

`AuthRepository.beginMfaSetup()` carries an explicit **SECURITY CONTRACT**
in its doc comment: the TOTP secret, the full `otpauth://` URI, and the
backup codes are **all server-issued**. The mock implementation returns a
fixed fixture with a `TODO(backend)` marker; a real implementation must
POST to `/api/v1/mfa/setup` and return the server response verbatim.
Never generate a TOTP secret on the client.

## Definition of done for the outstanding work

For any not-yet-built screen:

1. Read the corresponding repository + provider from `features/<x>/data/`.
2. In a `ConsumerWidget` (or `ConsumerStatefulWidget` if you need
   controllers), `ref.watch(...)` the provider.
3. Handle **every** state: loading (Skeleton), empty (EmptyState with
   icon + one-line explanation + action button), error (ErrorStateView
   with `onRetry: () => ref.invalidate(provider)`), offline (StaleBadge
   or the cached content), success.
4. Use `Stagger(index: i)` on the first 8 list items.
5. Wrap every tappable in `PressScale`.
6. Pull to refresh with `AppRefreshIndicator(onRefresh: () async =>
   ref.refresh(provider.future))`.
7. Bottom sheets go through `showAppSheet(title, child)`.
8. Every user-facing string comes from `l10n/strings.dart` (`S.xxx`).
   No Arabic literals in widgets.
9. Every color is `context.c.xxx`. No inline hex.
10. Every duration is `effectiveDuration(context, MotionTokens.xxx)`.
    Never a raw `Duration(milliseconds: …)`.
