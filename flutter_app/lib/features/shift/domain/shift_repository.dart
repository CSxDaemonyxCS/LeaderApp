import '../../../core/result/result.dart';
import '../../team/domain/team_models.dart';
import 'shift_models.dart';

abstract class ShiftRepository {
  /// Every shift starting in the seven days from [weekStart] (a Saturday),
  /// ordered by day then start time.
  Future<Result<List<Shift>>> listForWeek(
      String detachmentId, DateTime weekStart);

  Future<Result<List<Shift>>> listForDetachmentToday(String detachmentId);

  Future<Result<Shift>> byId(String id);

  /// Creates one dated shift. With [repeatWeekly] it also files a
  /// [ShiftTemplate], so the same shift appears on the same weekday from then
  /// on — the one control that turns a day's work into a standing schedule.
  Future<Result<Shift>> create({
    required String detachmentId,
    required DateTime date,
    required String centerName,
    required int startMinutes,
    required int endMinutes,
    required int needed,
    bool repeatWeekly = false,
  });

  Future<Result<Shift>> update(Shift shift);

  Future<Result<void>> delete(String id);

  Future<Result<Shift>> assignVolunteer(String shiftId, String memberId);

  Future<Result<Shift>> unassignVolunteer(String shiftId, String memberId);

  Future<Result<Shift>> markAttendance(
      String shiftId, String memberId, AttendanceState state);

  /// The roster, each member marked with whether they already work a shift
  /// that overlaps this one. Members already on *this* shift are not offered.
  Future<Result<List<ShiftCandidate>>> candidatesFor(String shiftId);

  /// Fills the gap with free members, most-rested first. Returns how many
  /// were added — zero is a legitimate answer and the caller says so.
  Future<Result<int>> quickFill(String shiftId);

  Future<Result<List<ShiftTemplate>>> templates(String detachmentId);

  /// Stops a weekly repeat. Occurrences it already produced are untouched.
  Future<Result<void>> stopTemplate(String templateId);

  /// Copies a whole week's shifts onto another week, **without** their
  /// assignments — a schedule repeats, the people on it do not.
  /// Returns how many shifts were created. Duplicates are skipped.
  Future<Result<int>> copyWeek({
    required String detachmentId,
    required DateTime fromWeekStart,
    required DateTime toWeekStart,
  });

  /// Materialises every active template into [weekStart], skipping any shift
  /// that already exists at that day and time. Returns how many were added.
  Future<Result<int>> applyTemplates({
    required String detachmentId,
    required DateTime weekStart,
  });
}
