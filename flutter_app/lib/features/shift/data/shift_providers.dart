import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../../team/data/team_providers.dart';
import '../domain/shift_models.dart';
import '../domain/shift_repository.dart';
import 'mock_shift_repository.dart';

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  // The mock resolves assignments against the same roster the Members tab
  // reads, so the two screens can never disagree about who exists.
  return MockShiftRepository(ref.watch(teamRepositoryProvider));
});

/// Cache key for one week of one detachment's schedule.
///
/// A record-shaped key, per `DETACHMENT-SCOPING.md` §2 rule 1: the detachment
/// id is part of the key, so two detachments cannot collide on one entry.
class WeekQuery {
  WeekQuery({required this.detachmentId, required DateTime weekStart})
      : weekStart = startOfWeek(weekStart);

  final String detachmentId;
  final DateTime weekStart;

  WeekQuery shifted(int weeks) => WeekQuery(
        detachmentId: detachmentId,
        weekStart: weekStart.add(Duration(days: 7 * weeks)),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekQuery &&
          other.detachmentId == detachmentId &&
          other.weekStart == weekStart;

  @override
  int get hashCode => Object.hash(detachmentId, weekStart);
}

/// The selected week on the schedule tab, per detachment.
///
/// Family state, not a single global — a week picked in one detachment must
/// not be sitting there when another opens (`DETACHMENT-SCOPING.md` §2,
/// rule 3).
final selectedWeekProvider =
    StateProvider.autoDispose.family<DateTime, String>(
        (ref, detachmentId) => startOfWeek(DateTime.now()));

/// The selected day inside that week, as an offset 0–6 from Saturday.
final selectedDayOffsetProvider =
    StateProvider.autoDispose.family<int, String>((ref, detachmentId) {
  // Open on today when today is inside the shown week — the day someone
  // opening the schedule almost always wants.
  final now = DateTime.now();
  return dateOnly(now).difference(startOfWeek(now)).inDays;
});

final weekShiftsProvider = FutureProvider.autoDispose
    .family<Result<List<Shift>>, WeekQuery>((ref, q) async {
  return ref.read(shiftRepositoryProvider).listForWeek(
        q.detachmentId,
        q.weekStart,
      );
});

final todaysShiftsProvider = FutureProvider.autoDispose
    .family<Result<List<Shift>>, String>((ref, detId) async {
  return ref.read(shiftRepositoryProvider).listForDetachmentToday(detId);
});

final shiftByIdProvider =
    FutureProvider.autoDispose.family<Result<Shift>, String>((ref, id) async {
  return ref.read(shiftRepositoryProvider).byId(id);
});

final shiftTemplatesProvider = FutureProvider.autoDispose
    .family<Result<List<ShiftTemplate>>, String>((ref, detId) async {
  return ref.read(shiftRepositoryProvider).templates(detId);
});

final shiftCandidatesProvider = FutureProvider.autoDispose
    .family<Result<List<ShiftCandidate>>, String>((ref, shiftId) async {
  return ref.read(shiftRepositoryProvider).candidatesFor(shiftId);
});
