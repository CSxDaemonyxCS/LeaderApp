import '../../../core/result/result.dart';
import 'team_models.dart';

abstract class TeamRepository {
  Future<Result<List<TeamMember>>> listForDetachment(String detachmentId);
  Future<Result<TeamMember>> assignRole(String memberId, TeamRole role);
  Future<Result<TeamMember>> setAttendance(
      String memberId, AttendanceState state);
}
