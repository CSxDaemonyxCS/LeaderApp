# MTM Mobile API Contract

Version: `v1`

Base path: `/api/v1`

This contract describes the API consumed by `flutter_app`. The field names,
enum values, and nesting below match the Dart `fromJson` / `toJson` methods.

Features built **frontend-first**, whose contract is not agreed yet, are not in
this file: they live in `FRONTEND-BACKEND-INTEGRATION.md` until their payload
and status codes are settled, and then move here.

## Transport and authentication

- Production traffic uses HTTPS.
- Request and response bodies use `application/json; charset=utf-8` unless the
  response is `204 No Content`.
- Authenticated requests send the access token in this exact form:

  ```http
  Authorization: Bearer <access-token>
  ```

- The sign-in response returns access and refresh tokens. Both are stored only
  in platform secure storage. They are never written to ordinary preferences.
- Password-reset endpoints use the reset token returned by the reset-request
  endpoint in the same bearer header.
- The TOTP secret and full `otpauthUrl` returned during MFA setup are displayed
  only for the active setup flow and are not persisted by the client.
- Member phone numbers and session IP addresses arrive already masked.

## JSON conventions

- Property names use `camelCase`.
- Dates and timestamps are ISO 8601 strings, including an offset or `Z` when
  the value represents an instant.
- Durations use whole seconds. `HomeSummary.lockRemaining` is serialized as
  `lockRemainingSec`.
- Optional properties emitted conditionally by `toJson` are omitted when
  absent; they are not sent as empty strings.
- List responses are JSON arrays, not pagination envelopes in v1.
- A successful endpoint returning `void` responds with `204 No Content`.

## Errors

All non-success responses use:

```json
{
  "error": {
    "code": "validation",
    "message": "Human-readable message",
    "fields": {
      "capacity": "Field-specific message"
    }
  }
}
```

`fields` is optional. The client recognizes these codes:

- `not_found` — HTTP `404`
- `not_permitted` — HTTP `403`
- `conflict` — HTTP `409`
- `validation` — HTTP `422`
- `authentication_expired` — HTTP `401`

### Frontend consumption (RFC 9457-ready)

The client models every error as a typed `Problem` (`lib/core/problem/`),
shaped so a future **RFC 9457 (`application/problem+json`)** response drops in
without touching screens or error architecture. Rules the backend contract must
respect:

- **The `code` is the only thing frontend flow branches on.** `error.message`
  / `detail` / `title` are diagnostics and last-resort fallback only, never
  product copy for a recognized code, and never a branch key.
- A **code this client version does not recognize** is safe: it renders a
  generic localized fallback ("تعذر إكمال العملية"), not `error.message`, and
  is not assumed retryable.
- The wire spelling above (`snake_case`) is what the client parses today; it is
  defined in one place (`ProblemCode.wire`) and can move to another convention
  cheaply.

Still open (see `FRONTEND-BACKEND-INTEGRATION.md` §2): whether the envelope
becomes literal RFC 9457 members (`type`/`title`/`status`/`detail`/`instance` +
`code` extension), the field-error key shape, and whether a safe support
reference id is provided.

`426 Upgrade Required` is not part of this contract yet. The client handles it
as a blocking application state and expects its body to use the shared Problem
Details contract with a `upgrade_required` code. See
`FRONTEND-BACKEND-INTEGRATION.md` §1 and §2.

`stale_write` (also `HTTP 409`, distinct from the `conflict` code above) is
likewise not part of this contract yet, but the client already recognises it:
`ProblemCode.staleWrite` — an **optimistic-concurrency** version mismatch on a
versioned write, never the same thing as the business-rule `conflict` code.
The full contract (the `version` token, what a `stale_write` body must carry,
and how a conflict is resolved) is decided in
`FRONTEND-BACKEND-INTEGRATION.md` §5.

Write requests are **not idempotent in `v1`**, and no `/sync` endpoint exists
yet. The client already has a local-first write foundation that mints one
UUIDv7 identity per logical write and will send it as `Idempotency-Key` on the
future write/sync transport; the backend contract for that (header name,
in-progress / invalid-reuse codes, retention) is open in
`FRONTEND-BACKEND-INTEGRATION.md` §3, and the related optimistic-concurrency
contract (record `version`, stale-write response contents, conflict
resolution/idempotency) is decided in `FRONTEND-BACKEND-INTEGRATION.md` §5.

## Canonical model payloads

### Capabilities

```json
{
  "global": [
    "workshop.create",
    "org.edit"
  ],
  "scoped": {
    "d_123": [
      "detachment.view",
      "member.view",
      "shift.assign"
    ]
  }
}
```

`global` and each value inside `scoped` are sets represented as arrays. Array
order is not significant. Unknown keys may be carried by the client but never
grant access in a client version that does not recognize them.

The 29 recognized capability keys are:

```text
Global
detachment.create
workshop.create
workshop.edit
workshop.archive
workshop.people.manage
workshop.attendance.record
workshop.payment.record
workshop.section.manage
admin.manage
org.edit

Scoped by detachment id
detachment.view
detachment.edit
detachment.archive
member.view
member.contact.view
member.invite
member.edit
member.deactivate
member.role.assign
shift.manage
shift.delete
shift.assign
shift.publish
shift.attendance.record
shift.attendance.override
shift.occurrence.manage
inventory.adjust
inventory.item.manage
stats.view
```

### AuthUser

```json
{
  "id": "u_123",
  "name": "User Name",
  "email": "user@example.org",
  "capabilities": {
    "global": ["workshop.create"],
    "scoped": {
      "d_123": ["detachment.view", "member.view"]
    }
  },
  "orgName": "Organization Name",
  "avatarInitials": "UN"
}
```

`avatarInitials` is optional. There is no `role` property.

### MfaSetupData

```json
{
  "otpauthUrl": "otpauth://totp/MTM:user@example.org?secret=SERVER_ISSUED&issuer=MTM",
  "manualSecret": "SERVER_ISSUED",
  "backupCodes": ["CODE-ONE", "CODE-TWO"]
}
```

### Session

```json
{
  "id": "s_123",
  "device": "Device and client",
  "ipMasked": "192.0.xx.xx",
  "locationLabel": "City, Country",
  "startedAt": "2026-09-02T14:30:00Z",
  "current": true
}
```

### Detachment

```json
{
  "id": "d_123",
  "name": "Detachment name",
  "region": "Region",
  "mainCenter": "Main center",
  "memberCount": 10,
  "weeklyShiftCount": 4,
  "coveragePercent": 90,
  "status": "active",
  "notes": "Optional internal notes"
}
```

`status` is one of `active`, `archived`. `notes` is optional.

### DetachmentStats

```json
{
  "attendanceSeries": [82, 85, 88, 86, 91, 90, 92],
  "coverageSeries": [90, 90, 95, 95, 100, 95, 100],
  "stockSeries": [3, 7, 5, 8, 4, 6, 5]
}
```

Each series contains the last seven days, oldest first.

### TeamMember

```json
{
  "id": "m_123",
  "name": "Member name",
  "initials": "MN",
  "role": "medic",
  "detachmentId": "d_123",
  "attendance": "present",
  "phoneMasked": "+963 9xx xxx 123"
}
```

`role` is one of `lead`, `medic`, `trainee`, `volunteer`. `attendance` is one
of `present`, `late`, `absent`, `notInvited`. `phoneMasked` is optional and,
when present, is already masked by the server.

### Shift

```json
{
  "id": "sh_123",
  "detachmentId": "d_123",
  "centerName": "Center name",
  "startHour": 8,
  "endHour": 14,
  "assigned": 2,
  "needed": 3,
  "hasCoverageGap": true,
  "attendees": [
    {
      "id": "m_123",
      "name": "Member name",
      "initials": "MN",
      "role": "medic",
      "detachmentId": "d_123",
      "attendance": "present",
      "phoneMasked": "+963 9xx xxx 123"
    }
  ],
  "corrections": [
    {
      "id": "corr_1",
      "memberId": "m_123",
      "before": { "status": "notCheckedIn" },
      "after": { "status": "checkedIn", "checkInAt": "2026-07-09T08:03:00.000" },
      "reason": "نسي المشرف تسجيل الدخول وقت الشفت",
      "author": { "id": "u_9", "displayName": "أحمد المشرف" },
      "correctedAt": "2026-07-12T10:00:00.000"
    }
  ]
}
```

Hours are whole local-clock hours in the range accepted by the backend.
`attendees` contains full `TeamMember` payloads. `corrections` is append-only
(oldest first), omitted or empty when the shift has never been corrected —
see `ShiftRepository.addAttendanceCorrection` and
`FRONTEND-BACKEND-INTEGRATION.md` §6. `author.id` is for internal
traceability only; the client never renders it, only `author.displayName`.

### InventoryItem

```json
{
  "id": "i_123",
  "detachmentId": "d_123",
  "name": "Item name",
  "unit": "box",
  "currentStock": 12,
  "minimum": 5,
  "expiresOn": "2027-03-15T00:00:00.000Z",
  "level": "ok"
}
```

`level` is one of `ok`, `low`, `empty`. `expiresOn` is optional.

### InventoryMovement

```json
{
  "id": "mv_123",
  "itemId": "i_123",
  "direction": "outflow",
  "quantity": 2,
  "reason": "Shift issue",
  "at": "2026-09-02T14:30:00Z"
}
```

`direction` is one of `inflow`, `outflow`.

### Workshop

```json
{
  "id": "w_123",
  "name": "Workshop name",
  "at": "2026-09-12T09:30:00Z",
  "location": "Training hall",
  "capacity": 20,
  "registered": 18,
  "guests": 3,
  "status": "scheduled",
  "organizingTeam": [
    {
      "id": "m_123",
      "name": "Member name",
      "initials": "MN",
      "role": "lead",
      "detachmentId": "d_123",
      "attendance": "present"
    }
  ]
}
```

`status` is one of `scheduled`, `ongoing`, `done`. `organizingTeam` contains
full `TeamMember` payloads.

### WorkshopParticipant

```json
{
  "id": "p_123",
  "workshopId": "w_123",
  "name": "Participant name",
  "initials": "PN",
  "kind": "guest",
  "attendance": "notInvited"
}
```

`kind` is one of `member`, `guest`. `attendance` uses the `TeamMember`
attendance values.

### HomeDecisionItem

```json
{
  "id": "decision_123",
  "kind": "unfilledShift",
  "title": "Decision title",
  "subtitle": "Decision details",
  "actionLabel": "Open"
}
```

`kind` is one of `unfilledShift`, `expiringStock`, `joinRequest`.

### HomeSummary

```json
{
  "detachmentName": "Detachment name",
  "centerName": "Center name",
  "activeShift": {
    "id": "sh_123",
    "detachmentId": "d_123",
    "centerName": "Center name",
    "startHour": 8,
    "endHour": 14,
    "assigned": 2,
    "needed": 3,
    "hasCoverageGap": true,
    "attendees": []
  },
  "lockRemainingSec": 1800,
  "attendancePresent": 2,
  "attendanceTotal": 3,
  "decisions": [
    {
      "id": "decision_123",
      "kind": "unfilledShift",
      "title": "Decision title",
      "subtitle": "Decision details",
      "actionLabel": "Open"
    }
  ],
  "workshopsThisWeek": 2,
  "attendanceRatePercent": 90,
  "stockLowCount": 3
}
```

`activeShift` and `lockRemainingSec` are optional.

### AppNotification

One row of the Notifications Center. `target` is a pointer, never a snapshot:
the client re-reads the record it names at the moment the user taps the row,
which is what makes a deleted shift a handled state rather than a crash.

```json
{
  "id": "shiftUnderstaffed:sh_412",
  "kind": "shiftUnderstaffed",
  "occurredAt": "2026-09-05T14:00:00+03:00",
  "count": 2,
  "recordLabel": "مركز الشعلان",
  "target": { "type": "shift", "detachmentId": "d_12", "shiftId": "sh_412" },
  "isRead": false
}
```

`kind` is one of `shiftUnderstaffed`, `shiftAttendanceMissing`,
`shiftStartingSoon`, `stockDepleted`, `stockLow`, `stockExpiring`. The two
remaining client-side kinds (`syncConflict`, `syncFailed`) are derived from
the local outbox and are **never** expected on this payload.

`target.type` is one of `shift`, `storage`, `review`, `sync`. An unrecognised
`type` is dropped by the client, and the row then renders as informational
rather than sending the user somewhere arbitrary. A row with no `target` at
all is valid and renders as informational — that is the shape a future
server-sent announcement takes.

**`id` must be stable for as long as the condition is.** Read state is keyed
by it, and the client rebuilds its own derived feed on every load; an id
regenerated per fetch would silently un-read every row the user had already
seen. `<kind>:<record id>` is what the client generates and what it expects
back.

`count` is the magnitude behind the row — volunteers still missing, attendance
still unrecorded, units left — and `0` when the kind has no count.
`recordLabel` is a real name from the record (a centre, a stock item), never
an id and never an internal tag.

### NotificationPrefs

```json
{
  "shiftReminders": true,
  "stockAlerts": true,
  "workshopUpdates": true,
  "joinRequests": false
}
```

### OrgInfo

```json
{
  "name": "Organization name",
  "legalName": "Legal organization name",
  "address": "Public address",
  "emailPublic": "contact@example.org",
  "detachmentCount": 5,
  "memberCount": 25
}
```

## Endpoints

The response type names below refer to the canonical JSON payloads above.

### Authentication

#### `AuthRepository.signIn`

`POST /api/v1/auth/sign-in` — public

Request:

```json
{
  "emailOrUsername": "user@example.org",
  "password": "user-supplied password"
}
```

Response `200`:

```json
{
  "accessToken": "opaque-access-token",
  "refreshToken": "opaque-refresh-token",
  "user": {
    "id": "u_123",
    "name": "User Name",
    "email": "user@example.org",
    "capabilities": {
      "global": ["workshop.create"],
      "scoped": {
        "d_123": ["detachment.view", "member.view"]
      }
    },
    "orgName": "Organization Name",
    "avatarInitials": "UN"
  }
}
```

The `user` property is an exact `AuthUser` payload.

#### `AuthRepository.beginMfaSetup`

`POST /api/v1/auth/mfa/setup` — access bearer required

Request: no body.

Response `200`: `MfaSetupData` JSON.

#### `AuthRepository.verifyMfa`

`POST /api/v1/auth/mfa/verify` — access bearer required

Request:

```json
{
  "code": "123456"
}
```

Response `204`: no body.

#### `AuthRepository.requestPasswordReset`

`POST /api/v1/auth/password-reset/request` — public

Request:

```json
{
  "email": "user@example.org"
}
```

Response `200`:

```json
{
  "resetToken": "opaque-reset-token"
}
```

The client keeps this token only for the active reset flow.

#### `AuthRepository.verifyResetOtp`

`POST /api/v1/auth/password-reset/verify` — reset bearer required

Request:

```json
{
  "email": "user@example.org",
  "code": "123456"
}
```

Response `204`: no body.

#### `AuthRepository.setNewPassword`

`POST /api/v1/auth/password-reset/complete` — reset bearer required

Request:

```json
{
  "password": "new user-supplied password"
}
```

Response `204`: no body. The reset token is invalid after success.

#### `AuthRepository.currentUser`

`GET /api/v1/auth/me` — access bearer required

Request: no body.

Response `200`: `AuthUser` JSON.

When no token exists, the client resolves the repository method to `null`
without making this request. An expired token returns
`authentication_expired`.

#### `AuthRepository.confirmNewDevice`

`POST /api/v1/auth/new-device/confirm` — access bearer required

Request:

```json
{
  "itsMe": true
}
```

Response `204`: no body.

#### `AuthRepository.signOut`

`POST /api/v1/auth/sign-out` — access bearer required

Request: no body.

Response `204`: no body. The submitted session token is revoked.

#### `AuthRepository.listSessions`

`GET /api/v1/auth/sessions` — access bearer required

Request: no body.

Response `200`: JSON array of `Session` objects.

#### `AuthRepository.revokeSession`

`DELETE /api/v1/auth/sessions/{sessionId}` — access bearer required

Request: no body.

Response `204`: no body. Revoking the current session returns `validation`.

### Detachments

#### `DetachmentRepository.list`

`GET /api/v1/detachments?filter={active|archived}&query={text}` — access bearer
required

Both query parameters are optional. Request: no body.

Response `200`: JSON array of `Detachment` objects.

#### `DetachmentRepository.byId`

`GET /api/v1/detachments/{detachmentId}` — access bearer required

Request: no body.

Response `200`: `Detachment` JSON.

#### `DetachmentRepository.create`

`POST /api/v1/detachments` — access bearer required

Request:

```json
{
  "name": "Detachment name",
  "region": "Region",
  "mainCenter": "Main center",
  "notes": "Optional internal notes"
}
```

`notes` is optional. Response `201`: `Detachment` JSON.

#### `DetachmentRepository.update`

`PUT /api/v1/detachments/{detachmentId}` — access bearer required

Request: complete `Detachment` JSON. The body `id` must equal
`{detachmentId}`.

Response `200`: updated `Detachment` JSON.

#### `DetachmentRepository.stats`

`GET /api/v1/detachments/{detachmentId}/stats` — access bearer required

Request: no body.

Response `200`: `DetachmentStats` JSON.

### Team members

#### `TeamRepository.listForDetachment`

`GET /api/v1/detachments/{detachmentId}/members` — access bearer required

Request: no body.

Response `200`: JSON array of `TeamMember` objects.

#### `TeamRepository.assignRole`

`PATCH /api/v1/members/{memberId}/role` — access bearer required

Request:

```json
{
  "role": "medic"
}
```

Response `200`: updated `TeamMember` JSON.

#### `TeamRepository.setAttendance`

`PATCH /api/v1/members/{memberId}/attendance` — access bearer required

Request:

```json
{
  "attendance": "present"
}
```

Response `200`: updated `TeamMember` JSON.

### Shifts

#### `ShiftRepository.listForDetachmentToday`

`GET /api/v1/detachments/{detachmentId}/shifts/today` — access bearer required

Request: no body.

Response `200`: JSON array of `Shift` objects.

#### `ShiftRepository.byId`

`GET /api/v1/shifts/{shiftId}` — access bearer required

Request: no body.

Response `200`: `Shift` JSON.

#### `ShiftRepository.assignVolunteer`

`POST /api/v1/shifts/{shiftId}/assignments` — access bearer required

Request:

```json
{
  "memberId": "m_123"
}
```

Response `200`: updated `Shift` JSON. A duplicate assignment returns
`conflict`; a member outside the shift detachment returns `validation`.

#### `ShiftRepository.markAttendance`

`PATCH /api/v1/shifts/{shiftId}/members/{memberId}/attendance` — access bearer
required

Request:

```json
{
  "attendance": "late"
}
```

Response `200`: updated `Shift` JSON.

**One-hour ordinary edit window.** This endpoint — and its check-in/check-out
equivalents — is only valid while the shift's real end time (see
`Shift.crossesMidnight` for how an overnight shift's end is computed) plus
one hour has not yet passed, evaluated against **server time**, not a client
timestamp. The frontend enforces the same window client-side
(`lib/features/shift/domain/attendance_policy.dart`, `AttendanceWindow`) —
this is a UX convenience only; the client check is not a security boundary
(`CAPABILITIES.md` §0) and the server must independently reject a late
attempt through this endpoint with `409 stale_write`-adjacent semantics —
concretely, a distinct wire code (the frontend mock uses
`attendance_window_expired`; the real wire code is a
`Backend contract decision required` — see §6 below). See
`FRONTEND-BACKEND-INTEGRATION.md` §6 for the full contract, including
`addAttendanceCorrection` below, which is the only endpoint that remains
valid after this window closes.

#### `ShiftRepository.addAttendanceCorrection`

`POST /api/v1/shifts/{shiftId}/members/{memberId}/attendance-corrections` —
access bearer required, and the bearer must hold
`shift.attendance.override` in the shift's detachment. Available
**indefinitely** — no time-window check applies to this endpoint.

Request:

```json
{
  "status": "checkedIn",
  "checkInAt": "2026-07-09T08:03:00.000",
  "checkOutAt": null,
  "reason": "نسي المشرف تسجيل الدخول وقت الشفت",
  "correctedAt": "2026-07-12T10:00:00.000"
}
```

`status` uses the same values as `TeamMember.attendance`
(`notCheckedIn`/`checkedIn`/`checkedOut`/`absent`). `reason` is required and
must be non-empty after the same normalization the frontend already applies
(trimmed, internal whitespace collapsed) — the server must reject a blank or
whitespace-only reason with `validation`, never accept it silently.
`correctedAt` is advisory (what the client's clock read); a real backend
should additionally stamp its own server-time value and treat that as
authoritative for the audit trail.

Response `200`: updated `Shift` JSON, with the new correction appended to a
`corrections` array (see `Shift` below) and the shift's live attendance
fields (`attendance`/`checkInAt`/`checkOutAt` on the affected member) updated
to the corrected values. **Append-only**: a correction is never returned by
any endpoint that edits or removes an earlier one — there is no
`PATCH`/`DELETE` on this resource, by design (`FRONTEND-BACKEND-INTEGRATION.md`
§6).

A checkout before its check-in returns `validation` with code
`checkout_before_checkin`, matching `markAttendance`'s own rule. A missing
shift or member returns `not_found`.

### Inventory

#### `InventoryRepository.listForDetachment`

`GET /api/v1/detachments/{detachmentId}/inventory-items` — access bearer
required

Request: no body.

Response `200`: JSON array of `InventoryItem` objects.

#### `InventoryRepository.byId`

`GET /api/v1/inventory-items/{itemId}` — access bearer required

Request: no body.

Response `200`: `InventoryItem` JSON.

#### `InventoryRepository.movementsForItem`

`GET /api/v1/inventory-items/{itemId}/movements` — access bearer required

Request: no body.

Response `200`: JSON array of `InventoryMovement` objects, newest first.

#### `InventoryRepository.addMovement`

`POST /api/v1/inventory-items/{itemId}/movements` — access bearer required

Request:

```json
{
  "itemId": "i_123",
  "direction": "outflow",
  "quantity": 2,
  "reason": "Shift issue"
}
```

The body `itemId` must equal `{itemId}`. Response `200`: the updated
`InventoryItem` JSON. Quantity must be greater than zero; an outflow cannot
exceed current stock. Rejected quantities return `validation`.

### Workshops

Workshop endpoints and capabilities are organization-level; no detachment id
is sent.

#### `WorkshopRepository.list`

`GET /api/v1/workshops` — access bearer required

Request: no body.

Response `200`: JSON array of `Workshop` objects sorted by `at` ascending.

#### `WorkshopRepository.byId`

`GET /api/v1/workshops/{workshopId}` — access bearer required

Request: no body.

Response `200`: `Workshop` JSON.

#### `WorkshopRepository.create`

`POST /api/v1/workshops` — access bearer required

Request:

```json
{
  "name": "Workshop name",
  "at": "2026-09-12T09:30:00Z",
  "location": "Training hall",
  "capacity": 20
}
```

Response `201`: `Workshop` JSON. Capacity must be greater than zero.

#### `WorkshopRepository.update`

`PUT /api/v1/workshops/{workshopId}` — access bearer required

Request: complete `Workshop` JSON. The body `id` must equal `{workshopId}`.

Response `200`: updated `Workshop` JSON.

#### `WorkshopRepository.participants`

`GET /api/v1/workshops/{workshopId}/participants` — access bearer required

Request: no body.

Response `200`: JSON array of `WorkshopParticipant` objects.

#### `WorkshopRepository.setParticipantAttendance`

`PATCH /api/v1/workshop-participants/{participantId}/attendance` — access
bearer required

Request:

```json
{
  "attendance": "present"
}
```

Response `200`: updated `WorkshopParticipant` JSON.

### Home

#### `HomeRepository.summary`

`GET /api/v1/home/summary?detachmentId=<id>` — access bearer required

Request: no body. `detachmentId` is required — the Today dashboard renders one
detachment at a time (`DETACHMENT-SCOPING.md` §4), and the client picks which.

Response `200`: `HomeSummary` JSON — the day's operational snapshot for that
detachment, joined server-side so the dashboard costs one round trip rather
than three:

- `detachmentId`, `detachmentName`, `region`, `mainCenter`
- `shifts` — every shift dated yesterday, today, or tomorrow, each the same
  `Shift` shape the schedule endpoints return. Three days because "running
  now" and "next" are clock questions: a 20:00–02:00 shift dated yesterday is
  still running at 01:00, and after the last shift of today the next one is
  tomorrow's. The client resolves current/next from real timestamps.
- `rosterCount`
- `storageStatus` — one of `empty`, `healthy`, `expiring`, `low`, `depleted`
- `lowStockCount`, `expiringSoonCount`

Response `403` for a detachment the caller may not see, `404` for one that
does not exist — the client renders each as its own state rather than
silently swapping in another detachment.

The dashboard's remaining signals (queued writes, a failed sync run, a
conflict awaiting review) are **client-side** and are never expected on this
payload.

### Notifications

Not implemented by any backend yet. The client ships a repository seam and a
mock that **derives** this feed by joining the shift and inventory data it
already holds, so every row points at a record that really exists. These are
the shapes a real implementation is expected to serve.

#### `NotificationRepository.feed`

`GET /api/v1/notifications?detachmentId=<id>` — access bearer required

Request: no body. `detachmentId` is required, for the same reason
`home/summary` requires it: the centre renders one detachment at a time.

Response `200`: `{ "notifications": [ AppNotification, ... ] }` — every
condition the detachment's records currently raise, **already filtered to what
the caller may see**. The client filters again by capability as a UX gate, but
that is not the boundary: a notification the caller has no grant for must not
be in the payload at all.

Response `403` / `404` as for `home/summary`.

The client sorts and groups the rows itself, so no order is required.

#### Read state

`PUT /api/v1/notifications/read` — access bearer required

Request: `{ "ids": ["shiftUnderstaffed:sh_412", ...] }`. Idempotent: an id
already marked read is not an error.

Response `200`: `{ "readIds": [...] }` — the caller's complete read set, so
the client can reconcile rather than assume.

Read state is **per user**, and covers ids the server never issued: the
client's own `syncConflict` / `syncFailed` rows are stored in the same set.
An unrecognised id must therefore be stored, not rejected.

### Settings

#### `SettingsRepository.notificationPrefs`

`GET /api/v1/settings/notifications` — access bearer required

Request: no body.

Response `200`: `NotificationPrefs` JSON.

#### `SettingsRepository.updateNotificationPrefs`

`PUT /api/v1/settings/notifications` — access bearer required

Request and response `200`: complete `NotificationPrefs` JSON.

#### `SettingsRepository.orgInfo`

`GET /api/v1/settings/organization` — access bearer required

Request: no body.

Response `200`: `OrgInfo` JSON.

#### `SettingsRepository.motionLevel`

`GET /api/v1/settings/motion-level` — access bearer required

Request: no body.

Response `200`:

```json
{
  "motionLevel": "reduced"
}
```

`motionLevel` is `full`, `reduced`, or `null` on first use.

#### `SettingsRepository.updateMotionLevel`

`PUT /api/v1/settings/motion-level` — access bearer required

Request and response `200`:

```json
{
  "motionLevel": "full"
}
```
