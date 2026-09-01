import '../../../core/result/result.dart';
import '../../team/domain/team_models.dart';
import 'shift_models.dart';

abstract class ShiftRepository {
  Future<Result<List<Shift>>> listForDetachmentToday(String detachmentId);
  Future<Result<Shift>> byId(String id);
  Future<Result<Shift>> assignVolunteer(String shiftId, String memberId);
  Future<Result<Shift>> markAttendance(
      String shiftId, String memberId, AttendanceState state);
}
