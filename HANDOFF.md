# MTM Front-Back — current handoff

Read in this order to resume:

1. `CLAUDE.md`
2. **this file** — start with **§ZZZZZZZZZZZ (latest session)**, then
   §ZZZZZZZZZZ, §ZZZZZZZZZ, §ZZZZZZZZ, §ZZZZZZZ, §ZZZZZZ, §ZZZZZ, §ZZZZ, §ZZZ,
   §ZZ, §Z, §A, then §0–§7 (all earlier, still accurate)
3. `SCHEDULE-CHANGES-HANDOFF.md` (older handoff — still accurate for the
   template/manage-sheet architecture it introduced; §4 records where a later
   session changed its rulings)
4. the working-tree diff (`git status`, `git diff`)

Branch: `main`, working tree only — nothing committed for this work.
Date: 2026-09-05.

---

## ZZZZZZZZZZZ. Latest session — 2026-09-05 (Point 4 — Notifications Center)

One area only. No redesign of the dashboard, Shifts, Inventory, Members,
Detachments or Settings; one new route, no new packages, no navigation
architecture change. `flutter analyze`: clean. `flutter test`: **536 pass / 0
fail** (486 before, +50 new). `dart format` run on the files this pass
touched. `git diff --check`: clean.

### What existed before this pass: nothing

The audit found **no notification domain, feed, model, repository, badge, or
screen** anywhere in the app. The one thing named "notifications" was
`/more/notifications` — `NotificationPrefs`, four push toggles, which is a
preference screen, not a feed. `API_CONTRACT.md` had no notifications
endpoint. Nothing in the app carried a notification icon, so there was no dead
badge to wire up either.

### What was built, and why it is not a fake backend

There is no notification table to read, so the centre **derives** its rows
from records that already exist, the way `MockHomeRepository` derives the
dashboard. `MockNotificationRepository` joins the shift and inventory
repositories; the client half is read straight off the outbox. Every row
therefore points at a real record with a real id, and disappears the moment
its condition is resolved. Nothing was seeded to fill the screen.

**Eight kinds, all backed by data the app can actually observe:** a shift
short of people, a finished shift with attendance unrecorded inside its
window, a shift starting within six hours, an item that ran out, an item under
its minimum, an item near expiry, a queued write that failed, a queued write
waiting on a conflict decision. One row per item, worst condition wins — the
same fold `storageStatusOf` uses.

**Three files carry the whole decision layer**, all pure Dart:
`notification_models.dart` (values, copy-free like `DashboardAlert`),
`notification_selectors.dart` (builders, capability filter, read-state stamp,
day grouping, destination mapping), and `notification_read_store.dart` (the
read-state seam, sitting beside `OutboxStore` and `ConflictReviewStore`
because read state covers rows from **both** halves of the feed).

### Three rulings worth keeping

1. **Ids are a function of the condition, not of the fetch.**
   `<kind>:<record id>`. The feed is rebuilt from scratch on every load, and
   read state is keyed by the id — a regenerated id would silently un-read
   every row the user had already seen. Tested.
2. **The fetch is split from the merge.** `notificationSourceProvider` asks
   the repository; `notificationFeedProvider` is a plain `Provider` that
   merges in the outbox, the read set and the session's grants. Written the
   other way round first, and every outbox change restarted a full round trip
   — which is also what broke eleven dashboard tests and two conflict tests
   with pending timers. The split is the fix and the right shape.
3. **Capability gates degrade the destination, they never fake one.** A
   volunteer is not told a shift is understaffed or that the store is low
   (`buildDashboardAlerts`' rule), but may know a shift starts soon — and
   tapping it opens the read-only schedule tab instead of a management sheet
   where every control would be disabled.

### Entry point and badge

One bell, in the dashboard's app bar, badged from
`unreadNotificationCountProvider` — which counts the very list the screen
renders, so the two cannot drift after a read, a mark-all, a refresh, or a
sync run. The dashboard's alert rows are unchanged: they still open the
surface that fixes each condition directly, which is a shorter path than
routing them through a list.

`/notifications` is a **root** route beside `/needs-review`, for the same
reason — a full surface opened deliberately, so it covers the bottom nav.

### One pre-existing test harness was touched

`dashboard_states_test.dart` now stubs `notificationSourceProvider` empty in
its `_pump`. The bell gave the dashboard a real new dependency; the assertions
are untouched. Nothing else in the preserved suites changed.

### Backend/domain gaps this pass could not close

- **No notification backend.** `API_CONTRACT.md` § Notifications now specifies
  `GET /api/v1/notifications` and `PUT /api/v1/notifications/read`; neither
  exists. Until they do, announcements, assignment/update/cancellation events,
  team messages and join requests **cannot** be shown — there is no record
  behind any of them, so none were invented.
- **Read state does not survive a relaunch.** `InMemoryNotificationReadStore`
  lives for the life of the object, exactly like the theme preference and the
  active-detachment choice. The seam is complete; there is still no durable
  local store in this build.
- **Read state is not queued to the outbox.** Deliberate: there is no
  transport, so `notification.read` operations would pile up forever and
  inflate the "بانتظار المزامنة" count on Settings and the dashboard. A real
  repository should enqueue them.
- **`NotificationPrefs` governs push, and there is no push.** No push package
  is in `pubspec.yaml`. The four toggles are not used to filter the in-app
  centre on purpose: switching off a *push* is not asking to be kept in the
  dark about a critical stock level when you open the app yourself.
- **No personal feed.** `AuthUser` still carries no link to a `TeamMember`
  (the same gap Point 2 recorded), so "your shift is starting" is really "a
  shift at your detachment is starting".

## ZZZZZZZZZZ. Earlier session — 2026-09-05 (Points 2 & 3 — Today dashboard finalized, Members module completed)

Two areas only. No redesign of Shifts, Inventory, Statistics, Detachments or
Settings; no new routes, no new packages, no navigation architecture change.
`flutter analyze`: clean. `flutter test`: **486 pass / 0 fail** (435 before,
+51 new). `dart format` run on the 17 files this pass touched.
`git diff --check`: clean.

### Point 2 — the Today dashboard was decorative; it is now operational

**What was wrong.** `MockHomeRepository` returned a hard-coded detachment
name, a hard-coded shift, and three invented "decisions" (including a join
request the app has no concept of). None of it carried an id, so every card
and every button on Home was a dead end, and the figures agreed with nothing
else in the app.

**What replaced it.** The `HomeRepository` seam is kept — a single-round-trip
summary is right for a mobile client — but it is now real:

- `HomeSummary` carries `detachmentId`, the detachment's identity, the shifts
  for **yesterday/today/tomorrow**, roster count, and the storage fold.
  Three days because "now" and "next" are clock questions: a 20:00–02:00
  shift dated yesterday is still running at 01:00.
- `MockHomeRepository` **composes** the detachment, shift, inventory and team
  repositories (the pattern `MockShiftRepository` already used for the
  roster), so a figure on the dashboard cannot disagree with the tab it links
  to. A section that fails degrades to "nothing known" instead of taking the
  screen down.
- `summary()` now takes a `detachmentId`. `API_CONTRACT.md` § Home updated.

**Which detachment.** `DETACHMENT-SCOPING.md` §4's proposal, implemented:
one at a time, deterministic seed (explicit choice if still valid → the only
one → first by name), a switcher rendered *only* when there is more than one.
Persistence across relaunch is still not possible (no durable local store —
the same gap the theme preference has), so the choice re-seeds deterministically
rather than being remembered wrongly.

**Decision layer, extracted and tested.** `shift/domain/shift_selectors.dart`
(current/next shift, attendance counts — shift-domain logic, so both the
dashboard and a member's page read the same answers) and
`home/domain/today_selectors.dart` (the alert rules). Two rules govern alerts:
nothing is raised without a record behind it, and nothing is raised at a user
whose grants cannot fix it (sync alerts excepted — those are their own writes).

**Screen.** Context header → current shift (manager, lock window, attendance
present/awaiting/absent/gap) → next shift → alerts → role-aware quick actions.
Every action opens an **existing** destination: the shift management sheet,
`/detachment/:id/{shifts,team,storage,stats}`, `/more/sync`, `/needs-review`.
The decorative stat cards (attendance rate, workshops this week) are gone —
that is Statistics' job, not Today's.

### Point 3 — Members completed in place, not rebuilt

The roster, the member form (add/edit/role/delete, each already gated) and the
member page already existed; nothing was duplicated. What was missing:

- **Search + filters** on the roster tab: a search field, a filter sheet
  offering only facets the data actually has (role, section), removable active
  filter chips, and a header that says how much of the roster is showing.
  Filtering is in memory (`team/domain/member_search.dart`) — a roster is tens
  of records, so a keystroke costs nothing and never touches the network.
- **Arabic search that works**: `memberSearchKey` folds أ/إ/آ→ا, ى→ي, ة→ه,
  strips harakat and tatweel, and maps Arabic-Indic digits, so "احمد" finds
  "أحمد" and "١٠٣" finds "103". `memberNameKey` (identity/duplicate detection)
  stays strict on purpose — folding there would merge two real people.
- **Member page**: identity card (detachment, section, number), a contact card
  gated on `Cap.memberContactView` (withheld and absent are different states,
  and it says which), and today's assignment — which opens the **existing**
  shift management sheet. Shifts remains the source of truth; Members is only
  a member-centric way in.

### Three real bugs the new tests caught

1. Two shifts short on the same day produced two alert rows keyed by kind
   alone — duplicate sibling keys, which is a hard crash. `d_dam_central` has
   exactly this shape today. Keys now carry the shift id.
2. The detachment picker's rows captured the page's context, so tapping one
   would have popped the dashboard instead of the sheet.
3. `SkeletonList` (a `ListView`) was used as a loading placeholder inside the
   member page's own `ListView` — unbounded height, i.e. a red screen while
   loading.

### Backend capability that blocked one thing

`AuthUser` carries no link to a `TeamMember`, so "my shift / my attendance"
for a plain volunteer is not resolvable on the client. The dashboard therefore
reports the **detachment's** day and gates management actions by capability,
rather than inventing a personal view. A `memberId` (or equivalent) on the
session profile is what would unlock it.

## ZZZZZZZZZ. Earlier session — 2026-09-05 (Settings IA Point 1 — hub + nested Themes/Performance/Sync screens)

**Point 1 of the Settings redesign only.** No backend, no `MTM-PRO` change,
no redesign of Profile/Security/Notifications/Org (Points 2–5 of that brief)
— their routes, contents, repositories, models, and workflows are untouched.
The working tree from every prior session was preserved; nothing reset,
reverted, or reformatted outside the files this pass touched.

`flutter analyze`: clean, whole project. `flutter test`: **435 pass / 0
fail** (roughly +17 new across the three new Settings test files, on top of
the pre-existing suite). `dart format` run only on the 12 files this pass
touched (3 needed reformatting: `settings_page.dart` and two of the new
test files). No `git diff --check` issues on the tracked files this pass
changed; the new/untracked files were checked by hand for trailing
whitespace instead, and are clean.

### The problem

`/more` mixed six theme controls, two performance controls, Manual Sync +
the conflict attention row, four account links, and sign-out on one long
page — the brief's "too many unrelated controls" complaint. The screen's
job was doing double duty as both a navigation index and a control panel.

### The information-architecture decision

`/more` becomes navigation-only: four grouped sections (Appearance & Device,
Data & Sync, Account, Organization) of `NavigationRow`s, each with an icon, a
label, and — for Themes/Performance/Sync only — a short live-state summary
(e.g. "طبّي · فاتح", "متوازنة · تلقائي", or the sync/needs-review line)
reusing strings the app already had. No control renders directly on the hub
any more; every one moved to its own nested screen, verbatim.

### Routes added (all children of the existing `/more` `GoRoute`, same
`_moreBranch`/`_sharedAxisPage` convention as every existing nested Settings
route — no new navigator, no new transition)

- `/more/themes` → `ThemesPage` — six-palette picker, Light/Dark/System,
  eye-protect.
- `/more/performance` → `PerformancePage` — the five-step motion/quality
  picker, the frame-rate picker.
- `/more/sync` → `SyncPage` — wraps the existing `SyncSettingsSection`
  widget unchanged (Manual Sync, pending count, the quiet Needs Review
  attention row).

### Controls moved / providers reused

Every control was **moved**, not reimplemented: same `themeStateProvider` /
`themeControllerProvider`, `motionLevelProvider`, `frameRateProvider` /
`displayCapabilitiesProvider`, `syncCoordinatorProvider` /
`pendingOperationsCountProvider` / `conflictOperationsCountProvider`, and the
same `SyncSettingsSection` widget (Task 4's conflict/Outbox wiring — Auto
Sync still cannot navigate, Manual Sync still never force-opens a conflict,
the attention row still opens `NeedsReviewPage.routePath` only on an
explicit tap). The five reusable pieces the old single-file page built
inline (`_SectionLabel`, `_SettingsSection`, `_NavigationRow`, `_PickerRow`,
`_ChoicePill`) were extracted, made public, and moved to
`features/settings/presentation/widgets/settings_widgets.dart` so the hub
and both new pickers screens share one implementation instead of three.
`_MotionPicker`/`_FrameRatePicker` moved with the rest of their screen into
`performance_page.dart` and stayed private — nothing else uses them.

### Provisional/mock behavior unchanged

Everything already documented as mock/provisional stays that way:
`MockSettingsRepository`'s simulated latency, the in-memory outbox, the
mock Profile/Security/Notifications/Org repositories. This pass added no
backend integration and claims none.

### Files changed

- New: `features/settings/presentation/{themes,performance,sync}_page.dart`,
  `features/settings/presentation/widgets/settings_widgets.dart`.
- Rewritten: `features/settings/presentation/settings_page.dart` (now hub
  only).
- Edited: `core/router/app_router.dart` (three routes added),
  `l10n/strings.dart` (one new string, `settingsPerformanceTitle` — Themes
  and Sync reuse existing `settingsAppearance`/`sectionSync` strings, same
  pattern the Organization section/row already used).
- Tests: `test/features/settings/{settings_hub,themes_page,performance_page}_test.dart`
  (new); `test/core/router/app_router_test.dart` (three new locations);
  `test/features/conflict/needs_review_page_test.dart` (its full-app boot
  now lands on `/more/sync`, where the attention row actually lives —
  same widget, same assertions, still proves Auto Sync never navigates and
  Manual Sync never force-opens a conflict).

### Docs corrected

`README.md` §5 and `DATA-NEEDS.md` §2.5 no longer say Settings is "NOT
built"/"stub" — both now describe the hub + nested screens as built (screen
exists; still mock-repository-backed, no backend integration claimed).
Nothing outside the Settings section of either file was touched.

---

## ZZZZZZZZ. Latest session — 2026-09-05 (Task 4 corrective pass — useLocal/useCurrent protocol, Shift snapshot path)

> **Addendum — same day, final narrow correction.** This session's own
> `applyShiftConflictCurrentVersion` deleted its captured `ShiftConflictSnapshot`
> the moment it applied it — before the outbox operation was actually
> retired, so a failed retirement afterwards would have left nothing to
> retry with. A follow-up pass fixed this: the applier now only applies and
> returns `true`/`false`; cleanup moved to a new sibling seam,
> `ConflictSnapshotCleaner`/`conflictSnapshotCleanersProvider`
> (`conflict_current_application.dart`), which `applyConflictResolution`
> invokes **last**, after the outbox step and the review-entry forget both
> succeed — in both `useLocal` and `useCurrent`, so both now remove the
> typed snapshot (this session's text below only ever describes `useCurrent`
> applying one; it never removed it either way). The same follow-up pass
> also closed two validation gaps this session left open:
> `OutboxController.supersedeConflict` now rejects an original operation
> that is not `SyncState.conflict` and a missing/empty `resolutionVersion`,
> both before any store write, and `applyConflictResolution` enforces the
> same two checks plus `decision.conflictId == operation.operationId` before
> resolving either intent. `reviewLater` is unaffected — it still calls
> nothing, so it still removes nothing. Touched only:
> `outbox_controller.dart`, `conflict_current_application.dart`,
> `conflict_outbox_resolver.dart`, `shift_conflict_review.dart`, and their
> three matching test files. `flutter analyze`: clean.
> `flutter test`: **416 pass / 1 fail** — the one failure is
> `test/features/conflict/needs_review_inbox_test.dart`'s `useLocal`
> decision test, which predates this correction and calls `useLocal` with no
> `currentVersion`; that file was outside this narrow pass's allowed-file
> list, so it was reported as a blocker rather than edited. See that pass's
> own completion report for the full detail.

**Corrective continuation of Task 4 only.** No other roadmap item started,
no backend, no `MTM-PRO` change. The working tree from every prior session
(§ZZZZZZZ and earlier) was preserved — nothing reset, reverted, deleted, or
reformatted outside the files this pass actually changed.

`flutter analyze`: clean, whole project. `flutter test`: **407 pass / 0
fail** (376 before this pass + 31 new — see "Tests added" below).
`dart format` run only on the 17 files this pass changed (8 needed
reformatting). No tracked file in the repo has a diff to run
`git diff --check` against — `core/sync`, `features/conflict`, and most of
`features/shift` are untracked working-tree state from earlier sessions (see
`git status`); every file this pass touched was checked by hand for trailing
whitespace and conflict markers instead, and is clean.

Full contract: `FRONTEND-BACKEND-INTEGRATION.md` §5 ("Resolution protocol and
idempotency", now implemented) and §7 (corrected — see its own "Corrective
pass" note and "What changed in the corrective pass" section).

### Root causes corrected

§ZZZZZZZ's own "Deliberate limits" section already named exactly what was
wrong, and this pass fixes each of them:

1. **`useLocal` called `OutboxController.requeueAfterConflict`** — reusing
   the original `operationId`/`idempotencyKey` for what §5.5 says must be a
   *new* logical write (its body carries a different `version`). Fixed: it
   now calls the new `OutboxController.supersedeConflict`.
2. **`useCurrent` dropped the pending operation without ever applying the
   chosen current record locally** — a user who chose "استخدام النسخة
   الحالية" would still see their own stale edit on screen, because nothing
   ever wrote the current/shared version back into local state. Fixed: a
   feature-owned `ConflictCurrentApplier` runs first; the operation is only
   retired if it reports success.
3. **The production Shift composer registry was empty and unregistered** —
   Task 4 tests injected a finished `ConflictReviewEntry` directly, so the
   claimed "representative typed path" was not actually reachable from a
   real (or even mocked-future) detection. Fixed: `ShiftConflictSnapshot(Store)`
   + `composeShiftConflictReview` + `applyShiftConflictCurrentVersion` are
   built and registered in `main.dart` via `shiftConflictReviewOverrides`.
4. **`NeedsReviewPage`'s retry only invalidated `conflictReviewProvider`** —
   `needsReviewItemsProvider` joins that *and* `outboxProvider`; an
   outbox-load failure had no working retry. Fixed: retry invalidates both.

### State/model decisions

- `PendingOperation` gains two optional fields —
  `resolvesOperationId: String?` and `currentVersion: String?` — both
  `null` for an ordinary operation, both absent from `toJson()` when unset,
  both read back as `null` from a record serialized before they existed
  (`PendingOperation.fromJson` never throws on a missing key). This is the
  "smallest typed extension" §5.5 asked for — sync metadata, not a payload
  field, same rule the rest of the class already follows.
- `OutboxController.supersedeConflict` is the new primitive.
  `requeueAfterConflict` **still exists** — it is the right tool for a
  same-body retry, which `useLocal` is not — but nothing in the
  conflict-resolution path calls it anymore; its doc comment now says so.
- `ConflictCurrentApplier` / `conflictCurrentAppliersProvider`
  (`features/conflict/data/conflict_current_application.dart`) is the new
  `useCurrent` seam, built to the exact same shape as the existing
  `ConflictReviewComposer` / `conflictReviewComposersProvider` (empty
  default registry, feature registers itself via a composition-root
  override) — no new architecture invented, the existing pattern reused.

### Shift snapshot path

- `ShiftConflictSnapshot` (an ordinary `Shift` + two opaque version
  strings) and `ShiftConflictSnapshotStore` live in `features/shift/domain/`;
  `InMemoryShiftConflictSnapshotStore` (object-lifetime only, same
  limitation as every other in-memory store in this app) lives in
  `features/shift/data/`. `core/sync` imports none of this.
- `composeShiftConflictReview` reads the *local* side from
  `shiftRepositoryProvider` (the user's edit is still sitting there — a
  failed push never touches local state) and the *current* side from the
  snapshot store, then reuses `presentShiftConflict` unchanged and wraps the
  result with the new `ConflictReviewEntry.fromPresentation`. With no
  captured snapshot it returns `null` — the conflict stays listed as
  "details unavailable," never fabricated.
- `applyShiftConflictCurrentVersion` applies the snapshot's `Shift` through
  the ordinary `ShiftRepository.update` — the same repository call every
  other shift edit already goes through — and clears its own snapshot entry
  once that succeeds.
- `shiftConflictReviewOverrides` installs both over the empty defaults;
  `main.dart` applies it alongside the existing `conflictReviewOverrides`.
  This is what makes "the registered production Shift adapter can consume a
  supplied mocked/future typed snapshot" checkable today, without a real
  transport: seed `shiftConflictSnapshotStoreProvider`, and the exact
  production functions produce a real entry / apply a real local write —
  see `test/features/shift/shift_conflict_review_test.dart`.

### Exact `useLocal` ordering (`OutboxController.supersedeConflict`)

1. If a replacement already exists for `originalOperationId` (found by
   `resolvesOperationId`), return it — minting nothing new. If the original
   is somehow still present too, retire it now (recovers a prior run that
   created the replacement but failed to retire the original).
2. Otherwise, the original must still be on file, or the call throws
   (`StateError`) rather than silently doing nothing.
3. Mint the replacement through the existing `PendingOperation.create` /
   `newOperationIdProvider` seam — new `operationId`, new `idempotencyKey`,
   `resolvesOperationId: originalOperationId`,
   `currentVersion: resolutionVersion`.
4. **Store the replacement** (`OutboxStore.upsert`) — if this throws, the
   original is untouched: still `conflict`, same identity, same metadata.
5. **Only then retire the original** (`OutboxStore.remove`) — if this
   throws, the replacement is already durable, so both operations are left
   on file; never neither.
6. The resolver (`conflict_outbox_resolver.dart`) forgets the stored
   `ConflictReviewEntry` only after `supersedeConflict` returns without
   throwing.

### Exact `useCurrent` ordering (`applyConflictResolution`)

1. Look up the still-conflicted `PendingOperation` by `localOperationId` —
   throws if it is gone (already resolved/synced elsewhere).
2. Look up `conflictCurrentAppliersProvider[operation.entityType]`. Missing
   entry ⇒ treated as `applied = false`.
3. Await the applier. It applies the typed current snapshot through the
   owning feature's own repository and returns whether that write actually
   succeeded — never throws by contract, but a thrown error is caught the
   same way a `false` is (both mean "do not resolve").
4. `applied == false` ⇒ throw. The operation, its `SyncState.conflict`, and
   its stored review entry are all untouched.
5. `applied == true` ⇒ `OutboxController.discardConflict` retires the
   operation, **then** the review entry is forgotten.

### Failure-preservation evidence

Both orderings above are proven with failure-injecting fakes, not just
happy-path assertions:

- `test/core/sync/outbox_supersede_conflict_test.dart` — a fake `OutboxStore`
  that fails `upsert`/`remove` on demand proves: the replacement is stored
  before the original is removed (call-order assertion); a failed `upsert`
  leaves the original's identity, state and metadata untouched; a failed
  `remove` leaves both operations on file; a second call after a completed
  resolution mints nothing new; a second call after a *failed* retirement
  completes the retirement without minting a second replacement.
- `test/features/conflict/conflict_outbox_resolver_test.dart` — fake
  `ConflictCurrentApplier`s (returns `false`, throws, or is simply absent
  from the map) each independently prove the operation and its review entry
  survive a failed/missing `useCurrent` application, and that a failed
  `useLocal` mint (a throwing `newOperationIdProvider`) leaves the original
  conflict and its entry exactly as they were.
- `test/features/shift/shift_conflict_review_test.dart` proves the same
  guarantees through the *real*, registered Shift composer/applier (not
  fakes): no captured snapshot ⇒ `null`/`false` rather than a fabricated
  entry or a fabricated local write; a repository-rejected snapshot
  (`needed: 0`) fails the apply without throwing.

### Files changed / added this pass

```
lib/core/sync/pending_operation.dart                          (resolvesOperationId, currentVersion)
lib/core/sync/outbox_controller.dart                          (supersedeConflict; requeueAfterConflict doc corrected)
lib/features/conflict/data/conflict_current_application.dart  (new — ConflictCurrentApplier seam)
lib/features/conflict/data/conflict_outbox_resolver.dart       (useLocal/useCurrent rewritten)
lib/features/conflict/domain/conflict_review_entry.dart        (ConflictReviewEntry.fromPresentation)
lib/features/conflict/presentation/needs_review_page.dart      (retry invalidates both sources)
lib/features/shift/domain/shift_conflict_snapshot.dart          (new — typed snapshot + store interface)
lib/features/shift/data/in_memory_shift_conflict_snapshot_store.dart  (new — MOCK)
lib/features/shift/data/shift_conflict_review.dart              (new — composer/applier + overrides)
lib/features/shift/data/shift_providers.dart                    (shiftConflictSnapshotStoreProvider)
lib/main.dart                                                    (installs shiftConflictReviewOverrides)

test/core/sync/pending_operation_test.dart                      (new field group)
test/core/sync/outbox_supersede_conflict_test.dart              (new — 11 tests)
test/features/conflict/conflict_outbox_resolver_test.dart       (rewritten — 7 tests)
test/features/conflict/needs_review_page_test.dart              (useLocal/useCurrent assertions updated; 2 retry tests added)
test/features/conflict/needs_review_inbox_test.dart             (useLocal/useCurrent assertions updated)
test/features/shift/shift_conflict_review_test.dart              (new — 8 tests, the real Shift adapter)
```

### Remaining provisional / blocked-on-backend work (unchanged in kind)

- Both new in-memory stores (`ShiftConflictSnapshotStore`,
  `ConflictReviewStore`) are object-lifetime only — not durable across an OS
  process restart. A concrete store writes the same JSON shapes to the
  encrypted DB alongside `pending_operations`.
- Nothing is recorded or applied in the shipped app yet, despite the
  registration being real: no real `SyncTransport` exists to ever write a
  captured snapshot into `ShiftConflictSnapshotStore`. This is unchanged
  from before this pass and is not a gap this pass could close — it depends
  on the backend `409 stale_write` body shape (`FRONTEND-BACKEND-
  INTEGRATION.md` §7's still-open `Backend contract decision required`).
- The resolution operation `supersedeConflict` mints is never actually
  pushed anywhere — no wire body, no `Idempotency-Key` header exists to
  carry `currentVersion` in yet. It waits in the outbox as an ordinary
  pending write, exactly like any other operation, until a real
  `SyncTransport` exists.
- The Settings `ListTile`-inside-`_SettingsSection` debug assertion
  (`needs_review_page_test.dart`'s suppression) was re-checked this pass:
  it comes from Flutter's own `ListTile._debugCheckBackgroundIsHidden`,
  which fires whenever a `ListTile` sits inside an ancestor with a
  background color — that is `_NavigationRow`'s `ListTile` inside
  `_SettingsSection`'s `Container`, both pre-existing widgets this pass did
  not touch. The new `_ConflictAttentionRow` uses `Material`+`InkWell`
  directly, not `ListTile`, so it cannot be and is not the source. The
  suppression was **not broadened** — same two matchers as before.

### Confirmation

No file outside the list above was modified. In particular
`lib/features/detachment/presentation/detachment_member_status_page.dart`,
`test/core/theme/palette_contrast_test.dart`, and every other untracked
file this session found already modified were left exactly as found.

### Task 5

Already complete (see §ZZZZZZ). Untouched by this session.

---

## ZZZZZZZ. Latest session — 2026-09-05 (Needs Review Inbox + Durable Conflict Review Foundation — Task 4)

**Task 4 only.** No other roadmap item started, no backend, no
`MTM-PRO` change. The pre-existing working tree was preserved — nothing
reset, reverted or deleted.

`flutter analyze`: clean, whole project. `flutter test`: **376 pass / 0
fail** (345 after Task 5 + 31 new: 21 in `needs_review_inbox_test.dart`, 10
in `needs_review_page_test.dart`; one location added to the existing
`app_router_test.dart` list). `dart format` applied. `git diff --check`
clean. `graphify update .` run.

Full contract: `FRONTEND-BACKEND-INTEGRATION.md` **§7** (new), plus the
now-closed follow-ons in §4 and the now-built half of §5.4.

### What this session builds

The user-facing review loop for conflicts that were already being
*classified* (Task 2) and *specified* (Task 3) but had nowhere to go:

1. Settings shows the quiet count — unchanged — and that row is now the way
   in;
2. `/needs-review` lists every conflicted operation;
3. tapping one opens the Task 1 differences-first screen, rebuilt from
   metadata stored at detection time;
4. `useLocal` / `useCurrent` / `reviewLater` apply through the existing
   `conflictDecisionHandlerProvider`;
5. `reviewLater` leaves the operation and its metadata exactly as they were,
   so the row is still on the list on the way back.

Auto Sync's contract is unchanged except for one added step — it now stores
safe review metadata after preserving the operation, and still never
navigates.

### Files added

```
lib/core/sync/conflict_review_recorder.dart                  (core hook, no-op default)
lib/features/conflict/domain/conflict_review_entry.dart      (durable safe metadata)
lib/features/conflict/domain/conflict_review_store.dart      (persistence seam)
lib/features/conflict/domain/needs_review_item.dart          (the joined row + record labels)
lib/features/conflict/data/in_memory_conflict_review_store.dart  (MOCK)
lib/features/conflict/data/conflict_review_controller.dart   (controller + needsReviewItemsProvider)
lib/features/conflict/data/conflict_review_recording.dart    (composer seam + app override)
lib/features/conflict/presentation/needs_review_page.dart    (the inbox)
test/features/conflict/needs_review_inbox_test.dart
test/features/conflict/needs_review_page_test.dart
```

### Files changed

- `lib/core/sync/sync_coordinator.dart` — calls the recorder after a
  conflict is durably classified; best-effort, cannot abort the run.
- `lib/features/conflict/domain/conflict_models.dart` — `ConflictValueDirection`
  gains an explicit `wire`/`fromWire` (the `SyncState` idiom);
  `ConflictFieldComparison` gains `toJson`/`fromJson` and value equality.
  Additive only — no behaviour change to the Task 1 screen.
- `lib/features/conflict/data/conflict_outbox_resolver.dart` — a resolved
  conflict now forgets its stored entry too; doc comments corrected, since
  this handler is no longer unwired.
- `lib/features/settings/presentation/widgets/sync_settings_section.dart` —
  the attention row is now a control that opens `/needs-review`, with one
  composed screen-reader announcement and the activation action on the same
  node.
- `lib/core/router/app_router.dart` — `/needs-review` as a root route,
  beside the conflict screen it opens.
- `lib/main.dart` — installs `conflictReviewOverrides` at the composition
  root.
- `lib/l10n/strings.dart` — the Needs Review vocabulary (Arabic).
- `test/core/router/app_router_test.dart` — `/needs-review` added to the
  reachable-locations list.

### Deliberate limits (read before "finishing" this)

> **Superseded — see §ZZZZZZZZ (the corrective pass on top of this
> session).** The first two bullets below described real gaps, not accepted
> limits: `useLocal` reusing the original identity contradicted §5.5, and
> the composer registry was not just empty by policy but was never actually
> registered anywhere, including in the shipped app. Both are fixed by the
> corrective pass. Left in place, unedited, as the historical record of what
> this session actually shipped.

- **The composer registry is empty, so the inbox is empty in production.**
  A composer needs the current record from a real `409`; inventing one to
  make the screen look populated would be fabricating a backend conflict.
  The seam is built, tested and documented — that is the deliverable.
- **`requeueAfterConflict` still reuses the original identity.** §5.5's
  create-then-retire protocol belongs with the work that adds a real
  `SyncTransport`; changing it now would be a wire-protocol change with no
  wire.
- **`InMemoryConflictReviewStore` is object-lifetime only**, like every
  other store in this app. A second container over the same instance models
  a relaunch and is tested; an OS process restart still loses it.

### Two notes on the working tree

- `dart format lib test` was run repo-wide and normalized three files this
  task did not otherwise touch:
  `lib/features/detachment/presentation/detachment_member_status_page.dart`
  and `test/core/theme/palette_contrast_test.dart` (both untracked
  work-in-progress) and `lib/core/theme/theme_controller.dart`. Whitespace
  only — `dart format` changes no semantics, and the suite and analyzer are
  green — but it is an unrelated diff, recorded here rather than left to be
  discovered.
- `needs_review_page_test.dart` renders Settings, which surfaces a
  **pre-existing** debug assertion (`ListTile` inside the decorated
  `_SettingsSection` — "background color or ink splashes may be invisible").
  It fires on `main` for every existing Settings row and was not introduced,
  or fixed, here; the test filters it narrowly, exactly as
  `tenant_flow_smoke_test.dart` already filters the known `GlassBottomNav`
  overflow.

### Task 5

Already complete (see §ZZZZZZ). Untouched by this session.

---

## ZZZZZZ. Latest session — 2026-09-04 (Attendance Edit Window + Append-Only Corrections — Task 5)

**Task 5 only**, implemented before Task 4 per explicit instruction. Task 4
(shift swap/cover requests) was **not started** — not read, not planned, not
touched.

`flutter analyze`: clean, whole project. `flutter test`: **345 pass / 0
fail** (full suite, up from 305 after Task 3 — 19 new in
`attendance_policy_test.dart`, 18 new in `attendance_correction_test.dart`, 3
new in `attendance_correction_sheet_test.dart`; every pre-existing shift/
capability/PDF/report test still passes unmodified in behaviour). `dart
format` applied to every touched file. `git diff --check` clean. `graphify
update .` run.

### What this session builds

A regular/sub-Admin (`Cap.shiftAttendanceRecord`) may record or edit a
shift's attendance for one hour after the shift ends. After that, ordinary
editing is read-only for that session. A Main Admin
(`Cap.shiftAttendanceOverride`) keeps working indefinitely, but only through
an **append-only correction** — the original attendance history is never
silently overwritten, every correction requires a reason, and the UI shows
who corrected what and why. Full contract:
`FRONTEND-BACKEND-INTEGRATION.md` §6.

### The one-hour boundary — decision and evidence

**Not a new decision.** Four independent, already-existing sources agree on
the exact same rule — shift end time (already correct for an overnight
shift, via `Shift.end`) plus exactly one hour:

1. `medical_team/lib/features/detachments/data/attendance_lock.dart`
   (`attendanceGracePeriod = Duration(hours: 1)`) — the legacy program's own
   executable rule, with its own boundary test suite this task's
   `attendance_policy_test.dart` mirrors (open at `end + 0:59:59`, closed at
   exactly `end + 1:00:00`, plus overnight and corrupt-data cases).
2. `LEGACY-EXTRACTION-REPORT.md` (D-16).
3. `CAPABILITIES.md` / `core/access/capability.dart` — `shift.attendance.record`
   already documented as "inside the one-hour window"; `shift.attendance.override`
   already documented as "after the one-hour lock" — both written before
   this session, for exactly this purpose.
4. `CAPABILITIES-REPORT.md` — cites "your legacy owner decision of
   2026-07-10" as the reason the two capabilities were split apart at all.

One deliberate, flagged divergence: MTM-PRO (a separate, unrelated project,
read-only reference) designed a *three*-layer scheme for its own unbuilt
backend (1h self-grace → 7-day gated window → permanent override). This
task's product-owner decisions specify only **two** layers, and are not open
for interpretation — the 7-day middle layer is intentionally **not** built
here. See `FRONTEND-BACKEND-INTEGRATION.md` §6 for the full citation trail.

Implemented as one pure function pair,
`lib/features/shift/domain/attendance_policy.dart`:
`AttendanceWindow.of(shift, now:)` (the boundary) and
`resolveAttendanceEditMode(window:, canRecord:, canOverride:)` (what the two
capabilities may do with it — `ordinary` / `correctionOnly` / `readOnly`).
No `DateTime.now()` inside either — `now` is always an argument, which is
what makes the whole boundary deterministically testable and cheap to change
later if the rule is ever revised.

### Capability behavior

Reused the existing `Cap.shiftAttendanceRecord`/`Cap.shiftAttendanceOverride`
keys and the existing presets — **no new capability, no `UserRole`, no
`role == mainAdmin` branch anywhere.** Both keys drive the ordinary path
while the window is open (a Main Admin uses the same controls a sub-Admin
does, not a separate admin path); only `shiftAttendanceOverride` continues
once the window closes, and then only through the correction method. Client
checks remain UX-only, exactly as this app's existing security contract
already states (`core/access/capability.dart`) — restated, not changed.

### Append-only model decision

New, minimal, owned entirely by the shift feature —
`lib/features/shift/domain/attendance_correction.dart`:
`AttendanceCorrection` (id, shiftId, memberId, before/after snapshots,
reason, author, correctedAt), `AttendanceSnapshot` (status +
checkIn/checkOut), `AttendanceCorrectionAuthor` (internal `id`, safe-for-UI
`displayName`), and `normalizeCorrectionReason` (trims, collapses
whitespace, rejects blank outright rather than accepting a placeholder).
`Shift` gained one field, `corrections: List<AttendanceCorrection>` (oldest
first) and a `correctionsFor(memberId)` helper — **not** on `TeamMember`,
because `TeamMember` already doubles as a workshop's organising-team
projection (`team_models.dart`'s own doc comment) and has no business
carrying shift audit data. The correction history is scoped to the
assignment (the shift), matching the existing precedent that attendance
state itself already lives there, not on the roster record.

### Files changed

New: `lib/features/shift/domain/attendance_policy.dart`,
`lib/features/shift/domain/attendance_correction.dart`,
`test/features/shift/attendance_policy_test.dart`,
`test/features/shift/attendance_correction_test.dart`,
`test/features/shift/attendance_correction_sheet_test.dart`.

Edited: `lib/features/shift/domain/shift_models.dart` (`Shift.corrections`),
`lib/features/shift/domain/shift_repository.dart`
(`addAttendanceCorrection` added to the interface),
`lib/features/shift/data/mock_shift_repository.dart` (window enforcement +
correction implementation + injectable `clock`),
`lib/features/shift/presentation/shift_assign_sheet.dart` (the attendance
sheet's three modes, correction form, and history section),
`lib/features/shift/presentation/shift_manage_sheet.dart` (threaded
`canOverride` so an override-only session can still open the sheet once the
window has closed), `lib/features/detachment/presentation/tabs/detachment_shifts_tab.dart`
(same threading, one layer up), `lib/l10n/strings.dart` (new Arabic strings),
`API_CONTRACT.md`, `FRONTEND-BACKEND-INTEGRATION.md` (new §6),
`DATA-NEEDS.md` (one glossary line).

Test-only, required by the new window enforcement (not a behaviour change):
`test/features/shift/schedule_test.dart` and
`test/features/shift/attendance_statistics_test.dart` now construct
`MockShiftRepository` with an injected clock frozen at the start of "this
week" — without it, a test picking an early-in-the-week seeded shift could
spuriously hit the new window check depending on what real day the suite
happens to run on. `test/features/shift/shift_manage_sheet_test.dart` gained
the same `canOverride` parameter its `showShiftManageSheet` call site now
requires, plus one latency-drain pump already used elsewhere in that file
(`member_assignment_sheet_test.dart`'s established pattern) for the test that
opens the attendance sheet.

### Repository behavior

`MockShiftRepository` gained an injectable `clock` (`DateTime Function()?`,
defaulting to `DateTime.now` — same pattern as `PendingOperation.create`/
`UuidV7`). The four ordinary mutation methods
(`recordCheckIn`/`recordCheckOut`/`markAbsent`/`resetAttendance`, and
`markAttendance` which dispatches to them) now share one choke point
(`_updateAttendance`) that checks `AttendanceWindow.of(shift, now: _clock())`
before doing anything else, returning `Failure(S.attendanceWindowExpired,
code: attendanceWindowExpiredCode)` — a typed, non-textual code, per the
task's requirement — without touching any state when denied.
`addAttendanceCorrection` is a new, separate method: validates the reason,
validates checkout-after-checkin (reusing the exact same overnight
normalization `recordCheckOut` already used, not a second copy of that
logic), appends one `AttendanceCorrection`, and only then updates the
member's effective attendance — both happen together, after every
validation has passed, so a failed call leaves both the effective state and
the correction history untouched (asserted directly in
`attendance_correction_test.dart`). It never checks the window itself,
matching "permit indefinite override only through the explicit override
method."

### UI behavior

`showAttendanceSheet`/`_AttendanceBody`
(`lib/features/shift/presentation/shift_assign_sheet.dart`) now renders one
of three modes:

- **`ordinary`** (window open): unchanged from before this task — the
  existing check-in/check-out pickers and status buttons — plus a
  `LockWindow` chip (`LockWindowState.open`, was already built and
  unwired anywhere except a static `home_page.dart` demo) showing the
  countdown.
- **`correctionOnly`** (window closed, override held): `LockWindow`
  (`sealed` — its pre-existing caption is literally "أضف تصحيحا") replaces
  the ordinary controls with a `إضافة تصحيح` action; the form reuses the
  same status buttons and date/time pickers as the ordinary path, plus a
  required reason field, and calls `addAttendanceCorrection`.
- **`readOnly`** (window closed, no override): `LockWindow` (`restricted` —
  "تعديل بصلاحية") plus `S.attendanceWindowClosedOrdinary` explaining why
  nothing here is editable. No dead controls, no hidden mutation path.

A compact `سجل التصحيحات` section (shown whenever a correction already
exists, or whenever the mode is not `ordinary`) lists every correction
newest-first: corrector name, timestamp, reason, and before/after attendance
— never the corrector's raw id.

### Local-first behavior

Not integrated with the outbox — a deliberate, documented deferral, not an
oversight. Grepping the whole `lib/features/` tree for `OutboxController`/
`PendingOperation.create` finds **zero** call sites anywhere in the app
today; no feature, shift attendance included, currently enqueues through it.
Per the task's own fallback instruction, the repository method
(`addAttendanceCorrection`) is already the clean seam a future outbox
integration would call — nothing about this session's UI or domain code
would need to change for that wiring to land later. Full reasoning:
`FRONTEND-BACKEND-INTEGRATION.md` §6.

### Privacy / security handling

`AttendanceCorrectionAuthor.id` is captured for internal traceability and
never rendered — only `.displayName` reaches a widget, asserted directly in
`attendance_correction_sheet_test.dart` (`findsNothing` for the raw id and
for the author's email). Client capability checks remain UX-only; the
backend must independently enforce both the capability and the time window
using server time — restated explicitly in `FRONTEND-BACKEND-INTEGRATION.md`
§6 because a correction/audit feature is exactly the surface where skipping
that would be a real gap, not a cosmetic one.

### What remains mock / provisional

Everything in this session is frontend/mock-only, per explicit scope. The
wire failure code for a denied ordinary edit
(`attendance_window_expired`) is the mock's own placeholder string, flagged
as `Backend contract decision required` in `FRONTEND-BACKEND-INTEGRATION.md`
§6 rather than assumed. The outbox/local-first integration is deferred, not
built (see above). No server enforces the window or the append-only rule —
both are honestly enforced by the mock for development/testing purposes
only, never a security boundary.

### Task 4

**Not started.** Not read, not planned. This session stops here per
instruction.

> Later correction (§ZZZZZZZ, 2026-09-05): "Task 4" as delivered is the
> **Needs Review inbox + durable conflict review foundation**, not the shift
> swap/cover requests this section guessed at from the roadmap ordering. The
> swap/cover work remains unstarted and unplanned.

**Task 3 only** (Optimistic Concurrency Backend Contract), resumed on top of
the Task 1 conflict screen and Task 2 outbox/conflict-state integration.
Primarily a documentation/contract task, as directed — no backend, no `/sync`,
no database, no resolution networking, no Needs-Review inbox were built.

`flutter analyze`: clean, whole project. `flutter test`: **305 pass / 0
fail** (301 from Task 2 + 4 new in `sync_conflict_classifier_test.dart`).
`dart format` applied to every touched file. `git diff --check` clean.

### Why this session, and what it actually resolves

Task 2 left four broad `Backend contract decision required` markers across
`FRONTEND-BACKEND-INTEGRATION.md` §3/§4 — no agreed `version` shape, no
agreed stale-write wire code, no agreed stale-write response contents, and no
agreed resolution/idempotency protocol for `useLocal`. Nothing about the
frontend's own behaviour was ever wrong; what was missing was a coherent,
evidenced answer a backend developer could implement against instead of
guessing. This session supplies that answer as a new
`FRONTEND-BACKEND-INTEGRATION.md §5 — Optimistic Concurrency & Stale-Write
Resolution Contract`, and updates `API_CONTRACT.md` / the older §3/§4 text so
nothing still calls a now-decided question "open."

### MTM-PRO evidence review

Read (read-only; nothing in MTM-PRO was modified) via a research pass over
`/home/ahmed/Documents/Python-Files/flutter/apps/MTM-PRO/mtm_app/`:
`CLAUDE.md`/`AGENTS.md` family, the `close-out/` decision-ledger documents,
`MTM-Unified-Roadmap.md`'s concurrency/idempotency/audit/tenant-isolation
sections, and the security skill set relevant to mobile/API security, secure
local storage, authorization, and idempotency (auth-assessment,
crypto-review, secure-storage-audit, privacy-audit, secure-mobile-dev-guide,
owasp-mobile-security-checker, mobile-threat-model, and related). Used
strictly as **evidence for how a comparable backend already reasoned about
the same problem**, never as an instruction to implement, never copied as
code, and never allowed to override an MTM-Front-Back ruling where the two
would conflict (none did). Concrete evidence points that shaped a decision
(see `FRONTEND-BACKEND-INTEGRATION.md` §5 for the full citations):

- A server-issued, DB-enforced `version bigint DEFAULT 1` counter — `xmin`
  explicitly rejected (lost on dump/restore, wraps around) — confirms §5.1's
  `version` token design.
- The equivalent concept `STALE_WRITE` (their casing) for exactly this
  condition — confirms §5.2's `stale_write` naming, translated into this
  project's existing lowercase `snake_case` `ProblemCode.wire` convention.
- A conflict response that inlines `serverState` alongside the code —
  confirms §5.3's "embed the current record by default" decision.
- Mandatory `Idempotency-Key`, a `same key/different hash → 422 key misuse`
  rule distinct from a version conflict, and a ~7-day retention window —
  confirms §5.5's "a resolution write needs a new key, not a resend under the
  old one" reasoning, and matches the retention figure this repo's own
  roadmap already carried.
- Tenant id read only from the verified JWT, never client-supplied context;
  an append-only, hash-chained audit log — confirms §5.7's authorization/audit
  requirements.
- A per-data-type conflict policy distinguishing status-field edits
  (version-checked), append-only ledger rows (structurally conflict-free),
  and shift double-booking (a DB exclusion constraint, unrelated to version)
  — confirms §5.1's inventory-movement exclusion and §5.9's shift-overlap
  scope boundary.

### The nine required decisions

All resolved except where explicitly and narrowly left open (see
`FRONTEND-BACKEND-INTEGRATION.md` §5 for full reasoning on every point below
— this is the short form):

1. **Concurrency token** — `version`: server-managed, wire JSON integer,
   frontend-opaque `String` (matches the existing `ConflictPresentation.
   baseVersion`/`currentVersion` type — no model change needed), starts at
   `1`, sent back as a body field (not a header), same mechanism for
   delete/archive. Append-only writes (`inventory.movement.add`) and
   server-computed fields are explicitly excluded — they cannot have a stale
   write by construction.
2. **Stable stale-write code** — `stale_write`, a new `ProblemCode` value,
   distinct from the pre-existing `conflict`. **Implemented**, not just
   documented — see "Code changes" below. The *in-progress* and
   *same-key-different-body* codes remain deliberately unresolved — see §5.2
   for why (they are a different failure shape and resolving them would need
   a `SyncState` surface change beyond this task's remit).
3. **Stale-write response contents** — a justified combination: always a
   `currentVersion`, `currentRecord` embedded by default using the entity's
   own ordinary read shape (reusing `presentShiftConflict`'s existing
   "two full typed records" design, no new diff-projection shape), reference
   -only fallback with an explicit note about the race that trades away.
4. **Conflict persistence boundary** — no new store: `conflictId :=
   operationId`, `PendingOperation` stays the durable record. One new,
   feature-owned, typed, encrypted "current-as-of-detection" snapshot is
   required (not implemented) so `reviewLater` works offline later; strict
   rules for what must never be persisted or displayed, and for removal
   timing (superseded on a newer `409`, deleted the moment the conflict
   resolves).
5. **Resolution protocol and idempotency** — `useLocal` becomes a **new**
   `PendingOperation` (new `operationId`/`idempotencyKey`, since its body
   genuinely differs) carrying a `resolvesOperationId` reference back to the
   original; create-then-retire ordering so a failed mint never loses the
   original conflicted operation. `useCurrent` sends nothing — there is
   nothing to submit. Today's `OutboxController.requeueAfterConflict` same
   -key reuse is documented as correct **only** because `OfflineSyncTransport`
   never actually sends anything — fixing it is explicit future work, not
   done here (`Explicitly forbidden` — no resolution networking).
6. **Meaning of the three intents** — restated precisely against §5's new
   ground truth; unchanged in substance from Task 1/2, no generic merge
   added.
7. **Authorization and privacy** — reauth is the ordinary token-expiry path,
   nothing special; tenant scope re-derived server-side at resolution time,
   never trusted from a cached snapshot; `ConflictUnavailablePage` is the
   correct fallback for access revoked since the conflict was created;
   auditability and safe-logging rules restated and tied to the new
   `resolvesOperationId` reference.
8. **Auto Sync / Manual Sync** — confirmed unchanged: already correctly
   implemented and proven by `auto_sync_no_navigation_test.dart`; nothing to
   redecide.
9. **Shift product context** — documented: shift conflicts are expected to be
   uncommon (one owner per shift) but the mechanism stays required for
   another device / Main Admin / stale offline copy / overlapping sessions;
   explicitly scoped away from `SHIFT_OVERLAP` (a different mechanism,
   MTM-PRO evidence: a DB exclusion constraint) and from inventory movements
   (structurally conflict-free).

### Code changes (small, aligning typed seams to decision #2)

- `lib/core/problem/problem.dart` — new `ProblemCode.staleWrite`
  (`'stale_write'`), documented against the pre-existing `conflict`.
- `lib/l10n/strings.dart` — `S.errStaleWriteTitle` / `S.errStaleWrite`
  (Arabic), styled like the existing `errConflict*` pair but distinct copy
  (points at reviewing differences, not "reload and retry").
- `lib/core/problem/problem_presentation.dart` — `resolveProblem()` gained
  `case ProblemCode.staleWrite:`, a required change once the enum grew (the
  switch is exhaustive) — generic modal fallback, `retryable: false` (unlike
  `conflict`'s `true`: resubmitting the same write against the same stale
  version is guaranteed, not just likely, to fail again).
- `lib/core/sync/sync_conflict_classifier.dart` — `defaultSyncConflictClassifier`
  now returns `ProblemCode.parse(problemCode) == ProblemCode.staleWrite`
  instead of always `false`. Compares through `ProblemCode.parse`, not a raw
  string, to keep one code vocabulary. Still inert in the shipped app: no
  real `SyncTransport` exists to ever produce this code.
- `lib/core/sync/sync_state.dart`, `outbox_controller.dart`,
  `sync_transport.dart` — doc-comment accuracy fixes only (they previously
  said "no production wire code classifies a push"; that is no longer true
  of the *code*, only of the *transport* — reworded precisely).
- `test/core/sync/sync_conflict_classifier_test.dart` — new, 4 focused tests:
  recognises `stale_write`; does not recognise `null`, the unrelated generic
  `conflict` code, or other/future/undecided codes.

No other production code changed. `ConflictPresentation`,
`ConflictResolutionDecision`, `OutboxController.requeueAfterConflict` /
`.discardConflict`, `presentShiftConflict`, and the conflict screen/route are
all **unchanged** — Task 3 documents what they will need once a transport
exists, but does not touch their behaviour, per the explicit "prefer no code
changes" / "do not implement resolution requests" instructions for this task.

### Verification

- `flutter analyze` — clean, whole project, before and after.
- `flutter test test/core/sync/ test/core/problem/ test/features/conflict/
  test/features/settings/manual_sync_settings_test.dart` — all pass,
  including every existing Task 2 conflict/outbox/idempotency test
  unmodified (the new classifier behaviour does not change any existing
  test's expected outcome: every existing test either overrides the
  classifier with its own private test code, or uses a code that is not
  `stale_write` and correctly stays `failed`).
- `flutter test` (full suite) — **305 passed, 0 failed**.
- `dart format` — applied to every touched `.dart` file.
- `git diff --check` — clean (see verification note at the end of this
  section for the exact command run).
- Manual cross-reference pass over `FRONTEND-BACKEND-INTEGRATION.md` §3/§4/§5,
  `API_CONTRACT.md`, and this entry: symbol names and file paths checked
  against the actual code, no remaining `Backend contract decision required`
  marker left pointing at something §5 actually decided.

### Documentation

- `FRONTEND-BACKEND-INTEGRATION.md` — new §5 (the bulk of this session's
  output); §3's "Conflict state model", the sync-result table, the "Mock /
  provisional" bullet, and its "Backend contract decision required" list all
  updated to point at §5 and to stop calling the stale-write code
  undecided; §4's "Frontend status", the `baseVersion`/`currentVersion`
  mock note, and its "Open decisions" list updated the same way; the index
  table gained a §5 row and corrected open-decision counts.
- `API_CONTRACT.md` — the "Errors" section gained a short `stale_write`
  paragraph (same treatment `upgrade_required` already gets: not part of the
  agreed `v1` contract yet, but the client already recognises it and the
  full contract lives in `FRONTEND-BACKEND-INTEGRATION.md`); the idempotency
  paragraph now also points at §5.
- This file — this section, plus the `§ZZZZZ` pointer at the top.

### Deferred / explicitly not built (unchanged from the task's own scope)

No backend API, no server-side optimistic concurrency, no database
constraint, no server `409` generation, no backend merge logic, no real
`/sync`, no cursors, no tombstones, no backend persistence, no server audit
infrastructure, no Needs-Review inbox, no generic merge engine, no resolution
networking. `OutboxController.requeueAfterConflict` was deliberately left
exactly as Task 2 wrote it — see §5.5's explanation of why that is correct
today and wrong the moment a real transport exists.

### Genuinely unresolved external facts

None required a business/legal/organizational answer this session could not
safely infer from repository evidence. The two items left open (the
*in-progress* and *same-key-different-body* wire codes, §5.2) are not
"unavailable facts" — they are a deliberate scope boundary: resolving them
would mean adding a third `SyncState` bucket for a client-protocol fault
distinct from both `failed` and `conflict`, which is a surface change beyond
"align a typed constant," and Task 3's required-decision list named only the
stale-write code. A future session should treat that as its own small,
explicit decision rather than something Task 3 silently expanded into.

---

## ZZZZ. Latest session — 2026-09-04 (Conflict/Outbox integration — Task 2)

**Task 2 only** (Outbox Conflict State + Sync Integration Seam), resumed on
top of the Task 1 conflict screen. Task 3 was **not** started (not asked for).

`flutter analyze`: clean, whole project. `flutter test`: **301 pass / 0
fail**, full suite (282 from Task 1 + 19 new/updated this session). `dart
format` applied to every touched file. `git diff --check` clean. Frontend
only — no backend, no real `/sync`, no server-side conflict generation.

### State-model decision

Added exactly **one** new `SyncState` value: `conflict`
(`lib/core/sync/sync_state.dart`). Rejected the alternatives the prompt
offered:

- **Adding both `conflict` and `needsReview` to the enum.** The roadmap's own
  original comment defined them as two different things — `conflict` is a
  *per-operation* stale-write verdict, `needsReview` was reserved for a
  *durable, cross-conflict inbox*. Task 2 does not build an inbox (explicitly
  out of scope), so a `needsReview` **state** would have no distinct meaning
  from `conflict` yet and would just be a second name for the same thing.
  `needsReview` survives instead as a `bool` convenience getter
  (`SyncState.needsReview` / `PendingOperation.needsReview`, `true` only for
  `conflict`) and as the aggregate `SyncRunOutcome.needsReview` — the run-level
  signal Settings/Manual Sync render — so the word is used precisely rather
  than doubled.
- **A separate "review disposition" structure.** Not needed: `reviewLater`
  from the Task 1 screen already has an exact meaning under this model — do
  nothing, the operation stays `conflict`. No extra field or type was
  required to represent that.

`SyncState` gained two predicates, both delegated onto `PendingOperation`:

- `isRetryable` — `true` for `pending`/`syncing`/`failed`, `false` for
  `conflict`. This is what `SyncCoordinator._run` now filters the queue on
  (previously `isUnsynced`), so a conflicted operation is never picked up by
  the ordinary retry loop.
- `needsReview` — `true` only for `conflict`.
- `isUnsynced` (existing) is unchanged in meaning (`!= synced`) and still
  includes `conflict` — it answers "still outstanding", not "should be
  retried".

### Classification seam (no wire code invented)

New file `lib/core/sync/sync_conflict_classifier.dart`: a
`SyncConflictClassifier = bool Function(String? problemCode)` seam
`SyncCoordinator` calls on every `Failure` before deciding `failed` vs
`conflict`. `defaultSyncConflictClassifier` — the one wired in the shipped
app — always returns `false`. `FRONTEND-BACKEND-INTEGRATION.md` §3 already
marked the *in-progress* / *invalid-reuse* wire codes as `Backend contract
decision required`; this session did not resolve that decision, so nothing
in the shipped app can transition an operation into `SyncState.conflict`
today. Tests override `syncConflictClassifierProvider` with a private test
code (`test_only_stale_write`) that will never collide with a real backend
value, and exercise the full transition honestly without asserting what the
real code will be.

### Preservation of operation / idempotency identity

`OutboxController.applyOutcome` already generically supported any non-synced
state, so classifying a `Failure` into `conflict` reuses that exact path —
same `operationId`, same `idempotencyKey`, no new record, no new store write
path. Verified directly: `conflict_outbox_test.dart` tests 1+2 assert the
stored `operationId`/`idempotencyKey`/`kind`/`entityId` are byte-identical
before and after the transition, and `conflict_outbox_resolver_test.dart`
asserts the same across a `useLocal` requeue.

### Auto Sync behaviour

Unchanged in shape, changed in effect: `SyncScheduler.request()` still only
calls `SyncCoordinator.syncNow(trigger: auto)` — it has no reference to
`GoRouter`, `context`, or any navigator, so it was structurally incapable of
navigating before this session and still is. What Task 2 adds is that a
`Failure` the classifier recognises now lands the operation in `conflict`
(a quiet state change) instead of endless `failed` retries, with **no**
route push, dialog, or navigation of any kind. New widget test
`test/core/sync/auto_sync_no_navigation_test.dart` proves this against a
real `GoRouter` instance: it seeds a conflict-classified failure, calls the
same `SyncScheduler.request()` `main.dart` calls on launch/resume, and
asserts the router is still on `/home` (not `/conflicts/...`) while
independently confirming the operation really did become `conflict` (so the
test is not vacuous).

### Manual Sync behaviour

`SyncCoordinator._run`'s per-op `failure` branch now asks the classifier
before deciding `failed` vs `conflict`; a classified conflict sets a new
`hitConflict` flag instead of `hitFailure`. `SyncRunOutcome` gained
`needsReview`, surfaced by `SyncSettingsSection._syncNow`'s existing outcome
switch as `S.syncNeedsReviewNote` ("توجد تغييرات تحتاج مراجعة قبل إكمال
المزامنة.") — distinct from the generic `S.syncFailedNote`, so a stale-write
conflict is never shown as a scary generic failure. Manual Sync still drains
the exact same `outboxProvider` through the exact same `SyncCoordinator` —
nothing new was introduced on that path.

### Settings changes

`SyncSettingsSection` (`lib/features/settings/presentation/widgets/`) gained:

- `conflictOperationsCountProvider` (new, `outbox_controller.dart`) watched
  alongside the existing `pendingOperationsCountProvider`. The latter now
  filters on `isRetryable` instead of `isUnsynced`, so a conflicted operation
  is no longer double-counted into "بانتظار المزامنة" — it has its own line.
- A quiet `_ConflictAttentionRow` (key `sync-conflict-attention`), shown only
  when the conflict count is `> 0`: "تغيير واحد يحتاج مراجعة" /
  "%d تغييرات تحتاج مراجعة" on a `c.warnTint` background — the same
  warning treatment Task 1's conflict screen uses for its intro icon.

**Deliberately not built:** a tap action on that row. Building a real
`ConflictPresentation` needs the feature's own typed local/current records
(exactly what `presentShiftConflict` does for a `Shift`) — a generic,
payload-free `PendingOperation` does not carry them, and there is no
Needs-Review inbox or live per-feature trigger to route a tap into yet.
Wiring a button to nothing honest would violate prompt §5/§9 ("do not
fabricate backend conflicts as production behaviour"). Settings otherwise
stays fully usable: the sync-now button and every navigation row keep
working while conflicts are outstanding (`manual_sync_settings_test.dart`,
"Settings stays usable while conflicts exist").

### Problem integration seam

Not touched beyond what `sync_conflict_classifier.dart` documents. §2's
`ProblemCode.conflict` (`'conflict'`, `HTTP 409`) is a **different** concept
— "someone else changed this record" for an ordinary request/response call —
from the sync-retry stale-write case this task's classifier is for (a
`409`/`422` on an *idempotent retry* whose exact wire code
`FRONTEND-BACKEND-INTEGRATION.md` §3 still marks undecided). The classifier
seam exists precisely so the two are never accidentally conflated by reusing
one wire string for both.

### Retry behaviour

`SyncCoordinator._run`'s `pending` list now filters on
`PendingOperation.isRetryable`, so a `conflict` operation is skipped by
every subsequent Auto or Manual run — proven by
`conflict_outbox_test.dart`'s "a conflicted operation is not retried
indefinitely" (three runs, transport pushed once). A generic (unclassified)
`Failure` is completely unaffected: same `failed` state, same retry-forever
behaviour as before Task 2 (test "generic temporary failures keep their
pre-Task-2 behaviour").

### Conflict resolution intent seam

New `lib/features/conflict/data/conflict_outbox_resolver.dart`:
`applyConflictResolution(ref, decision)` and the
`conflictDecisionHandlerProvider` it backs. Turns a Task 1
`ConflictResolutionDecision` into outbox calls only — no network, no claim of
server success:

- `useLocal` → `OutboxController.requeueAfterConflict` (conflict → pending,
  same identity, no push attempted here).
- `useCurrent` → `OutboxController.discardConflict` (removes the pending
  write; never contacts the transport).
- `reviewLater` → no call at all — leaving the operation alone **is** the
  preservation behaviour.

Not wired to a live call site: exactly as Task 1 left it, nothing in `lib/`
opens `ConflictResolutionPage` yet, so `conflictDecisionHandlerProvider` has
no real `onDecision` to be passed to today. It exists, is fully tested
(`conflict_outbox_resolver_test.dart`), and is ready for whatever future
conflict-detecting integration opens the route.

### Tests added/updated this session

- `test/core/sync/conflict_outbox_test.dart` (new, 10 tests) — prompt §10
  items 1, 2, 3, 6, 8, 9 plus the useLocal/useCurrent/reviewLater seam and
  the `needsReview` run outcome.
- `test/core/sync/auto_sync_no_navigation_test.dart` (new) — item 4.
- `test/features/conflict/conflict_outbox_resolver_test.dart` (new) — the
  decision → outbox bridge, all three intents.
- `test/features/settings/manual_sync_settings_test.dart` (+3 tests) — items
  6, 7, and the honest `needsReview` snackbar note.
- `test/core/sync/pending_operation_test.dart` — updated the Task-1-era
  "`'conflict'` is unknown" assertion, since it is now a real, recognised
  value (item 10); added `isRetryable`/`needsReview` coverage; `'needsReview'`
  remains the genuinely-unknown probe.
- Full existing suite (local-first sync, manual sync widget tests, Task 1
  conflict screen/router tests) re-run unmodified where not listed above —
  items 5, 11, 12 all pass with no changes needed.

### Deferred / mock work (unchanged or newly explicit)

- No production wire code classifies anything as a conflict — the shipped
  classifier always returns `false` (§3 "Backend contract decision required"
  still open).
- No Needs-Review inbox; no tap-to-review action in Settings (see "Settings
  changes" above).
- `useLocal`/`useCurrent` never talk to a server and never claim a server
  outcome — `useLocal` only re-queues for the *next* ordinary sync attempt;
  `useCurrent` only stops asking the server for that write.
- `ConflictResolutionDecision.currentVersion` is still carried by the Task 1
  model but nothing in this task's outbox seam reads or attaches it to a
  retried request — that is real transport work, out of scope here and
  dependent on the still-open `baseVersion`/`currentVersion` shape decision
  (§4 open decisions).
- No adapter beyond the existing `presentShiftConflict` was added or needed
  — Task 2 never builds a `ConflictPresentation`.

### Documentation

- `FRONTEND-BACKEND-INTEGRATION.md` — §3 updated (state model, classifier
  seam, retry-loop change, count providers, backend-decision note
  unchanged/still open) and §4 updated ("Frontend status", the outbox
  resolver as the new integration point, "Open decisions" #3/#4 narrowed to
  what is now actually true). Index table refreshed.
- This file — this section, plus the `§ZZZZ` pointer at the top.

---

## ZZZ. Latest session — 2026-09-04 (Conflict UX Task 1 — review, fixes, docs)

**Task 1 only** (Conflict UX Design + Frontend Screen Foundation), resumed
from a prior interrupted session whose documentation patch had not applied.
The implementation already existed in the working tree; this session
independently reviewed it against the original requirements, fixed what it
found, and wrote the missing documentation. **Task 2 was not started.**

`flutter analyze`: clean, whole project. `flutter test`: **282 pass / 0 fail**,
full suite (includes one new regression test added this session). `dart
format` applied to every Task 1 file (no changes needed — already formatted).
`git diff --check` clean. Frontend only.

### What existed already (verified correct, unchanged)

- `lib/features/shift/presentation/shift_conflict_adapter.dart`,
  `lib/core/router/app_router.dart`'s `/conflicts/:conflictId` route,
  `lib/l10n/strings.dart`'s conflict-resolution string block, and
  `test/core/router/app_router_test.dart`'s `/conflicts/c1` location. Reviewed
  line-by-line; no correctness, RTL, routing, or privacy defect found — left
  as-is.
- The differences-first design (Option B), the three typed intents
  (`useLocal`/`useCurrent`/`reviewLater`, deliberately no `merge`), the
  `PopScope`/`_allowPop`/deferred-pop fix for the "repeated reviewLater on a
  root route" bug, and the opaque-identity privacy model
  (`ConflictPresentation` never carries a raw backend field or JSON) — all
  verified against the code and the existing test suite (11 widget tests + 3
  router tests, all passing at session start).

### Fixes made this session

1. **Accessibility — double semantics announcement.** `_VersionLabel` and
   `_ConflictValue` in `conflict_resolution_page.dart` each wrapped their
   visible `Text` children in a `Semantics(container: true, label: …)` with no
   `ExcludeSemantics`. Every other composed-label widget in the app
   (`_ChoicePill` in `settings_page.dart`) wraps its child in `ExcludeSemantics`
   specifically so a screen reader announces the composed label once instead
   of the label followed by the same text again from the descendant nodes —
   this pair did not follow that pattern. Fixed by wrapping both in
   `ExcludeSemantics`, matching the established convention. New regression
   test: `version legend and value cells announce their composed label once`
   (asserts the composed label is reachable by `bySemanticsLabel` and the bare
   title/subtitle/value strings are not).
2. **Lint cleanup** (`flutter analyze` was not clean on these files before this
   session): `conflict_models.dart` — `assert(differences.length > 0)` →
   `assert(differences.isNotEmpty)` (`prefer_is_empty`).
   `conflict_resolution_page.dart` — hoisted `const` onto the `_VersionLabel`
   declarations and their enclosing `Column`/`Row` in `_VersionLegend`
   (`prefer_const_declarations` / `prefer_const_constructors`).

### Reviewed and found already correct (no change made)

- **State preservation on exit.** Confirmed every exit path (button tap,
  system back, AppBar back, failed callback) resolves through `onDecision`
  before the screen closes, or keeps the screen open on failure — unresolved
  local work is never silently discarded. See
  `FRONTEND-BACKEND-INTEGRATION.md` §4 "How unresolved conflicts are
  preserved" for the full trace.
- **Privacy.** No raw JSON, backend field name, or hidden identifier reaches
  the generic screen; `entityType`/`entityId`/`baseVersion`/`currentVersion`
  are carried but never rendered. Existing test already plants
  backend-looking strings in every non-display field and asserts none render.
- **Routing.** The route sits on the root navigator beside the forced-upgrade
  gate, inherits the router's one `redirect` with no special-casing, and
  falls back to `ConflictUnavailablePage` on a stale/missing `extra` rather
  than crashing or fabricating a conflict.
- **Scope discipline.** Confirmed by search: nothing anywhere in `lib/`
  outside the conflict feature and the router calls
  `presentShiftConflict`/`ConflictResolutionRouteArgs`/
  `ConflictResolutionPage.locationFor` — Auto Sync, Manual Sync, and every
  other feature are untouched, so "Auto Sync must never navigate here" holds
  by construction today. No outbox `conflict` state, Needs-Review inbox, or
  other-domain adapter was added, per the task's explicit exclusions.

### Documentation

- `FRONTEND-BACKEND-INTEGRATION.md` — new **§4 Conflict Resolution UX**
  (design options considered and rejected, product model, integration point,
  preservation guarantee, privacy/accessibility notes, mock/provisional
  pieces, open backend decisions). Index table updated.
- This file — this section, plus the `§ZZZ` pointer at the top.

### Deferred / not built (explicitly out of scope for Task 1)

Conflict *detection*, any outbox `conflict`/`needsReview` state, a
Needs-Review inbox, real sync, and adapters for domains other than shift. See
`FRONTEND-BACKEND-INTEGRATION.md` §4 "Removal / follow-on during integration"
and "Open decisions."

---

## ZZ. Latest session — 2026-09-04 (local-first write foundation + forced-upgrade cleanup)

Two tasks from one prompt, **both complete**. `flutter analyze` clean (whole
project); `flutter test` **270 pass / 0 fail** (was 242 at session start).
`dart format` applied to touched files; `git diff --check` clean. **Frontend
only — no backend code, no full sync engine.**

### ZZ.1 Local-first write / idempotency-ready sync foundation

- **Architecture chosen: C** — one shared lightweight local write-operation
  primitive in `lib/core/sync/`. Rejected A (network layer mints a key per
  request — there is no network layer, and a per-attempt key cannot survive a
  restart) and B (each feature owns write identity — fragments the one pending
  set Auto + Manual Sync must share, fights the "shared primitives are Core"
  grain). C matches the repo's own seam idiom (`abstract *Store` + in-memory
  mock + overridable `Provider`, exactly like `AppVersionGateStore`). No
  equivalent primitive existed (searched mutation/command/outbox/change-log/
  dirty-state/sync-metadata). Full rationale + integration points:
  `FRONTEND-BACKEND-INTEGRATION.md` §3 (new).
- **New — `lib/core/sync/`:**
  - `sync_state.dart` — `SyncState { pending, syncing, synced, failed }`.
    `conflict` / `needsReview` documented as deferred; `SyncState.fromWire`
    keeps an unknown state as `pending`, never "done".
  - `uuid_v7.dart` — RFC 9562 UUIDv7 (`Random.secure()`, `dart:math`, **no new
    dependency**; monotonic per-ms counter; injectable `Random`/clock for
    tests), `uuidV7()`, `isUuidV7()`.
  - `pending_operation.dart` — `PendingOperation`: `operationId` +
    `idempotencyKey` (one UUIDv7, minted once, never regenerated), `kind`
    (namespaced tag), opaque `entityType`/`entityId`, `createdAt`, `state`,
    attempt bookkeeping (`attemptCount`, `lastAttemptAt`, `lastProblemCode` —
    **wire code only**). **No payload field** — payloads stay with the
    feature's own storage / future SQLCipher tables.
  - `outbox_store.dart` — `OutboxStore` (seam) + `InMemoryOutboxStore` (mock,
    lifetime-of-object; real impl → SQLCipher `pending_operations`).
  - `outbox_controller.dart` — `OutboxController`/`outboxProvider`
    (`AsyncNotifier`, hydrates from the store), `enqueue(...)` is **the single
    identity-creation point**; `outboxStoreProvider`, `newOperationIdProvider`
    (test seam), `pendingOperationsCountProvider`.
  - `sync_transport.dart` — `SyncTransport` (seam; where a real impl attaches
    `Idempotency-Key`) + `OfflineSyncTransport` (every push → `Offline`, so no
    fabricated success is possible today).
  - `sync_coordinator.dart` — `SyncCoordinator`/`syncCoordinatorProvider`
    (`Notifier<SyncStatus>`), `syncNow({trigger})` is **the one engine both
    paths call**; re-entrancy guard (`_inFlight` future) so a flapping signal
    or a manual tap during an auto run cannot fan a write out twice; never
    creates a `PendingOperation`. `SyncTrigger { auto, manual }` — audit only,
    behaviour identical. `syncTransportProvider`.
  - `sync_scheduler.dart` — `SyncScheduler`/`syncSchedulerProvider`, the Auto
    Sync trigger seam. `main.dart` calls `onAppStart()` (post-first-frame) and
    `onAppResumed()` (on `AppLifecycleState.resumed`). No connectivity trigger
    (no connectivity plugin in deps — documented as the next hook).
- **Settings surface:** new `SyncSettingsSection`
  (`features/settings/presentation/widgets/sync_settings_section.dart`), placed
  in `settings_page.dart` under a new `S.sectionSync`. Shows plain-language
  state + pending count (`٣ تغييرات بانتظار المزامنة`) + last-sync line + a
  `مزامنة الآن` button. Button disabled while syncing; the rest of Settings
  navigation stays live. Honest feedback only — with the offline transport the
  snackbar says "لا يوجد اتصال…", never a fake "اكتملت المزامنة". No ids /
  keys / wire codes anywhere in the UI.
- **Representative integration:** `detachment_storage_tab.dart`
  `_ItemSheetBodyState._record()` — after the local `addMovement` succeeds it
  `enqueue`s a `PendingOperation` (`kind: 'inventory.movement.add'`,
  `entityType: 'inventory_item'`, `entityId`), `unawaited`-nudges
  `SyncScheduler.request()`, pops the sheet and shows `S.savedPendingSync`
  ("تم الحفظ · بانتظار المزامنة"). Nothing waits on a server. Every other
  write in the app is unchanged — the same one-line adoption is available to
  them.
- **Strings:** `strings.dart` new "Sync (local-first writes)" block.
- **7-day rule:** NOT implemented on the frontend. No timer. Recorded in
  `FRONTEND-BACKEND-INTEGRATION.md` §3 as backend-owned retention; the local
  outbox keeps an op until it is `synced`.
- **Security (scoped):** `PendingOperation` has no payload / header / token
  field; only a wire `code` is retained on failure, never server `detail`;
  no id / key is shown in the UI (test asserts a `Bearer …` / `SQLSTATE …`
  failure message never reaches the stored record).
- **Tests (+27):** `test/core/sync/{uuid_v7,pending_operation,local_first_sync}
  _test.dart`, `test/features/settings/manual_sync_settings_test.dart`,
  `test/features/inventory/local_first_movement_test.dart`. Cover: local write
  with no server, identity stable across auto+manual+restart retries, one
  engine / one queue, no duplication, offline ≠ data loss, unknown backend
  code passes through as code-only, re-entrancy = one run, RTL Settings,
  no-fake-success, sync button busy ≠ nav locked.

### ZZ.2 Forced Upgrade cleanup (did **not** redesign the feature)

- **Build/version identity.** The persisted gate was keyed on
  `AppInfo.version` (display SemVer `1.0.0` only). Added
  `AppInfo.buildIdentity = '1.0.0+1'` — the full `pubspec.yaml` `version:`
  string (`versionName+versionCode`) — and keyed
  `PersistedUpgradeGate.blockedVersion` on it
  (`AppVersionController._restorePersistedGate` / `_persistVerdict`). So a
  hotfix that keeps the SemVer but bumps the build number is a different
  binary and does not inherit the old build's `426`. `AppInfo.version`
  (SemVer) still drives the screen text and `X-Client-Version`. Both held to
  `pubspec.yaml` by the drift test. New test: "same version, different build
  number ⇒ not inherited".
- **Legacy `updateUrl`.** **Removed.** `AppVersionSupport.updateUrl` and
  `AppVersionState.updateUrl` deleted; `UpdateDestination.open()` /
  `resolvedDestination()` lost their `overrideUrl` param;
  `AppVersionController.openUpdateDestination()` passes nothing.
  Evidence for removing rather than keeping: the field sat on the
  *backend-response* model, implying the backend owns the update destination —
  which directly contradicts the already-resolved "destination is
  client-owned" decision, so every reference had to carry a "but not really"
  caveat. Its only justification was hypothetical edge cases (sideloaded
  enterprise build, moved listing) with no product driver — `com.mtm.mtm` is a
  fixed Play listing, there is no iOS target, no enterprise channel. And a
  wire-controlled launch target that `open()` would hand to a launcher is a
  redirect risk. `AppVersionSupport.fromJson` now simply ignores an incoming
  `updateUrl` (unknown-member-dropped, like `Problem.fromJson`), so a future
  server that sends one does not break the client. Test replaced: "an
  `updateUrl` on the wire is ignored — destination stays client-owned".
- Docs: `FRONTEND-BACKEND-INTEGRATION.md` §1 (Required-backend-data table +
  Open-decisions/Resolved rewritten — down to 2 open items), `API_CONTRACT.md`
  (idempotency note).

### ZZ.3 Unresolved — `Backend contract decision required`

`FRONTEND-BACKEND-INTEGRATION.md` §3: wire `code` strings for *in-progress* /
*invalid-reuse*; final `Idempotency-Key` header name; server retention window
+ whether the client is told a key expired; `/sync` upload single-vs-batch and
per-op result shape. §1: what identity the *server* compares (SemVer? +platform
+build? hash?) and whether `X-Client-Version` should carry more; `426` body
shape / `minimumVersion` placement; endpoint-vs-any-request for the check.

---

## Z. Latest session — 2026-09-04 (forced-upgrade finalization + Problem/error foundation)

Two requests, **both complete**. `flutter analyze` clean (whole project);
`flutter test` **242 pass / 0 fail** (was 198 at session start). `dart format`
applied to the touched files. Frontend only — **no backend code added**.

### Z.1 Forced Upgrade — finalization (feature was untracked/new, not redesigned)

- **Update action is no longer "copy a URL".** The update destination is
  **client-owned**: new `UpdateChannel`
  (`features/app_version/domain/update_channel.dart`) holds per-platform
  store/update links (`androidStore` real for `com.mtm.mtm`; `iosStore` empty —
  no iOS target; `webFallback` placeholder). `UpdateDestination.open()` no
  longer takes the backend URL — it resolves `UpdateChannel.forPlatform` and
  takes `AppVersionSupport.updateUrl` only as an *optional override*. The
  launcher-less dev build still copies to the clipboard (`UpdateLaunchOutcome`
  unchanged); production returns `opened`. Rationale: the destination is a fact
  about how the client shipped, identical for every user, needed with no
  network — so a `426` body never has to carry it, and a hostile `updateUrl`
  can't redirect off-store. Closes former open decision 2 in
  `FRONTEND-BACKEND-INTEGRATION.md` §1.
- **The gate now survives an offline restart.** New tiny seam
  `AppVersionGateStore` + `PersistedUpgradeGate`
  (`features/app_version/domain/app_version_gate_store.dart`), mock
  `MockAppVersionGateStore` in-memory (same limitation as
  `MockSettingsRepository`), `appVersionGateStoreProvider`.
  `AppVersionController.check()` now: (1) before the network call, when not
  already blocking, restores a persisted verdict **keyed to
  `AppInfo.version`** — a build previously told `426` re-enters the gate even
  with no network; (2) after a check that *reaches a verdict*, persists it
  (`supported` → clear). A stored verdict whose version string ≠ the running
  build is stale → ignored and cleared, so a fix shipped as a new version is
  not blocked by the old one. An unreadable store **fails open** (offline-first
  rule preserved). Deliberately NOT on `SettingsRepository` — that is
  user-chosen settings; a forced-upgrade verdict is a cached server answer.
  Real impl writes it to the same ordinary local-prefs bucket (`DATA-NEEDS.md`
  §3.3).
- Tests: `test/features/app_version/forced_upgrade_test.dart` — 15 original
  kept unchanged + 13 new (persisted-gate cases 1/2, verdict persist/clear,
  stale-version drop, failed-recheck-no-overwrite, relaunch-over-same-store,
  unreadable-store-fails-open; client-owned destination + override + platform +
  controller-with-no-backend-url).

### Z.2 RFC 9457-ready Problem / error UX foundation

- **Architecture: C — hybrid.** Evidence: `Result` / `AsyncResultView` /
  `ErrorStateView` are already shared Core primitives; `mock_shift_repository`
  already owns its own domain codes → its own `S.*` copy at its own call site;
  Forced Upgrade is already a Core-owned global blocking state; Riverpod has no
  global interceptor (errors travel per-provider as `Result`). A central
  resolver (A) would become the god object the feature folders avoid; a purely
  feature-owned model (B) would duplicate the shared widgets. Core owns the
  bounded set of app-wide conditions (a plain `switch`, not a registry);
  features own domain codes at their own `Result`/`Problem` sites and fall back
  safely for anything Core doesn't enumerate.
- **New:** `lib/core/problem/` — `problem.dart` (`Problem` RFC 9457-shaped +
  typed extensions `fieldErrors`/`reference`, no untyped map; `ProblemCode`
  enum with `wire` strings matching `API_CONTRACT.md`; `Problem.fromJson`
  parses RFC 9457 *and* tolerates the interim `{error:{…}}` envelope, drops
  unnamed members), `problem_presentation.dart` (`ProblemView`,
  `ProblemSurface` = field/inline/transient/modal/fullScreen, `resolveProblem`),
  `problem_result.dart` (`Result.problemOrNull` bridge — `Result` unchanged).
- **Representative integration:** `AsyncResultView` failure branch (~25
  screens) now renders MTM-owned localized copy for known codes, the generic
  fallback (`تعذر إكمال العملية`) for an unrecognised code, and **never** the
  raw wire `message`. Debug builds `debugPrint` an unhandled code + detail;
  release is silent. Feature mutation surfaces (form sheets, snackbars) are
  untouched — they adopt `problemOrNull` incrementally.
- **Not built** (foundation only, per prompt §15): session-terminated
  auto-routing, shift-overlap sheet, stale-write merge, cursor-expired,
  needs-review, FEFO UI, subscription suspension. `authentication_expired` is
  *classified* (full-screen, `S.sessionExpired*`) but nothing auto-navigates
  yet — extension point is `resolveProblem` + the existing `/session-expired`
  route.
- **Strings:** `strings.dart` new "Problem / error taxonomy" block.
- **Security (scoped to the error flow):** `Problem` has no field for headers /
  tokens / PII; `fromJson` reads only whitelisted keys and drops the rest;
  `detail`/`title`/`type`/`instance` are never shown for a known code (test:
  a fake `SQLSTATE … token=Bearer …` detail never reaches `ProblemView.message`
  for any code); unknown code → generic copy, not the server string; `reference`
  shown only on modal/full-screen, never on a field error.
- Tests: `test/core/problem/{problem_test,problem_presentation_test,async_result_problem_test}.dart`
  (31).
- Docs: `FRONTEND-BACKEND-INTEGRATION.md` §2 (new, full handoff),
  `API_CONTRACT.md` "Errors" (RFC 9457-ready note + open items).

### Z.3 Unresolved — `Backend contract decision required`

`FRONTEND-BACKEND-INTEGRATION.md` §1: `426` body shape / `minimumVersion`
placement; what answers the check (endpoint vs any-request); version-comparison
identity (semver vs +build). §2: whether the envelope becomes literal RFC 9457
members; field-error key shape; the safe support-reference field name.

---

## A. Latest session — 2026-09-03 (detachment status + more themes)

Two requests, **both complete**. Latest verification after the theme follow-up:
`flutter analyze lib test` clean; `flutter test` **183 pass / 0 fail**;
`git diff --check` clean.

### A.1 Detachment "status" + storage status, and a per-member status page

- **Status strip in the detachment detail shell** — new `_StatusStrip` in
  `features/detachment/presentation/detachment_detail_shell.dart`, shown under
  the app bar on all four tabs. Two `StatusChip`s:
  - lifecycle: نشطة / مؤرشفة (this is the "status" the legacy `medical_team`
    details header carried — brought across).
  - storage: a **derived worst-wins rollup** of the detachment's stock —
    `features/detachment/domain/storage_status.dart`, `StorageStatus`
    { empty, healthy, expiring, low, depleted } via `storageStatusOf(items)`.
    Precedence depleted > low > expiring > healthy. Not a stored field, no
    wire enum. Memory: `mtm-storage-status-rollup`.
- **Member status page** — new
  `features/detachment/presentation/detachment_member_status_page.dart`,
  route `/detachment/:id/member/:memberId/status`. Tapping a roster card in
  the Team tab now opens this (was: straight to the edit form); editing is an
  app-bar icon gated on `Cap.memberEdit`. Shows the member's current
  attendance state, week/month/quarter range chips, present/absent/completed/
  percent totals, and **one card per shift day** (weekday+date, center,
  status chip, `الدخول HH:MM · الخروج HH:MM` forced LTR, or "بلا تسجيل دخول").
  Data: existing `attendanceStatisticsProvider` filtered to one member — no
  new provider, numbers match the stats tab.
- `detachment_team_tab.dart` `_openMember` → `/status`.
- `strings.dart` — new keys: `detachmentStatusStrip`, `storageStatus*` (5),
  `memberStatusTitle`, `memberStatusCurrent`, `memberAttendanceLog(+Sub)`,
  `noAttendanceRecords(+Sub)`, `notCheckedInShort`.
- `test/core/router/app_router_test.dart` — added the `/status` location.

### A.2 More themes + eye-protect mode

- **Palettes: 3 → 6.** `PaletteId` is now
  `{ medical, slate, copper, clay, indigo, teal }` in
  `core/theme/app_palette.dart`, each with a full light + dark `AppColors`
  const. **`medical` is the new default** (clean clinical green on white) —
  `ThemeState.initial()` selects it in light mode. `indigo` (cool blue) and
  `teal` are the two new alternates; `slate`/`copper`/`clay` are unchanged.
  `AppColors.resolve` is exhaustive; no code uses `PaletteId.index`.
- **Eye-protect mode** — `AppColors.warmed()`: a warm, low-blue lerp toward
  amber applied to the **ground only**: backgrounds, surfaces, lines and
  status tints. Ink, primary and semantic foreground colours stay unchanged,
  preserving legibility and meaning. It is **orthogonal** to palette and to
  light/dark — `ThemeState.eyeProtect` (bool, default false),
  `ThemeController.setEyeProtect`; `main.dart` passes `theme.eyeProtect` into
  both `AppTheme.light` and `AppTheme.dark`.
- **Settings UI** (`features/settings/presentation/settings_page.dart`) —
  palette row loops over all 6 and each pill previews the palette's primary
  colour at the brightness currently on screen. The mode row exposes light,
  dark **and System** (`S.settingsModeSystem`). The new "حماية العين"
  `_PickerRow` has مفعّلة / متوقفة pills. `_ChoicePill` is a selectable
  button semantics node with its tap action registered, so TalkBack can
  announce and activate it.
- `strings.dart` — `settingsPaletteMedical` / `Indigo` / `Teal`,
  `settingsEyeProtect(+Sub)`, `settingsEyeProtectOn` / `Off`.
- `test/features/detachment/tenant_flow_smoke_test.dart` — the "every palette
  resolves" test now also loops `eyeProtect ∈ {false, true}`, so it covers
  all 6 palettes × 2 modes × 2 washes and exercises `warmed()`.
- **Theme settings seam** — `ThemeState` moved to
  `core/theme/theme_state.dart`; `ThemeController` is now an `AsyncNotifier`
  that hydrates from `SettingsRepository.themePrefs()` and writes the whole
  palette/mode/eye-protect value through `updateThemePrefs()`. Widgets read
  `themeStateProvider`, which supplies `ThemeState.initial()` while hydration
  is pending. The mock repository read is latency-free to avoid a manufactured
  launch-theme flash.
- **Theme tests** — `test/core/theme/palette_contrast_test.dart` covers all
  palettes in both brightnesses, plain and warmed; it checks contrast floors,
  visible blue removal and immutable foreground tokens.
  `test/core/theme/theme_persistence_test.dart` covers repository hydration,
  write-through, JSON fallback/value semantics and a fresh provider container
  sharing the same repository instance.

**Boundary / optional follow-up:** the current `MockSettingsRepository` keeps
theme preferences in memory. It proves and exercises the repository contract,
but it is not durable storage across an operating-system process restart. A
real repository must write `ThemeState.toJson()` to local storage or the
backend before claiming device-relaunch persistence. This was not required by
the original palette/eye-protect prompt. There is also no dedicated widget
test for the settings picker layout; the theme build path and state behavior
are covered by the smoke, contrast and controller tests.

---

## 0. Earlier-session status snapshot
_(The results below and §1–§7 record the earlier 2026-09-03 session. Use
the 183-test verification in §A for the current baseline.)_

| Check | Result |
|---|---|
| `flutter analyze` | **clean**, whole project |
| `flutter test` | **168 pass, 0 fail** (was 136 at the start of this session) |
| `dart format` | applied to `lib/` and `test/` |
| `graphify update .` | ran — 3405 nodes, 4845 edges |

Four requested work items, all complete. Nothing is half-written.

---

## 1. Swipe navigation reversed

**Rule now:** swipe **LEFT** → the tab physically on the **RIGHT**; swipe
**RIGHT** → the tab physically on the **LEFT**. The tabs behave like a
filmstrip in visual order, which is the pager contract.

For the RTL detachment row `الفريق | الشفتات | المخزن | الإحصائيات`
(indices 0–3, index growing leftward):

| From | Swipe left | Swipe right |
|---|---|---|
| الشفتات (1) | الفريق (0) | المخزن (2) |
| المخزن (2) | الشفتات (1) | الإحصائيات (3) |

- `lib/core/widgets/swipe_tabs.dart` — `adjacentTabIndex()` now steps by
  `rightStep = rtl ? -1 : 1` and a leftward swipe takes `+rightStep`.
  Thresholds, `HitTestBehavior.translucent`, the inner-consumer yield and the
  `enabled` flag are untouched. Still no `PageView`; still `context.go`.
- `lib/core/motion/transitions.dart` — `TabSwitchTransition._enterSign` flips
  with it: `destinationIsRight ? +1 : -1`. The body still travels **with the
  finger** (swipe left → body moves left, incoming enters from the right), so
  gesture and animation now agree instead of contradicting.
- Applies everywhere `SwipeTabs` is used: detachment shell, workshop shell,
  and the bottom-nav shell (`main_shell.dart`), which was already sharing the
  rule.

Tests: `test/core/swipe_tabs_test.dart` (10), `test/core/tab_switch_transition_test.dart` (5).

---

## 2. Settings → "السمات والأداء" (Themes & Performance)

Now the **first** section on the settings screen, above Account and
Organisation, ordered: **theme (palette, light/dark) → graphics/animation
quality → frame rate.** The old `sectionApp` grouping is gone from the screen;
its string constant is kept (project "don't delete" rule).

### 2a. Quality levels are now meaningfully different

`MotionSpec` gained three dials and converted one, so the five levels differ by
*kind* of work rather than only duration:

| dial | performance | low | balanced | high | maximum |
|---|---|---|---|---|---|
| `durationScale` | **0** | 0.60 | 0.85 | 1.0 | 1.0 |
| `intensity` | 0 | 0.50 | 0.80 | 1.0 | 1.15 |
| `blurSigma` | 0 | 0 | 10 | 18 | 24 |
| `ambientLoops` | ✗ | ✗ | ✓ | ✓ | ✓ |
| `staggerMaxItems` *(was `stagger` bool)* | 0 | 0 | 6 | 8 | 8 |
| `overshoot` | ✗ | ✗ | ✗ | ✓ | ✓ |
| `richShadows` | ✗ | ✗ | ✓ | ✓ | ✓ |
| `animatedValues` *(new)* | ✗ | ✗ | ✓ | ✓ | ✓ |
| `slideRoutes` *(new)* | ✗ | ✗ | ✓ | ✓ | ✓ |
| `crossFadeOutgoing` | ✗ | ✗ | ✗ | ✗ | ✓ |

- **`MotionSpec.performance` is now `MotionSpec.none`** — animations are off,
  not merely short, as the brief asked. `spec.isInstant` is true, so no
  controller/transform/opacity layer is built at all.
- `animatedValues` gates counter and progress-bar tweens via the new
  `effectiveValueDuration(context, d)` helper (`motion_tokens.dart`). Wired
  into `AnimatedCounter` and the three progress fills (home, detachment stats,
  shift coverage bar) and the new workshop donut.
- `slideRoutes` replaces the magic `spec.intensity >= 0.8` gate in
  `SharedAxisPageTransition`.
- `stagger` survives as a getter (`staggerMaxItems > 0`), so no call site
  changed; `Stagger` now reads the level's depth, capped by
  `MotionTokens.staggerMaxItems` (the sub-300ms budget).
- **OS accessibility still outranks everything** — `motionSpec()` returns
  `MotionSpec.none` on `MediaQuery.disableAnimations` regardless of level.
  Unchanged, and asserted in `mtm_verify_test.dart`.

### 2b. Frame rate — real display APIs, no fake throttling

New, self-contained: `lib/core/display/`.

- `frame_rate.dart` — `FrameRatePreference {auto, fps30, fps60, fps90, fps120}`,
  `DisplayCapabilities`, and three **pure** functions:
  `availableFrameRates()`, `resolveFrameRate()`, `isFrameRateExact()`.
- `display_refresh.dart` — `DisplayRefresh`, a `MethodChannel('mtm/display')`
  client with a per-process capability cache and a `PlatformDispatcher.displays`
  fallback for reading the active rate.
- `android/.../MainActivity.kt` — answers `capabilities` and `setFrameRate`
  using `Display.getSupportedModes()` and
  `WindowManager.LayoutParams.preferredDisplayModeId` / `preferredRefreshRate`
  (API 21/23 — compiles on any compileSdk the app uses).

Honesty rules, all enforced in code and tests:

- **Nothing drops or throttles frames.** The app asks the *display* for a mode;
  the compositor schedules as it always did.
- A rate is only offered when the panel has a display mode for it (or the
  platform accepts a frame-rate hint, which Android reports as `false` at this
  SDK floor). A 60 Hz phone is offered **Auto + 60**, not 90/120.
- A platform with no channel (desktop, web, tests) reports `canChoose == false`
  and gets **Auto only**, with an explanatory line instead of dead pills.
- When the nearest mode is not the exact request, the row says so
  (`S.settingsFrameRateNearest`) rather than implying the number was honoured.
- The row prints the display's current rate when known.

Persistence follows the existing pattern: `SettingsRepository.frameRate()` /
`updateFrameRate()`, `MockSettingsRepository` in-memory, `FrameRateController`
(`AsyncNotifier`) in `features/settings/data/frame_rate_provider.dart`. It is
`ref.watch`-ed in `main.dart` purely so its `build()` re-applies the stored
preference on launch (the platform forgets it between runs).

Tests: `test/core/frame_rate_test.dart` (14), incl. `MethodChannel` mocking and
the missing-plugin path.

---

## 3. Detachments → Shifts

### 3a. Copy previous **day** (was: previous week)

- `ShiftRepository.copyDay({detachmentId, fromDay, toDay})` — new.
  `copyWeek` is **kept** (still a valid repository capability, still tested);
  both now share `MockShiftRepository._cloneOnto`, so the dedupe rule
  (skip a day+time that already has a shift) and the "assignments do not
  travel" rule live in one place.
- UI: `_BulkActions` button → `S.copyPreviousDay`, copying
  `selectedDay - 1 day` onto the selected day. The previous day may sit in the
  previous week; the copy is date-based, so that works.
- `_BulkActions` no longer takes `weekStart` (nothing used it).

### 3b. Templates: custom date selection, kept and improved

Templates were **not** removed. The date-set model from the previous handoff
(D1/D2: `ShiftTemplate.dates: List<DateTime>`) stands. What is new:

- `ShiftRepository.updateTemplateDates(templateId, dates)` — edits a template's
  day set **directly**, without going through one of its shifts.
- `MockShiftRepository._reconcileTemplateShifts(...)` — extracted from
  `updateRepeat`, now shared by both paths. The three safety rules are stated
  once: materialise a missing day from the given spec (unless the day+time is
  already occupied — dedupe), delete a surplus day **only if its shift is
  empty**, and fold a staffed day back into the set rather than deleting it.
  Collapsing to ≤1 day deactivates the template and leaves its shifts alone.
- `lib/features/shift/presentation/repeat_days_picker.dart` — **new**. The
  21-day grid was extracted out of `shift_edit_sheet.dart` as the public
  `RepeatDaysPicker` (`firstDay`, `windowDays`, `selected`, `locked`, `title`,
  `help`), so the shift editor and the template editor drive the same widget.
- `lib/features/shift/presentation/template_edit_sheet.dart` — **new**.
  `showTemplateEditor(...)`; reached from the ✎ button on each row of the
  templates sheet. Window starts at `min(today, template.firstDate)` and runs
  at least 21 days (long enough for a 10–15 day detachment, and always long
  enough to show every day the template already occupies). Staffed days are
  locked in the grid with a snackbar explaining why.

### 3c. Weekly summary removed, day selector promoted

- `_WeekHeader` + `_Stat` + `_DayStrip` → one `_DaySelector`, now the **first**
  thing under the tab bar. It carries the week navigation (‹ / week range /
  ›, with the range doubling as a "jump to this week" tap target when off the
  current week) directly above the seven day chips.
- Gone: weekly coverage %, shift count, gap count. `WeekSummary` the *model*
  is untouched — the exported report still uses it.
- Each day chip keeps its own dot (green/amber) — that is what tells you which
  day to pick, and is not weekly-summary information.

### 3d. Shift cards simplified

- `_ShiftCard` no longer lists attendees. It shows centre + repeat glyph, the
  time range, the status chip (now / gap / covered), the coverage bar with
  assigned-of-needed, and **the shift manager's name** — or a warning line when
  no supervisor is assigned.
- New derived getter `Shift.manager` → the first attendee whose role is
  `TeamRole.shiftSupervisor`, else `null`.
- The whole card is still one tap target into `showShiftManageSheet`, which is
  **unchanged**: both assignment routes, quick-fill, the full attendee list,
  attendance, check-in/out, edit and delete all still live there.

Flow: **choose day → shift cards → open shift → full shift management.**

Tests: `test/features/shift/copy_day_and_template_dates_test.dart` (13).

---

## 4. Workshop → Statistics, copied from the `medical team` project

Source (read-only, **not modified**):
`/home/ahmed/Documents/Python-Files/flutter/apps/medical_team/lib/features/workshops/`
— `presentation/workshop_stats_screen.dart`,
`data/workshop_stats_providers.dart`,
`presentation/widgets/workshop_export_buttons.dart`.

The source's information architecture is preserved: **dashboard → detail →
file export**, two groups counted separately, a donut per group, a two-tile
financial summary, a copy-paid-names card, a one-tap full export and a
section-picking custom export. Everything underneath was rebuilt on MTM's
architecture.

### New files

| File | What |
|---|---|
| `features/workshop/domain/workshop_stats.dart` | `WorkshopStats`, `WorkshopGroupStats`, `WorkshopStatsPerson`, `WorkshopStatsGroup`, label extensions. `WorkshopStats.of(workshop, participants)` is the only calculation path. |
| `features/workshop/data/workshop_stats_providers.dart` | `workshopStatsProvider` — composes `workshopByIdProvider` + `workshopParticipantsProvider` into one `Result<WorkshopStats>`, preserving failure/offline honestly. |
| `features/workshop/data/workshop_stats_report.dart` | `WorkshopReportSection {summary, participants, team}` + `buildWorkshopStatsReport()` → a `ReportDocument`. `formatWorkshopAmount()`. |
| `features/workshop/presentation/widgets/workshop_stats_export.dart` | `WorkshopStatsExportCard`, `showWorkshopExportSheet`, `WorkshopCopyNamesCard`, `exportWorkshopReport`, `formatPaidNames`. |
| `features/workshop/presentation/tabs/workshop_stats_tab.dart` | Rewritten dashboard. |

### Adaptation decisions

- **Export reuses MTM's own report pipeline.** `buildWorkshopStatsReport`
  produces a `ReportDocument`, which `AttendancePdfBuilder` already renders as
  a paginated RTL PDF and `ReportDocument.toCsv()` already flattens for a
  spreadsheet. **No new packages were added.** The source used
  `archive` + `path_provider` + `share_plus` for a real `.xlsx`; MTM's
  documented delivery is `Printing.sharePdf` for PDF and CSV-to-clipboard for
  the spreadsheet (see `report_export_page.dart`), and this follows it exactly.
  *Consequence: the Excel option delivers CSV on the clipboard, not an .xlsx
  file. Swapping in a real file write is a delivery change, not a rebuild.*
- **`ReportDocument` gained one optional field**, `headerNote`, plus a
  `scopeLabel` getter. A workshop happens on a date, not across a window, so
  it must not print "last 7 days". Detachment reports are unaffected.
- **Two additive model fields** (the only data-model change):
  `Workshop.registrationFee` (default `0`) and
  `WorkshopParticipant.paymentStatus` (`PaymentStatus? {paid, unpaid}`,
  default `null` = not recorded). Both are read-only and seeded in
  `MockWorkshopRepository` — no payments-management UI was built, per the
  brief's exclusion. `w4` is seeded free so the "free workshop" path has data.
- **`null` payment is a real third state**, never folded into `unpaid`. The
  organising team carries no payment record (they run the workshop, they do
  not buy a seat), so they land in "غير محدد".
- **Attendance now counts `checkedOut` as present.** The old tile counted only
  `checkedIn`, which reported every *finished* workshop as 0 % attended. This
  supersedes the `// ASSUMPTION` comment that used to sit on that tab.
- Currency is `ل.س` (`S.currencyUnit`), not the source's `د.ع`.
- The source's app-bar "custom export" action became a button inside the
  export card, because the tab has no app bar of its own (the shell owns it).
- Section toggles use the same `PressScale` card style as the detachment
  report composer, not `CheckboxListTile` — the Material-ink assertion inside
  the sheet's `DecoratedBox` is a real failure mode, and the two export flows
  should not look like two different apps.

Tests: `test/features/workshop/workshop_stats_test.dart` (19), covering the
counts, the money, both export section paths, the CSV content, copy-names
formatting, and two widget tests of the rendered dashboard.

---

## 5. Files changed (this session only)

**Core**
- `core/widgets/swipe_tabs.dart` — reversed rule + docs
- `core/motion/transitions.dart` — `_enterSign` flip; `slideRoutes` gate
- `core/motion/motion_level.dart` — new dials, `performance = none`
- `core/motion/motion_tokens.dart` — `effectiveValueDuration()`
- `core/motion/animated_counter.dart`, `core/motion/stagger.dart`
- `core/display/frame_rate.dart`, `core/display/display_refresh.dart` — **new**
- `core/export/attendance_pdf.dart` — header reads `scopeLabel`

**Settings**
- `features/settings/presentation/settings_page.dart` — section reorder,
  `_FrameRatePicker`
- `features/settings/domain/settings_repository.dart`,
  `data/mock_settings_repository.dart`, `data/frame_rate_provider.dart` (new)
- `main.dart` — watches `frameRateProvider`

**Shifts / detachment**
- `features/shift/domain/shift_models.dart` — `Shift.manager`
- `features/shift/domain/shift_repository.dart` — `copyDay`, `updateTemplateDates`
- `features/shift/data/mock_shift_repository.dart` — `_reconcileTemplateShifts`,
  `_cloneOnto`, `copyDay`, `updateTemplateDates`
- `features/shift/presentation/repeat_days_picker.dart` — **new** (extracted)
- `features/shift/presentation/template_edit_sheet.dart` — **new**
- `features/shift/presentation/shift_edit_sheet.dart` — uses `RepeatDaysPicker`
- `features/detachment/presentation/tabs/detachment_shifts_tab.dart` —
  `_DaySelector`, copy-previous-day, template ✎, simplified card
- `features/detachment/domain/report_models.dart` — `headerNote`/`scopeLabel`

**Workshop** — see §4 table, plus `domain/workshop_models.dart` and
`data/mock_workshop_repository.dart`

**Platform** — `android/app/src/main/kotlin/com/mtm/mtm/MainActivity.kt`

**Strings** — `l10n/strings.dart`, ~70 new constants. Nothing deleted:
`copyLastWeek*`, `weekCoverage`, `weekShifts`, `weekGaps`, `settingsMotion*`,
`sectionApp`, `totalParticipants`, `presentCount`, `attendancePercent` are all
retained even where now unused, per the project rule.

**Tests** — new: `core/frame_rate_test.dart`,
`features/shift/copy_day_and_template_dates_test.dart`,
`features/workshop/workshop_stats_test.dart`. Updated:
`core/swipe_tabs_test.dart`, `core/tab_switch_transition_test.dart`,
`mtm_verify_test.dart`, `features/detachment/tenant_flow_smoke_test.dart`.

---

## 6. Known issues / open points

1. **Excel export is CSV-on-clipboard, not a `.xlsx` file.** Deliberate (§4).
   To make it a real file: add `archive` (already in the lock file as a
   transitive dep), `path_provider` and `share_plus`, port
   `medical_team/lib/core/export/xlsx_writer.dart`, and swap the `else` branch
   in `exportWorkshopReport`. Needs dependency approval per `CLAUDE.md`.
2. **Frame rate is Android-only in practice.** iOS/desktop/web report
   `canChoose == false` and get Auto only. iOS ProMotion would need
   `CADisableMinimumFrameDurationOnPhone` in `Info.plist` plus an engine-level
   hook that does not exist in Dart today.
3. **Frame-rate selection is untested on a real device.** The Kotlin compiles
   against API 21/23 APIs and the Dart side is unit-tested through a mocked
   channel, but nobody has watched a panel actually change mode. Worth a
   `/run` on hardware.
4. **Workshop payment data is read-only.** There is no UI or repository method
   to change `paymentStatus` — the brief excluded payments management. If that
   is wanted later, mirror `setParticipantAttendance`.
5. **`ReportDocument.range` is still required** and meaningless for a workshop
   report (it passes `ReportRange.week` and overrides the label via
   `headerNote`). Making it nullable is a small follow-up if it starts to grate.
6. **No widget test for the settings screen ordering** — the section order is
   asserted only by reading. The pieces underneath (`MotionSpec` ladder, frame
   rate resolution) are covered.
7. The `_RepeatDays` grid is still a flat `Wrap` of pills with no month
   affordance; fine at 21–25 days, would need grouping if the window grew.
8. `S.applyTemplatesEmpty` is still the templates-sheet empty state — reads
   fine, but the name is now a misnomer.

---

## 7. Exact next steps (nothing is required)

Optional, in the order I would take them:

1. `/run` the app and eyeball, on a device: the reversed swipe in RTL, the
   frame-rate picker against a real 120 Hz panel, the new shifts day selector,
   and the workshop statistics dashboard.
2. Decide on issue 1 (real `.xlsx`) — it is the one place the copied feature
   is deliberately thinner than its source.
3. If wanted, a widget test that asserts "السمات والأداء" renders above
   "الحساب" on the settings screen.
