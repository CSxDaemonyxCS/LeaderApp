import '../../../core/result/result.dart';
import '../../team/domain/team_models.dart';
import 'workshop_models.dart';

abstract class WorkshopRepository {
  Future<Result<List<Workshop>>> list();
  Future<Result<Workshop>> byId(String id);
  Future<Result<Workshop>> create({
    required String name,
    required DateTime at,
    required String location,
    required int capacity,
  });
  Future<Result<Workshop>> update(Workshop w);
  Future<Result<List<WorkshopParticipant>>> participants(String workshopId);
  Future<Result<WorkshopParticipant>> setParticipantAttendance(
      String participantId, AttendanceState state);
}
