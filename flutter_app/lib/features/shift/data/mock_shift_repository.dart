import 'dart:math';

import '../../../core/result/result.dart';
import '../../team/domain/team_models.dart';
import '../../team/domain/team_repository.dart';
import '../domain/shift_models.dart';
import '../domain/shift_repository.dart';

/// In-memory schedule for every active detachment.
///
/// Two rules hold this file together:
///
/// 1. **The roster is read, never copied.** Every attendee is resolved
///    through [TeamRepository], so the schedule cannot show a person the
///    Members tab does not have, and a rename shows up on both.
/// 2. **Occurrences are dated relative to today.** The seed is built at
///    construction from this week's Saturday, so the schedule always has
///    something in it whenever the app is opened — including a filled last
///    week, which is what makes "copy last week" demonstrable.
class MockShiftRepository implements ShiftRepository {
  MockShiftRepository(this._directory) {
    _seed();
  }

  final TeamRepository _directory;
  final _rand = Random(31);

  final List<Shift> _shifts = [];
  final List<ShiftTemplate> _templates = [];

  int _nextShift = 1;
  int _nextTemplate = 1;

  // ---------------------------------------------------------------------
  // Seed
  // ---------------------------------------------------------------------

  /// Weekly repeats per detachment, and the roster ids that start out
  /// assigned to each. Distinct per detachment on purpose: switching
  /// detachments has to show a visibly different week, otherwise a scoping
  /// leak looks the same as correct behaviour.
  static const _plan = <String, List<(int weekday, ShiftPeriod period,
      String center, int needed, List<String> members)>>{
    'd_dam_central': [
      (DateTime.saturday, ShiftPeriod.morning, 'مركز الشعلان', 8,
          ['m1', 'm2', 'm4', 'm7']),
      (DateTime.saturday, ShiftPeriod.evening, 'مركز الشعلان', 6,
          ['m3', 'm8']),
      (DateTime.sunday, ShiftPeriod.morning, 'مركز الشعلان', 6,
          ['m1', 'm10']),
      (DateTime.monday, ShiftPeriod.evening, 'مركز المهاجرين', 8, ['m2']),
      (DateTime.wednesday, ShiftPeriod.night, 'مركز المهاجرين', 5, []),
      (DateTime.thursday, ShiftPeriod.morning, 'مركز الشعلان', 7,
          ['m1', 'm5', 'm9']),
    ],
    'd_dam_rural': [
      (DateTime.saturday, ShiftPeriod.morning, 'مركز داريا', 6,
          ['m11', 'm12', 'm16']),
      (DateTime.monday, ShiftPeriod.evening, 'مركز صحنايا', 6, ['m13']),
      (DateTime.tuesday, ShiftPeriod.morning, 'مركز داريا', 4,
          ['m11', 'm18']),
      (DateTime.friday, ShiftPeriod.evening, 'مركز صحنايا', 5, ['m17']),
    ],
    'd_homs': [
      (DateTime.sunday, ShiftPeriod.morning, 'مركز الوعر', 5,
          ['m14', 'm19']),
      (DateTime.tuesday, ShiftPeriod.evening, 'مركز الوعر', 5, ['m20']),
      (DateTime.thursday, ShiftPeriod.night, 'مركز الوعر', 4, ['m14']),
    ],
    'd_coast': [
      (DateTime.saturday, ShiftPeriod.morning, 'مركز اللاذقية', 4,
          ['m15', 'm23']),
      (DateTime.wednesday, ShiftPeriod.evening, 'مركز جبلة', 5, ['m24']),
    ],
    // d_north_arch is archived and runs no shifts.
  };

  void _seed() {
    final thisWeek = startOfWeek(DateTime.now());
    final lastWeek = thisWeek.subtract(const Duration(days: 7));

    for (final entry in _plan.entries) {
      for (final row in entry.value) {
        final (weekday, period, center, needed, members) = row;
        final times = period.times!;
        _templates.add(ShiftTemplate(
          id: 'tpl${_nextTemplate++}',
          detachmentId: entry.key,
          centerName: center,
          weekday: weekday,
          startMinutes: times.$1,
          endMinutes: times.$2,
          needed: needed,
        ));
        final templateId = 'tpl${_nextTemplate - 1}';

        // Last week ran; this week is being staffed. Last week is seeded a
        // little fuller so the two weeks read differently at a glance.
        for (final (weekStart, ids) in [
          (lastWeek, members),
          (thisWeek, members.take(members.length - (members.isEmpty ? 0 : 1))
              .toList()),
        ]) {
          _shifts.add(Shift(
            id: 'sh${_nextShift++}',
            detachmentId: entry.key,
            templateId: templateId,
            date: _dayOfWeek(weekStart, weekday),
            centerName: center,
            startMinutes: times.$1,
            endMinutes: times.$2,
            needed: needed,
            attendees: _placeholders(entry.key, ids),
          ));
        }
      }
    }
  }

  /// The date of [weekday] inside the week beginning [weekStart] (Saturday).
  static DateTime _dayOfWeek(DateTime weekStart, int weekday) =>
      weekStart.add(Duration(days: (weekday - weekStartsOn) % 7));

  /// Seed attendees are placeholders carrying only an id; every read
  /// re-resolves them against the live roster in [_hydrate], so a member
  /// renamed or deleted on the Members tab is renamed or gone here too.
  static List<TeamMember> _placeholders(String detachmentId, List<String> ids) =>
      [
        for (final id in ids)
          TeamMember(
            id: id,
            name: '',
            initials: '',
            role: TeamRole.volunteer,
            detachmentId: detachmentId,
            attendance: AttendanceState.notInvited,
          ),
      ];

  // ---------------------------------------------------------------------
  // Roster resolution
  // ---------------------------------------------------------------------

  Future<void> _latency() => Future<void>.delayed(
        Duration(milliseconds: 260 + _rand.nextInt(300)),
      );

  Future<List<TeamMember>> _roster(String detachmentId) async {
    final result = await _directory.listForDetachment(detachmentId);
    return result.when(
      success: (data, {stale = false}) => data,
      failure: (_, __) => const <TeamMember>[],
      offline: (cached) => cached ?? const <TeamMember>[],
    );
  }

  /// Replaces each attendee with the live roster record, keeping the
  /// attendance state recorded on the shift. A member who has left the
  /// detachment simply falls out of the list.
  Shift _hydrate(Shift shift, List<TeamMember> roster) {
    final by = {for (final m in roster) m.id: m};
    final attendees = <TeamMember>[
      for (final a in shift.attendees)
        if (by[a.id] != null) by[a.id]!.copyWith(attendance: a.attendance),
    ];
    return shift.copyWith(attendees: attendees);
  }

  Future<List<Shift>> _hydrateAll(
      String detachmentId, Iterable<Shift> shifts) async {
    final roster = await _roster(detachmentId);
    return [for (final s in shifts) _hydrate(s, roster)];
  }

  int _indexOf(String shiftId) => _shifts.indexWhere((s) => s.id == shiftId);

  static int _order(Shift a, Shift b) {
    final byDate = a.date.compareTo(b.date);
    return byDate != 0 ? byDate : a.startMinutes.compareTo(b.startMinutes);
  }

  // ---------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------

  @override
  Future<Result<List<Shift>>> listForWeek(
      String detachmentId, DateTime weekStart) async {
    await _latency();
    final start = startOfWeek(weekStart);
    final end = start.add(const Duration(days: 7));
    final week = _shifts
        .where((s) =>
            s.detachmentId == detachmentId &&
            !s.date.isBefore(start) &&
            s.date.isBefore(end))
        .toList()
      ..sort(_order);
    return Success(await _hydrateAll(detachmentId, week));
  }

  @override
  Future<Result<List<Shift>>> listForDetachmentToday(
      String detachmentId) async {
    await _latency();
    final today = dateOnly(DateTime.now());
    final list = _shifts
        .where((s) => s.detachmentId == detachmentId && s.date == today)
        .toList()
      ..sort(_order);
    return Success(await _hydrateAll(detachmentId, list));
  }

  @override
  Future<Result<Shift>> byId(String id) async {
    await _latency();
    final i = _indexOf(id);
    // Never fall back to another detachment's shift.
    if (i < 0) return const Failure('لم يُعثر على الشفت.', code: 'not_found');
    final roster = await _roster(_shifts[i].detachmentId);
    return Success(_hydrate(_shifts[i], roster));
  }

  // ---------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------

  @override
  Future<Result<Shift>> create({
    required String detachmentId,
    required DateTime date,
    required String centerName,
    required int startMinutes,
    required int endMinutes,
    required int needed,
    bool repeatWeekly = false,
  }) async {
    await _latency();
    if (startMinutes == endMinutes) {
      return const Failure('وقت البداية يجب أن يختلف عن وقت النهاية.',
          code: 'validation');
    }
    if (needed <= 0) {
      return const Failure('عدد المطلوبين يجب أن يكون أكبر من صفر.',
          code: 'validation');
    }
    if (centerName.trim().isEmpty) {
      return const Failure('اسم المركز مطلوب.', code: 'validation');
    }

    final day = dateOnly(date);
    String? templateId;
    if (repeatWeekly) {
      final template = ShiftTemplate(
        id: 'tpl${_nextTemplate++}',
        detachmentId: detachmentId,
        centerName: centerName.trim(),
        weekday: day.weekday,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        needed: needed,
      );
      _templates.add(template);
      templateId = template.id;
    }

    final shift = Shift(
      id: 'sh${_nextShift++}',
      detachmentId: detachmentId,
      templateId: templateId,
      date: day,
      centerName: centerName.trim(),
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      needed: needed,
      attendees: const [],
    );
    _shifts.add(shift);
    return Success(shift);
  }

  @override
  Future<Result<Shift>> update(Shift shift) async {
    await _latency();
    final i = _indexOf(shift.id);
    if (i < 0) return const Failure('لم يُعثر على الشفت.', code: 'not_found');
    if (shift.startMinutes == shift.endMinutes) {
      return const Failure('وقت البداية يجب أن يختلف عن وقت النهاية.',
          code: 'validation');
    }
    if (shift.needed <= 0) {
      return const Failure('عدد المطلوبين يجب أن يكون أكبر من صفر.',
          code: 'validation');
    }
    // Keep the stored attendee ids; the caller may be handing back a
    // hydrated copy, and the roster is re-resolved on the next read anyway.
    _shifts[i] = shift.copyWith(date: dateOnly(shift.date));
    return Success(_shifts[i]);
  }

  @override
  Future<Result<void>> delete(String id) async {
    await _latency();
    final i = _indexOf(id);
    if (i < 0) return const Failure('لم يُعثر على الشفت.', code: 'not_found');
    _shifts.removeAt(i);
    return const Success(null);
  }

  @override
  Future<Result<Shift>> assignVolunteer(String shiftId, String memberId) async {
    await _latency();
    final i = _indexOf(shiftId);
    if (i < 0) return const Failure('لم يُعثر على الشفت.', code: 'not_found');
    final shift = _shifts[i];

    if (shift.attendees.any((a) => a.id == memberId)) {
      return const Failure('هذا المتطوع مسند بالفعل.', code: 'conflict');
    }

    final roster = await _roster(shift.detachmentId);
    final member = roster.where((m) => m.id == memberId).firstOrNull;
    // A member from another detachment must not be assignable here.
    if (member == null) {
      return const Failure('العضو ليس في هذه المفرزة.', code: 'not_found');
    }
    if (_clashFor(memberId, shift) != null) {
      return const Failure('هذا العضو مسند لشفت آخر يتقاطع مع هذا الوقت.',
          code: 'conflict');
    }

    _shifts[i] = shift.copyWith(attendees: [
      ...shift.attendees,
      member.copyWith(attendance: AttendanceState.notInvited),
    ]);
    return Success(_hydrate(_shifts[i], roster));
  }

  @override
  Future<Result<Shift>> unassignVolunteer(
      String shiftId, String memberId) async {
    await _latency();
    final i = _indexOf(shiftId);
    if (i < 0) return const Failure('لم يُعثر على الشفت.', code: 'not_found');
    final shift = _shifts[i];
    final attendees =
        shift.attendees.where((a) => a.id != memberId).toList();
    if (attendees.length == shift.attendees.length) {
      return const Failure('العضو غير مسند لهذا الشفت.', code: 'not_found');
    }
    _shifts[i] = shift.copyWith(attendees: attendees);
    final roster = await _roster(shift.detachmentId);
    return Success(_hydrate(_shifts[i], roster));
  }

  @override
  Future<Result<Shift>> markAttendance(
      String shiftId, String memberId, AttendanceState state) async {
    await _latency();
    final i = _indexOf(shiftId);
    if (i < 0) return const Failure('لم يُعثر على الشفت.', code: 'not_found');
    final shift = _shifts[i];

    final at = shift.attendees.indexWhere((a) => a.id == memberId);
    if (at < 0) {
      return const Failure('العضو غير مسند لهذا الشفت.', code: 'not_found');
    }
    final attendees = [...shift.attendees];
    attendees[at] = attendees[at].copyWith(attendance: state);
    _shifts[i] = shift.copyWith(attendees: attendees);
    final roster = await _roster(shift.detachmentId);
    return Success(_hydrate(_shifts[i], roster));
  }

  // ---------------------------------------------------------------------
  // Assignment helpers
  // ---------------------------------------------------------------------

  /// The other shift [memberId] already works that overlaps [shift], if any.
  Shift? _clashFor(String memberId, Shift shift) {
    for (final other in _shifts) {
      if (other.id == shift.id) continue;
      if (other.detachmentId != shift.detachmentId) continue;
      if (!other.attendees.any((a) => a.id == memberId)) continue;
      if (other.overlaps(shift)) return other;
    }
    return null;
  }

  @override
  Future<Result<List<ShiftCandidate>>> candidatesFor(String shiftId) async {
    await _latency();
    final i = _indexOf(shiftId);
    if (i < 0) return const Failure('لم يُعثر على الشفت.', code: 'not_found');
    final shift = _shifts[i];
    final roster = await _roster(shift.detachmentId);
    final already = shift.attendees.map((a) => a.id).toSet();

    final out = <ShiftCandidate>[
      for (final m in roster)
        if (!already.contains(m.id))
          ShiftCandidate(
            member: m,
            busy: _clashFor(m.id, shift) != null,
            busyWith: _clashFor(m.id, shift),
          ),
    ];
    // Free members first, then by role so leads and medics surface before
    // trainees — the order someone staffing a shift actually wants.
    out.sort((a, b) {
      if (a.busy != b.busy) return a.busy ? 1 : -1;
      return a.member.role.index.compareTo(b.member.role.index);
    });
    return Success(out);
  }

  @override
  Future<Result<int>> quickFill(String shiftId) async {
    final candidates = await candidatesFor(shiftId);
    final free = candidates.when(
      success: (data, {stale = false}) =>
          data.where((c) => !c.busy).map((c) => c.member).toList(),
      failure: (_, __) => const <TeamMember>[],
      offline: (cached) => const <TeamMember>[],
    );
    final i = _indexOf(shiftId);
    if (i < 0) return const Failure('لم يُعثر على الشفت.', code: 'not_found');

    var added = 0;
    for (final m in free) {
      if (_shifts[i].gap == 0) break;
      // Re-check per member: each assignment changes who is still free.
      if (_clashFor(m.id, _shifts[i]) != null) continue;
      _shifts[i] = _shifts[i].copyWith(attendees: [
        ..._shifts[i].attendees,
        m.copyWith(attendance: AttendanceState.notInvited),
      ]);
      added++;
    }
    return Success(added);
  }

  // ---------------------------------------------------------------------
  // Templates and bulk week operations
  // ---------------------------------------------------------------------

  @override
  Future<Result<List<ShiftTemplate>>> templates(String detachmentId) async {
    await _latency();
    final out = _templates
        .where((t) => t.detachmentId == detachmentId && t.active)
        .toList()
      ..sort((a, b) {
        final byDay = ((a.weekday - weekStartsOn) % 7)
            .compareTo((b.weekday - weekStartsOn) % 7);
        return byDay != 0
            ? byDay
            : a.startMinutes.compareTo(b.startMinutes);
      });
    return Success(out);
  }

  @override
  Future<Result<void>> stopTemplate(String templateId) async {
    await _latency();
    final i = _templates.indexWhere((t) => t.id == templateId);
    if (i < 0) return const Failure('لم يُعثر على القالب.', code: 'not_found');
    // Deactivated, not deleted: the shifts it already produced still point at
    // it, and a past week has to keep reading the way it was worked.
    _templates[i] = _templates[i].copyWith(active: false);
    return const Success(null);
  }

  /// True when [detachmentId] already has a shift at this day and start time.
  bool _exists(String detachmentId, DateTime day, int startMinutes) =>
      _shifts.any((s) =>
          s.detachmentId == detachmentId &&
          s.date == day &&
          s.startMinutes == startMinutes);

  @override
  Future<Result<int>> copyWeek({
    required String detachmentId,
    required DateTime fromWeekStart,
    required DateTime toWeekStart,
  }) async {
    await _latency();
    final from = startOfWeek(fromWeekStart);
    final to = startOfWeek(toWeekStart);
    if (from == to) {
      return const Failure('لا يمكن نسخ الأسبوع على نفسه.', code: 'validation');
    }

    final source = _shifts
        .where((s) =>
            s.detachmentId == detachmentId &&
            !s.date.isBefore(from) &&
            s.date.isBefore(from.add(const Duration(days: 7))))
        .toList()
      ..sort(_order);

    var added = 0;
    for (final s in source) {
      final day = to.add(Duration(days: s.date.difference(from).inDays));
      if (_exists(detachmentId, day, s.startMinutes)) continue;
      _shifts.add(Shift(
        id: 'sh${_nextShift++}',
        detachmentId: detachmentId,
        templateId: s.templateId,
        date: day,
        centerName: s.centerName,
        startMinutes: s.startMinutes,
        endMinutes: s.endMinutes,
        needed: s.needed,
        // The schedule repeats; the people on it do not. Copying assignments
        // forward is how a lead ends up publishing a week nobody agreed to.
        attendees: const [],
      ));
      added++;
    }
    return Success(added);
  }

  @override
  Future<Result<int>> applyTemplates({
    required String detachmentId,
    required DateTime weekStart,
  }) async {
    await _latency();
    final start = startOfWeek(weekStart);
    final active =
        _templates.where((t) => t.detachmentId == detachmentId && t.active);

    var added = 0;
    for (final t in active) {
      final day = _dayOfWeek(start, t.weekday);
      if (_exists(detachmentId, day, t.startMinutes)) continue;
      _shifts.add(Shift(
        id: 'sh${_nextShift++}',
        detachmentId: detachmentId,
        templateId: t.id,
        date: day,
        centerName: t.centerName,
        startMinutes: t.startMinutes,
        endMinutes: t.endMinutes,
        needed: t.needed,
        attendees: const [],
      ));
      added++;
    }
    return Success(added);
  }
}
