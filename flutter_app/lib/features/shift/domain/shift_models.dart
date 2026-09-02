import '../../team/domain/team_models.dart';

/// Where a week begins in this app: **Saturday**.
///
/// Not a preference — it is how a Syrian volunteer week is actually worked,
/// and the whole schedule screen (the day strip, "copy last week", the weekly
/// repeat) reads off it. Kept in one place so nothing can disagree.
const int weekStartsOn = DateTime.saturday;

/// The Saturday on or before [d], at local midnight.
DateTime startOfWeek(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: (day.weekday - weekStartsOn) % 7));
}

/// Local midnight of [d] — the canonical form of a shift's date. Two shifts
/// on the same day must compare equal, and a stray hour on a `DateTime` is
/// exactly how that quietly stops being true.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The three shifts almost every detachment actually runs, plus an escape
/// hatch. Offering these as one tap is the single biggest thing that makes
/// scheduling easy for someone who has never done it: nobody should have to
/// operate two time pickers to say "the morning shift".
enum ShiftPeriod { morning, evening, night, custom }

extension ShiftPeriodTimes on ShiftPeriod {
  /// Minutes from midnight. `night` deliberately ends *after* midnight.
  (int start, int end)? get times => switch (this) {
        ShiftPeriod.morning => (8 * 60, 14 * 60),
        ShiftPeriod.evening => (14 * 60, 20 * 60),
        ShiftPeriod.night => (20 * 60, 2 * 60),
        ShiftPeriod.custom => null,
      };

  /// Which preset a pair of times matches, or [ShiftPeriod.custom].
  static ShiftPeriod match(int start, int end) {
    for (final p in ShiftPeriod.values) {
      final t = p.times;
      if (t != null && t.$1 == start && t.$2 == end) return p;
    }
    return ShiftPeriod.custom;
  }
}

/// A weekly repeat. One row per weekday the detachment always runs a shift.
///
/// The legacy program stored the schedule as a weekly template plus dated
/// occurrences, and that shape is kept here because it is the one that makes
/// "every Tuesday evening" a single record instead of fifty-two.
///
/// Stopping a template never touches the occurrences it already produced —
/// last month's attendance has to keep reading the same way after this
/// month's schedule changes.
class ShiftTemplate {
  const ShiftTemplate({
    required this.id,
    required this.detachmentId,
    required this.centerName,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    required this.needed,
    this.active = true,
  });

  final String id;
  final String detachmentId;
  final String centerName;

  /// `DateTime.monday` (1) … `DateTime.sunday` (7).
  final int weekday;

  final int startMinutes;
  final int endMinutes;
  final int needed;
  final bool active;

  ShiftPeriod get period =>
      ShiftPeriodTimes.match(startMinutes, endMinutes);

  ShiftTemplate copyWith({
    String? centerName,
    int? weekday,
    int? startMinutes,
    int? endMinutes,
    int? needed,
    bool? active,
  }) =>
      ShiftTemplate(
        id: id,
        detachmentId: detachmentId,
        centerName: centerName ?? this.centerName,
        weekday: weekday ?? this.weekday,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
        needed: needed ?? this.needed,
        active: active ?? this.active,
      );

  factory ShiftTemplate.fromJson(Map<String, dynamic> j) => ShiftTemplate(
        id: j['id'] as String,
        detachmentId: j['detachmentId'] as String,
        centerName: j['centerName'] as String,
        weekday: j['weekday'] as int,
        startMinutes: j['startMinutes'] as int,
        endMinutes: j['endMinutes'] as int,
        needed: j['needed'] as int,
        active: (j['active'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'detachmentId': detachmentId,
        'centerName': centerName,
        'weekday': weekday,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'needed': needed,
        'active': active,
      };
}

/// One dated shift — the thing people are actually assigned to.
///
/// `assigned` and `hasCoverageGap` used to be stored fields that the caller
/// had to keep in step with the attendee list. They are derived now, so the
/// count on the card and the chips under it cannot drift apart.
class Shift {
  const Shift({
    required this.id,
    required this.detachmentId,
    required this.date,
    required this.centerName,
    required this.startMinutes,
    required this.endMinutes,
    required this.needed,
    required this.attendees,
    this.templateId,
  });

  final String id;
  final String detachmentId;

  /// Local midnight of the day the shift *starts*. A night shift that runs
  /// past midnight still belongs to the day it began.
  final DateTime date;

  final String centerName;
  final int startMinutes;
  final int endMinutes;
  final int needed;
  final List<TeamMember> attendees;

  /// Set when the shift was produced by a weekly repeat. Editing the shift
  /// does not edit the template — one week's change is not next week's rule.
  final String? templateId;

  int get assigned => attendees.length;
  int get gap => (needed - assigned).clamp(0, needed);
  bool get hasCoverageGap => assigned < needed;

  /// True when the shift runs past midnight, e.g. 20:00 → 02:00.
  bool get crossesMidnight => endMinutes <= startMinutes;

  DateTime get start => date.add(Duration(minutes: startMinutes));
  DateTime get end => date
      .add(Duration(days: crossesMidnight ? 1 : 0))
      .add(Duration(minutes: endMinutes));

  ShiftPeriod get period => ShiftPeriodTimes.match(startMinutes, endMinutes);

  int get coveragePercent =>
      needed == 0 ? 100 : ((assigned / needed) * 100).round().clamp(0, 100);

  /// Whole-hour accessors kept for the screens that only ever show hours.
  int get startHour => startMinutes ~/ 60;
  int get endHour => endMinutes ~/ 60;

  /// Two shifts collide when their real time ranges intersect — which is why
  /// [start] and [end] resolve the midnight crossing first. Assigning the
  /// same person to 20:00–02:00 and 00:00–06:00 is a double booking even
  /// though the two rows carry different dates.
  bool overlaps(Shift other) =>
      start.isBefore(other.end) && other.start.isBefore(end);

  bool get isPast => end.isBefore(DateTime.now());
  bool get isRunningNow {
    final now = DateTime.now();
    return !start.isAfter(now) && end.isAfter(now);
  }

  Shift copyWith({
    DateTime? date,
    String? centerName,
    int? startMinutes,
    int? endMinutes,
    int? needed,
    List<TeamMember>? attendees,
  }) =>
      Shift(
        id: id,
        detachmentId: detachmentId,
        templateId: templateId,
        date: date ?? this.date,
        centerName: centerName ?? this.centerName,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
        needed: needed ?? this.needed,
        attendees: attendees ?? this.attendees,
      );

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
        id: j['id'] as String,
        detachmentId: j['detachmentId'] as String,
        templateId: j['templateId'] as String?,
        date: DateTime.parse(j['date'] as String),
        centerName: j['centerName'] as String,
        startMinutes: j['startMinutes'] as int,
        endMinutes: j['endMinutes'] as int,
        needed: j['needed'] as int,
        attendees: (j['attendees'] as List)
            .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'detachmentId': detachmentId,
        if (templateId != null) 'templateId': templateId,
        'date': date.toIso8601String(),
        'centerName': centerName,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'needed': needed,
        'attendees': attendees.map((a) => a.toJson()).toList(),
      };
}

/// A roster member offered for assignment, with the one thing the person
/// assigning actually needs to know: whether they are already working.
///
/// The screen shows busy members rather than hiding them — a lead who cannot
/// find someone in the list assumes the list is broken, and then assigns them
/// twice through some other route.
class ShiftCandidate {
  const ShiftCandidate({
    required this.member,
    required this.busy,
    this.busyWith,
  });

  final TeamMember member;
  final bool busy;

  /// The shift they are already on, for the conflict line.
  final Shift? busyWith;
}

/// What one week of the schedule adds up to. Read by the week header and by
/// the exported report, so both quote the same numbers.
class WeekSummary {
  const WeekSummary({
    required this.shiftCount,
    required this.assignedTotal,
    required this.neededTotal,
    required this.gapShiftCount,
  });

  final int shiftCount;
  final int assignedTotal;
  final int neededTotal;
  final int gapShiftCount;

  int get coveragePercent => neededTotal == 0
      ? 100
      : ((assignedTotal / neededTotal) * 100).round().clamp(0, 100);

  factory WeekSummary.of(List<Shift> shifts) => WeekSummary(
        shiftCount: shifts.length,
        assignedTotal: shifts.fold(0, (s, x) => s + x.assigned),
        neededTotal: shifts.fold(0, (s, x) => s + x.needed),
        gapShiftCount: shifts.where((x) => x.hasCoverageGap).length,
      );
}
