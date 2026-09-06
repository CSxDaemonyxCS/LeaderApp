# DATA-NEEDS

A requirements log for the backend developer. **This is not an API design.**
There are no endpoints, no verbs, no payloads, no status codes here — only what
each screen shows, what the user can do on it, and when the screen needs fresh
data. How that is served is entirely the backend developer's decision.

Maintained by the frontend developer. Updated at the end of every page in the
per-page loop.

Legend for **State**: `built` = screen exists; `stub` = compiling placeholder
only (Batch 0 item D); `planned` = not yet created.

Entity and field names are the frontend's current domain vocabulary. Where the
new app invented a value set that the legacy program did not have, it is flagged
— see LEGACY-EXTRACTION-REPORT.md §5.

---

## 1. Entities in the domain today

| Entity | Fields the UI reads | Notes |
|---|---|---|
| **AuthUser** | id, name, email, role, orgName, avatarInitials | `role` is being replaced by a capability set (CAPABILITIES.md). |
| **Session** | id, device, ipMasked, locationLabel, startedAt, current | Shown on the security screen. IP is masked before it reaches the client. |
| **MfaSetupData** | otpauthUrl, manualSecret, backupCodes | Issued by the server. The client must never generate a TOTP secret. |
| **Detachment** | id, name, region, mainCenter, memberCount, weeklyShiftCount, coveragePercent, status, notes | `status` values pending your ruling. |
| **DetachmentStats** | attendanceSeries[7], coverageSeries[7], stockSeries[7] | Last 7 days, oldest first. |
| **TeamMember** | id, name, initials, role, detachmentId, attendance, phoneMasked | `detachmentId` is **scalar** — the model currently assumes one detachment per person. See open decision #2. |
| **Shift** | id, detachmentId, centerName, startHour, endHour, assigned, needed, hasCoverageGap, attendees[] | Current model is a single dated shift. The legacy model is a weekly template plus dated occurrences — richer, and the rules are already proven. Reconciling these is part of the scheduling redesign. |
| **InventoryItem** | id, detachmentId, name, unit, currentStock, minimum, expiresOn, level | New module, no legacy source. |
| **InventoryMovement** | id, itemId, direction, quantity, reason, at | |
| **Workshop** | id, name, at, location, capacity, registered, guests, status, organizingTeam[] | Legacy adds a **registration fee** and derives status from the date rather than storing it. |
| **WorkshopParticipant** | id, workshopId, name, initials, kind, attendance | Legacy also carries a section assignment and a tri-state payment status. |
| **HomeSummary** | detachmentName, centerName, activeShift, lockRemaining, attendancePresent, attendanceTotal, decisions[], workshopsThisWeek, attendanceRatePercent, stockLowCount | |
| **HomeDecisionItem** | id, kind, title, subtitle, actionLabel | kind: unfilled shift / expiring stock / join request. |
| **AppNotification** | id, kind, occurredAt, count, recordLabel, target, isRead | The Notifications Center. **Derived, not stored** — no backend emits these yet, so the client joins shift + inventory records and its own outbox. `id` must be stable per condition: read state is keyed by it. |
| **NotificationPrefs** | shiftReminders, stockAlerts, workshopUpdates, joinRequests | Personal, per-user. |
| **OrgInfo** | name, legalName, address, emailPublic, detachmentCount, memberCount | |

### Entities the legacy program has that this domain does not model yet

Raised for your decision, not assumed:

- **Workshop section** — an optional grouping of a workshop's people.
- **Workshop payment status** — paid / unpaid / unspecified, per person.
- **Workshop team member** — distinct from a participant, carries a role.
- **Shift occurrence** — a dated instance of a weekly shift, cancellable as a
  tombstone.
- **Shift roster vs per-date attendance** — two separate lists, deliberately.
- **Attendance correction** — an append-only record a session with
  `shift.attendance.override` adds once the one-hour ordinary edit window has
  closed. Never edits or removes an earlier entry or the original attendance
  row; the current (effective) attendance is a value derived by applying
  every correction in order, not a second copy the two could disagree on. See
  `FRONTEND-BACKEND-INTEGRATION.md` §6 (Task 5).
- **Patient** — a detachment's patient register. See open decision #8.
- **Member specialty and phone** — legacy member fields with no equivalent here.

---

## 2. Screens

### 2.1 Authentication (outside the main shell)

| Screen | State | Entities displayed | Fields used | Actions | Refresh trigger |
|---|---|---|---|---|---|
| Login `/login` | built | — | email or username, password | Sign in | None. Submits on demand. |
| MFA setup `/mfa-setup` | built | MfaSetupData | otpauthUrl (as QR), manualSecret, backupCodes | Copy secret, copy backup codes, confirm setup | Once on entry. Never re-fetched — a second fetch would issue a different secret. |
| MFA challenge `/mfa-challenge` | built | — | 6-digit code | Verify code | None. |
| Forgot password `/forgot` | built | — | email | Request reset | None. |
| OTP `/otp` | built | — | email, 6-digit code | Verify code, resend | None. Resend is user-initiated. |
| New password `/new-password` | built | — | new password | Set password | None. |
| Session expired `/session-expired` | built | — | — | Sign in again | Entered when the session is rejected. |
| New device `/new-device` | built | — | device description | Confirm "it was me" / "it wasn't me" | Entered on an unrecognised-device signal. |

**Capability note:** none of these are capability-gated. They are pre-session.

### 2.2 Home

| Screen | State | Entities displayed | Fields used | Actions | Refresh trigger |
|---|---|---|---|---|---|
| Home `/home` | built | HomeSummary, HomeDecisionItem, Shift | detachmentName, centerName, active shift with its remaining lock time, present/total attendance, decision list, workshops this week, attendance rate, low-stock count | Act on a decision item (navigates), pull to refresh | On first open; on pull-to-refresh; on app resume; **when the active detachment changes**; after any action taken from a decision item. |

**Open:** what Home shows when the user belongs to several detachments is
unresolved — see DETACHMENT-SCOPING.md §4 and open decision #6.

### 2.3 Detachment

| Screen | State | Entities displayed | Fields used | Actions | Refresh trigger |
|---|---|---|---|---|---|
| Detachment list `/detachment` | built | Detachment | name, region, mainCenter, memberCount, weeklyShiftCount, coveragePercent, status | Search by name/centre/region, filter by status, open a detachment, create | On first open; on pull-to-refresh; after creating, editing, or archiving a detachment. |
| New / edit detachment `/detachment/new`, `/detachment/:id/edit` | **stub** | Detachment | name, region, mainCenter, notes, status | Save, cancel | Loads the detachment once when editing. |
| Detail shell `/detachment/:id/...` | built | Detachment | name, status | Switch tab | Loads the detachment header once per detachment id. |
| Team tab `/detachment/:id/team` | built | TeamMember | name, initials, role, attendance, phoneMasked | Assign role, set attendance, open member | On tab open; on pull-to-refresh; after any role or attendance change. |
| Shifts tab `/detachment/:id/shifts` | **stub** | Shift | centre, start/end hour, assigned vs needed, coverage gap, attendees | Assign a volunteer, record attendance, create/edit a shift | On tab open; after any assignment or attendance change; **when the date or week in view changes**. |
| Storage tab `/detachment/:id/storage` | **stub** | InventoryItem | name, unit, currentStock, minimum, expiresOn, level | Record an inflow/outflow movement, open an item | On tab open; after any movement is recorded. |
| Stats tab `/detachment/:id/stats` | **stub** | DetachmentStats | attendance / coverage / stock series over 7 days | — (read only) | On tab open; on pull-to-refresh. |

**Every screen from the detail shell down is scoped by detachment id.** No
inventory or schedule screen is reachable without one. See DETACHMENT-SCOPING.md.

### 2.4 Workshop

| Screen | State | Entities displayed | Fields used | Actions | Refresh trigger |
|---|---|---|---|---|---|
| Workshop list `/workshop` | **stub** | Workshop | name, date, location, capacity, registered, guests, status | Search, filter by date bucket, sort, open, create | On first open; on pull-to-refresh; after create/edit/archive. |
| New / edit workshop `/workshop/new`, `/workshop/:id/edit` | **stub** | Workshop | name, date, location, capacity (legacy also: registration fee, active flag) | Save, cancel | Loads the workshop once when editing. |
| Detail shell `/workshop/:id/...` | **stub** | Workshop | name, date, status | Switch tab, archive | Loads the workshop header once per workshop id. |
| Team tab `/workshop/:id/team` | **stub** | TeamMember | name, initials, role, attendance | Set attendance, edit role | On tab open; after any change. |
| Members tab `/workshop/:id/members` | **stub** | WorkshopParticipant | name, initials, kind (member/guest), attendance (legacy also: section, payment status) | Set attendance, add, edit, remove | On tab open; after any change. |
| Stats tab `/workshop/:id/stats` | **stub** | Workshop, WorkshopParticipant | totals, present count, attendance % (legacy also: paid/unpaid/unspecified per group) | — (read only) | On tab open. |

### 2.5 More / settings

Reorganized into a navigation hub plus four nested category screens (Point 1
of the Settings IA pass). No new backend data: every nested screen reads and
writes the same `SettingsRepository` methods the hub used to call directly.

| Screen | State | Entities displayed | Fields used | Actions | Refresh trigger |
|---|---|---|---|---|---|
| Settings hub `/more` | **built** | app preferences, sync status (for row summaries only) | active palette/mode, active motion level/frame rate, pending/needs-review counts | Navigate to Themes, Performance, Sync, Profile, Security, Notifications, Organization; sign out | Row summaries follow the same providers the nested screens write to; no separate fetch. |
| Themes `/more/themes` | **built** | app preferences | palette, mode (light/dark/system), eye-protect | Change palette, mode, eye-protect | Preferences read once at start-up; changes are written immediately and take effect without restart. |
| Performance `/more/performance` | **built** | app preferences | motion/quality level, frame-rate preference | Change motion level, change frame rate | Preferences read once at start-up; changes are written immediately and take effect without restart. |
| Sync `/more/sync` | **built** | local outbox (pending/needs-review counts, last sync time) | pending count, needs-review count, last-synced time | Trigger a manual sync, open Needs Review | On open; after any sync run (manual or automatic). |
| Profile `/more/profile` | **built** | AuthUser | name, email, orgName, avatarInitials | Edit own profile | On open. |
| Security `/more/security` | **built** | Session | device, ipMasked, locationLabel, startedAt, current | Revoke a session, manage MFA | On open; after revoking a session. |
| Notifications `/more/notifications` | **built** | NotificationPrefs | shiftReminders, stockAlerts, workshopUpdates, joinRequests | Toggle each preference | On open. Each toggle persists immediately. |
| Notifications Center `/notifications` | **built** | AppNotification (derived from Shift + InventoryItem + the local outbox) | kind, occurredAt, count, recordLabel, target, isRead | Open the record behind a row (existing shift sheet / detachment tab / Needs Review / Sync); mark one read; mark all read | On open, and whenever the outbox or read state changes — the merge is client-side, so neither refetches the records. |
| Org info `/more/org` | **built** | OrgInfo | name, legalName, address, emailPublic, detachmentCount, memberCount | View (edit gated on `org.edit`) | On open. |

---

## 3. Cross-cutting data needs

### 3.1 Every read needs a typed outcome

Every repository call returns one of exactly three outcomes, and every screen
renders all three:

- **success** — with a flag for "this came from cache after a background refresh
  failed", so the screen can show a subtle stale indicator rather than lying;
- **failure** — with a human-readable message and an optional machine code;
- **offline** — optionally carrying the last cached value.

This is already the shape of `Result<T>` in `lib/core/result/result.dart`. The
backend developer does not need to produce this shape; the client maps whatever
arrives onto it. It is listed here so the **failure taxonomy** can be agreed:
the client needs to distinguish at least *not found*, *not permitted*, *conflict*
(someone else changed it first), *validation rejected*, and *authentication
expired*, because each renders differently.

### 3.2 Freshness expectations, in plain terms

- **Attendance and shift assignment** are the most time-sensitive data in the
  app. Two people commonly edit the same shift at the same time. The client
  needs to know when its copy is stale.
- **Inventory stock levels** change during a shift and drive the low-stock
  warnings on Home.
- **Detachment, workshop, and member records** change rarely. Cached values are
  fine for a working session.
- **Organisation info and notification preferences** change almost never.

### 3.3 What must never reach local device storage

Recorded here because it constrains what the client may cache, and the research
scope is mobile security (OWASP MASVS):

- Authentication tokens, refresh tokens, and the TOTP secret — secure storage
  only, never in ordinary preferences.
- Member phone numbers — currently only ever received masked, and that should
  stay true.
- Anything identifying the tenant/organisation, if the app becomes multi-tenant.

Non-sensitive UI preferences (theme, motion level, notification toggles, last
active detachment) are the only things written to ordinary local preferences.

---

## 4. Open items owed to the backend developer

1. Can one volunteer belong to **more than one detachment**? The client model
   currently says no (a scalar detachment id on the member). Open decision #2.
2. The **detachment and workshop status value sets** are not decided.
3. Whether **workshops belong to a detachment** or to the organisation. Legacy
   says organisation (via a centre). This determines whether workshop
   capabilities are scoped.
4. Whether the **patient register** is in scope. Open decision #8.
5. Whether **shifts have a draft/published distinction**. Legacy has none;
   `shift.publish` was named in the capability brief.
6. The **failure taxonomy** in §3.1.

---

*Last updated: Batch 0 analysis. No screens built yet beyond those marked
`built`, which pre-date this batch.*
