# CAPABILITIES

Status: **ruled and implemented.** 2026-09-02. The stop point in §7 is lifted.
`lib/core/access/` exists and `UserRole` has been removed.

The fixed role-enum approach is cancelled. `UserRole { superAdmin, mainAdmin,
simpleAdmin, volunteer }` in `lib/features/auth/domain/auth_models.dart` was the
last surviving piece of it and is gone as of this ruling.

---

## 0. Rulings — 2026-09-02

Ahmed's instruction: *"read them again and read my answers in ur memory and
continue"* — i.e. rule the open items from the arguments already written and
from the decisions already on record, rather than asking a fifth time.

So every ruling below is **taken by delegation**, and each one names the evidence
it rests on. Anything that could not be settled from the record is listed in §8
as still open — it is not guessed.

| Sheet item | Ruling | Rests on |
|---|---|---|
| **A** — the six §4 changes in the report | **All six taken.** 32 keys → 29. | The report argues each one; none was contested. |
| **B/Q1** — multi-detachment scoping | **The representation carries a map, so several detachments are possible.** The UI to grant more than one is deferred. | Costs nothing now and forecloses nothing; collapses to one id later if ruled so. |
| **B/Q2** — workshops org- or detachment-level | **Org-level.** All seven `workshop.*` keys are global, not scoped. | Legacy has no detachment↔workshop relation; a workshop belongs to a **centre**. The legacy backend confirms the shape: `organizations` → `centers.organization_id` → operational rows. |
| **B/Q3** — does a scoped grant imply `detachment.view`? | **Yes.** Any scoped entry for a detachment implies the right to see it. | Report recommendation; removes a class of "granted but invisible" tickets. |
| **B/Q4** — union or override | **Union.** `canIn` is true if the key is global **or** in that detachment's set. | Report recommendation; revocation stays explicit and auditable. |
| **C** — Super Admin | **Option 3 — not a mobile role.** Three presets ship, not four. | Cross-organisation administration is vendor-run outside the app (a service-role provisioning endpoint behind a platform secret), and the in-org root admin is a *Main* Admin. The mobile app never renders a cross-org actor. |
| **D** — the preset table | **Approved with the three questioned cells resolved.** See §3. | Resolved by one stated principle rather than case by case. |
| **E** — the two blocking decisions | **Still open — see §8.** Neither blocks the access layer. | Decision #1 sets the *values* `member.role.assign` writes, not whether the key exists. Decision #8 governs whether `workshop.section.manage` survives. |

**Reversal cost.** Every ruling here is one line in
`lib/core/access/capability.dart` or `capability_presets.dart`. Nothing about
the check surface depends on which way any of them went.

---

## 1. The model

- A **capability** is a plain string key, e.g. `workshop.create`.
- The signed-in user's profile carries a **set of granted capability keys**. It
  is runtime data returned by the repository, not a compile-time enum.
- The UI asks `can('workshop.create')`. It **never** asks `role == 'admin'`.
- **Roles are presets**, i.e. named starting sets of keys used when a Main Admin
  creates an account. They are a convenience at grant time, never the check.
  After creation the Main Admin can add or remove individual keys, so a user's
  real capability set may not match any preset.
- An unknown key is **denied**, never granted. Adding a key server-side must
  never silently unlock a client that does not know it.

### Client-side checks are UX only

This is written into the code, not just this document — see the library comment
at the top of `lib/core/access/capability.dart`:

> Capability checks in this app hide, disable, and gate UI. They are a usability
> device — they stop a user being offered an action that would fail. They are
> **not** a security boundary. Anyone can modify a client. Real enforcement of
> every capability in this file is the backend developer's responsibility, on
> every request, server-side. `TODO(security)` markers in the capability code
> point back to this paragraph.

### A denied capability renders as absent or disabled — never as a dead control

Carried from the house rule the legacy app enforces: the UI must never present a
control that does nothing. A capability the session lacks renders its control
**absent or visibly disabled**, and a missing handler is passed down as `null` so
the widget renders read-only. Preferring a removed affordance over an inert one
is the rule; `CapabilityGate` implements both and defaults to removal.

### The single-resolver rule

Carried over from the legacy `session_access.dart`, which got this right: **one**
function resolves whether a capability is held, and both the route guard and the
in-screen controls call it. When the guard and the controls resolve access
separately they drift, and a user reaches a screen where every control is
disabled — or worse, a control works on a screen they should not have reached.

In this code that function is `Capabilities.canIn`. `can` delegates to it. The
route guard and `CapabilityGate` both call it and nothing else.

### Two-key routes

Also carried from legacy: a route may open on **either of two** capabilities
while each control inside is gated individually. The shift screens are the
example — they open for schedule management *or* attendance recording, and the
edit controls and the attendance toggles check different keys.
`Capabilities.canAnyIn` is the resolver for that case.

---

## 2. Capability keys — 29, as ruled

`[SOURCED]` = named explicitly in the brief.
`[RULED]` = was an assumption; settled on 2026-09-02 per §0.

### Detachment — 4

| Key | Unlocks | Scope | Source |
|---|---|---|---|
| `detachment.view` | See a detachment and its tabs. The anchor of per-detachment scoping. | scoped | [RULED — keep] |
| `detachment.create` | Create a new detachment. | **global** | [RULED — keep; an org coordinator who opens teams is not an account administrator] |
| `detachment.edit` | Edit name, region, main centre, notes. | scoped | [SOURCED] |
| `detachment.archive` | Archive / restore a detachment. | scoped | [RULED — keep; highest-consequence detachment act, never delegated in legacy] |

### Members — 6

| Key | Unlocks | Scope | Source |
|---|---|---|---|
| `member.view` | Names, roles, who is on a shift. | scoped | [RULED — keep, split] |
| `member.contact.view` | Phone numbers and personal details. | scoped | [RULED — **new**; the split so a volunteer can see who is on their own shift without reading everyone's phone number] |
| `member.invite` | Add a person to a detachment. | scoped | [SOURCED] |
| `member.edit` | Edit a member's name, specialty, phone. | scoped | [SOURCED] |
| `member.deactivate` | Deactivate a member. Legacy never hard-deletes. | scoped | [RULED — keep; touches attendance history on every past shift] |
| `member.role.assign` | Change a member's role within the detachment. | scoped | [RULED — keep] |

### Shifts — 7

| Key | Unlocks | Scope | Source |
|---|---|---|---|
| `shift.manage` | Create a weekly shift template **and** edit its name, leader, times. | scoped | [RULED — **merged** from `shift.create` + `shift.edit`] |
| `shift.delete` | Delete a shift with its occurrences, attendance, and roster. | scoped | [RULED — keep separate; destructive, cascades] |
| `shift.assign` | Add/remove members on a shift's roster. | scoped | [SOURCED] |
| `shift.publish` | Make a draft week visible to volunteers. **Reserved — meaning still open.** | scoped | [SOURCED, meaning pending] |
| `shift.attendance.record` | Mark present/absent on a dated occurrence, inside the one-hour window. | scoped | [RULED — keep, split] |
| `shift.attendance.override` | Correct attendance **after** the one-hour lock. | scoped | [RULED — **new**; a supervisor act, and the one that wants an audit trail] |
| `shift.occurrence.manage` | Cancel a date, or add a date manually. | scoped | [RULED — keep; cancelling one Tuesday ≠ changing every Tuesday] |

> **Not a permission:** the weekday of a shift is immutable for everyone. That is
> a data rule carried from legacy. It must never become a key.

> **On `shift.publish`:** the legacy program has no draft/published concept — a
> shift exists and is immediately live. Whether publish is real depends on which
> scheduling interaction the Domain Note 5 redesign picks, and that redesign now
> carries a standing requirement to be *easier* to operate than legacy, which
> argues against an extra state. The key is reserved and granted, but nothing
> checks it yet. Decide it when scheduling is designed.

### Inventory — 2

| Key | Unlocks | Scope | Source |
|---|---|---|---|
| `inventory.adjust` | Record an inflow or outflow movement. The daily act. | scoped | [SOURCED] |
| `inventory.item.manage` | Add items and edit name, unit, minimum, expiry. The setup act. | scoped | [RULED — **merged** from `inventory.item.create` + `.edit`] |

> The boundary that matters here is the sourced one and it is a good one: a medic
> logging an outflow is a different job from deciding what the detachment stocks.

### Workshops — 7, all org-level per §0/Q2

| Key | Unlocks | Scope | Source |
|---|---|---|---|
| `workshop.create` | Create a workshop. | global | [SOURCED] |
| `workshop.edit` | Edit name, date, location, fee, capacity. | global | [SOURCED] |
| `workshop.archive` | Archive / restore a workshop. | global | [RULED — keep] |
| `workshop.people.manage` | Add, edit, remove participants and team members. | global | [RULED — keep as one key; legacy handles the register as one screen] |
| `workshop.attendance.record` | Toggle a person's attendance. No time-lock in legacy, so no override key. | global | [RULED — keep] |
| `workshop.payment.record` | Set paid / unpaid / unspecified. | global | [RULED — keep; money, and the one field with an audit consequence] |
| `workshop.section.manage` | Create, rename, delete sections and assign people. | global | [RULED — **conditional** on open decision #8; deleted with sections if they do not carry over] |

### Statistics — 1

| Key | Unlocks | Scope | Source |
|---|---|---|---|
| `stats.view` | Open the statistics tabs. Scoped, so seeing your own detachment's numbers is a different grant from seeing every detachment's. | scoped | [RULED — keep; statistics are performance data about named individuals] |

### Administration and organisation — 2

| Key | Unlocks | Scope | Source |
|---|---|---|---|
| `admin.manage` | Create admin accounts and grant/revoke their capabilities. | global | [SOURCED] |
| `org.edit` | Edit organisation info (name, legal name, address, public email). | global | [RULED — keep; editing the org's public email is not the same job as creating admin accounts] |

> **Deliberately not a capability:** personal app settings — theme, motion level,
> notification preferences, profile, security/sessions. These affect only the
> signed-in user's own device or account, so gating them behind a grant would be
> wrong. The legacy `editSettings` permission conflated personal preferences with
> organisation settings; that is split here into "no capability needed" and
> `org.edit`.

### Dropped on 2026-09-02

`shift.view` · `inventory.view` · `workshop.view` — all three were granted to
every role in the old preset table, so they gated nothing and cost an admin
three clicks per account. **Visibility now follows membership:** if you are in a
detachment you see its schedule and its stock; if you are in the org you see the
workshop list. `detachment.view` survives because "which detachments can this
person see" is a real question and it anchors the scoping model.

> `inventory.view` was in the sourced set — it was named in the brief. It is
> dropped anyway on the argument above. Restoring it is one constant plus one
> preset row if you disagree.

**Total: 29 keys — 10 sourced, 19 ruled.**

---

## 3. Presets — 3, as ruled

A preset is the starting grant set at account creation. It is not stored as the
user's identity and is not consulted at check time. Super Admin is not a mobile
preset (§0/C).

The sub-Admin column follows **one principle**, which is also how the three
questioned cells were resolved:

> **A sub-Admin does every operational act, and no lifecycle act, no money, and
> no administration.**

Lifecycle acts are the four that destroy or retire a record —
`detachment.archive`, `member.deactivate`, `shift.delete`, `workshop.archive` —
plus `detachment.edit`, which renames the team itself. Money is
`workshop.payment.record`. Administration is `admin.manage`, `org.edit`,
`detachment.create`. Retro-correcting attendance after the lock
(`shift.attendance.override`) is a supervisor act and sits with the lifecycle
group.

| Key | Main Admin | sub-Admin | Volunteer |
|---|:--:|:--:|:--:|
| `detachment.view` | Y | Y | Y |
| `detachment.create` | Y | – | – |
| `detachment.edit` | Y | – | – |
| `detachment.archive` | Y | – | – |
| `member.view` | Y | Y | **Y** |
| `member.contact.view` | Y | Y | – |
| `member.invite` | Y | Y | – |
| `member.edit` | Y | Y | – |
| `member.deactivate` | Y | – | – |
| `member.role.assign` | Y | Y | – |
| `shift.manage` | Y | Y | – |
| `shift.delete` | Y | – | – |
| `shift.assign` | Y | Y | – |
| `shift.publish` | Y | Y | – |
| `shift.attendance.record` | Y | Y | – |
| `shift.attendance.override` | Y | – | – |
| `shift.occurrence.manage` | Y | Y | – |
| `inventory.adjust` | Y | Y | – |
| `inventory.item.manage` | Y | Y | – |
| `workshop.create` | Y | Y | – |
| `workshop.edit` | Y | Y | – |
| `workshop.archive` | Y | – | – |
| `workshop.people.manage` | Y | Y | – |
| `workshop.attendance.record` | Y | Y | – |
| `workshop.payment.record` | Y | – | – |
| `workshop.section.manage` | Y | Y | – |
| `stats.view` | Y | Y | – |
| `admin.manage` | Y | – | – |
| `org.edit` | Y | – | – |

### The three questioned cells, resolved

1. **Volunteer now holds `member.view`.** The old table denied it, which meant a
   volunteer could not see who else was on their own shift — a real usability
   loss caused by the key doing two jobs. The split fixes it: volunteers see
   names and rosters, they do not see `member.contact.view`.
2. **sub-Admin keeps `member.role.assign` and still does not get
   `member.deactivate`.** This is not the inconsistency it looked like. Under
   the capability model, a member's *role* is a roster label (who leads this
   shift), not a grant of app capabilities — assigning it is operational.
   Deactivation retires a person's record and rewrites how their attendance
   history reads, which is a lifecycle act. Different axes, so the split holds.
3. **sub-Admin keeps `stats.view`.** A day-to-day operator running shifts needs
   attendance rates to do the job. The privacy concern is answered by *scope*,
   not by denial: `stats.view` is scoped, so a sub-Admin sees their own
   detachment's numbers and not the org's.

**Volunteer holds exactly two keys** — `detachment.view` and `member.view`.
That is not an oversight. Everything else a volunteer sees (the schedule, the
stock list, the workshop list) follows from membership now that the three view
keys are dropped.

---

## 4. Scoped capabilities — ruled and implemented

A sub-Admin can be scoped per detachment (may manage A but not B). The legacy
program already needed this: `session_access.dart` binds a temporary account to
exactly one record id and validates both the route subtree and each control
against it.

### The representation

Two grant sets, checked in one call:

- a **global set** — capabilities held everywhere in the org. Exactly ten keys
  are global: `detachment.create`, `admin.manage`, `org.edit`, and all seven
  `workshop.*`.
- a **scoped map** — detachment id → capability set, for the nineteen keys that
  live inside a detachment (`detachment.view/edit/archive`, `member.*`,
  `shift.*`, `inventory.*`, `stats.view`).

The check surface is two methods:

- `can(key)` — global capabilities only.
- `canIn(detachmentId, key)` — true if the key is in the global set **or** in
  that detachment's scoped set. **Union, per §0/Q4.**

Plus `canAnyIn(detachmentId, keys)` for the two-key routes.

**Q3 is implemented:** any scoped entry for a detachment implies
`detachment.view` for it. Granting someone `shift.manage` in Homs lets them see
Homs, without a second grant.

### Why this shape

1. **The check site never changes.** A screen inside a detachment always calls
   `canIn(detachmentId, ...)`, whether or not scoping is enabled for that user.
   Turning scoping on later does not touch a single screen.
2. **It matches how the data is already routed.** Every inventory and shift
   route already carries a detachment id (see `DETACHMENT-SCOPING.md`), so the
   scope argument is always in hand.
3. **Workshops are org-level** (§0/Q2), so no workshop screen carries a
   detachment id and `workshop.*` is checked with `can`.
4. **It degrades safely.** If the backend sends only a global set, `canIn`
   behaves exactly like `can`.
5. **Union, not override.** A Main Admin holds everything globally and should
   not need an entry per detachment. Revoking for one detachment means removing
   the global key and re-granting per detachment — explicit and auditable,
   rather than a silent negative override that is invisible in a grant screen.

---

## 5. Super Admin — not a mobile role

In any preset table Super Admin and Main Admin hold identical keys. The real
difference is *scope* — a Main Admin administers one organisation, a Super Admin
sees all of them — and that is an axis the capability set does not carry.

**Ruled: option 3.** Super Admin is not a mobile role. Cross-organisation
administration is vendor-run outside the app entirely, and the in-organisation
root admin is a Main Admin, not a separate tier. The mobile app ships three
presets and never renders a cross-org actor. If a Super Admin surface is ever
needed it is the later web dashboard, which is why `lib/core/access/` is pure
Dart with no Flutter import — the dashboard can reuse it verbatim.

The two rejected alternatives, recorded so the decision is legible: (1) a
separate org-scope field on the profile, orthogonal to capabilities; (2)
dedicated `org.list` / `org.switch` keys. Both add an axis the mobile app has no
screen for.

---

## 6. Where this lives in the code

Implemented as proposed. The split keeps the access rules free of mobile-only
dependencies, so the future web dashboard can import them unchanged.

- `lib/core/access/capability.dart` — the 29 key constants, the global/scoped
  partition, and the `Capabilities` value type with `can` / `canIn` /
  `canAnyIn`. **Pure Dart, no Flutter import.**
- `lib/core/access/capability_presets.dart` — the three presets. **Pure Dart.**
- `lib/core/access/capability_guard.dart` — the Flutter/Riverpod layer:
  `capabilitiesProvider`, the `CapabilityGate` widget for hiding or disabling
  controls, and `requireCapability` for `go_router` redirects.

---

## 7. Stop point — lifted

The 2026-09-02 rulings in §0 clear this file. Admin screens are unblocked.

---

## 8. Still open — not guessed

These could not be settled from the record and are **not** decided here.

1. **Decision #1 — member roles.** Legacy has seven (leader, organization,
   administrative, followUp, support, trainer, member); the new app invented
   four (`lead, medic, trainee, volunteer`). This sets the *values*
   `member.role.assign` writes. It does not block the key or the access layer.
2. **Decision #8 — do workshop sections carry over?** If not,
   `workshop.section.manage` is deleted — one constant and one preset row.
3. **Decision #2 — can one volunteer belong to several detachments?** Both
   codebases currently say scalar. The scoped map already allows several for an
   *admin*; the volunteer question is a domain-model question, not this one.
4. **`shift.publish`'s meaning** — reserved, granted, unchecked, pending the
   Domain Note 5 scheduling redesign.
5. **Does the legacy no-hard-delete rule for members carry over?** The new
   `TeamMember` has no deactivation concept yet, so `member.deactivate` has
   nothing to call.
6. **The grant UI for multi-detachment scoping.** The model allows it; no screen
   grants it. That is the admin dashboard's problem, now unblocked.
