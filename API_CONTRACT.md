# MTM Mobile API Contract

Version: `v1`

Base path: `/api/v1`

This contract describes the API consumed by `flutter_app`. The field names,
enum values, and nesting below match the Dart `fromJson` / `toJson` methods.

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

An unknown code is shown as a generic failure using `error.message`.

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
  ]
}
```

Hours are whole local-clock hours in the range accepted by the backend.
`attendees` contains full `TeamMember` payloads.

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

`GET /api/v1/home/summary` — access bearer required

Request: no body.

Response `200`: `HomeSummary` JSON.

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
