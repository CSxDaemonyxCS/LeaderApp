import 'dart:math';

import '../../../core/result/result.dart';
import '../../team/domain/team_models.dart';
import '../domain/shift_models.dart';
import '../domain/shift_repository.dart';

class MockShiftRepository implements ShiftRepository {
  MockShiftRepository();
  final _rand = Random(31);

  final List<Shift> _shifts = [
    const Shift(
      id: 'sh1',
      detachmentId: 'd_dam_central',
      centerName: 'مركز الشعلان',
      startHour: 8,
      endHour: 14,
      assigned: 8,
      needed: 8,
      hasCoverageGap: false,
      attendees: [
        TeamMember(id: 'm1', name: 'أحمد كنعان', initials: 'أك',
            role: TeamRole.lead, detachmentId: 'd_dam_central',
            attendance: AttendanceState.present),
        TeamMember(id: 'm2', name: 'ليلى ياسين', initials: 'لي',
            role: TeamRole.medic, detachmentId: 'd_dam_central',
            attendance: AttendanceState.present),
      ],
    ),
    const Shift(
      id: 'sh2',
      detachmentId: 'd_dam_central',
      centerName: 'مركز الشعلان',
      startHour: 14,
      endHour: 20,
      assigned: 7,
      needed: 10,
      hasCoverageGap: true,
      attendees: [
        TeamMember(id: 'm1', name: 'أحمد كنعان', initials: 'أك',
            role: TeamRole.lead, detachmentId: 'd_dam_central',
            attendance: AttendanceState.present),
        TeamMember(id: 'm3', name: 'سامي درويش', initials: 'سد',
            role: TeamRole.medic, detachmentId: 'd_dam_central',
            attendance: AttendanceState.late),
        TeamMember(id: 'm5', name: 'ياسر البكري', initials: 'يب',
            role: TeamRole.volunteer, detachmentId: 'd_dam_central',
            attendance: AttendanceState.absent),
      ],
    ),
    const Shift(
      id: 'sh3',
      detachmentId: 'd_dam_central',
      centerName: 'مركز المهاجرين',
      startHour: 20,
      endHour: 2,
      assigned: 5,
      needed: 8,
      hasCoverageGap: true,
      attendees: [],
    ),
    const Shift(
      id: 'sh4',
      detachmentId: 'd_dam_rural',
      centerName: 'مركز داريا',
      startHour: 10,
      endHour: 16,
      assigned: 6,
      needed: 6,
      hasCoverageGap: false,
      attendees: [],
    ),
  ];

  Future<void> _latency() => Future<void>.delayed(
        Duration(milliseconds: 400 + _rand.nextInt(400)),
      );

  @override
  Future<Result<List<Shift>>> listForDetachmentToday(String detachmentId) async {
    await _latency();
    return Success(_shifts.where((s) => s.detachmentId == detachmentId).toList());
  }

  @override
  Future<Result<Shift>> byId(String id) async {
    await _latency();
    final s = _shifts.firstWhere((s) => s.id == id, orElse: () => _shifts.first);
    return Success(s);
  }

  @override
  Future<Result<Shift>> assignVolunteer(String shiftId, String memberId) async {
    await _latency();
    final i = _shifts.indexWhere((s) => s.id == shiftId);
    if (i < 0) return const Failure('لم يُعثر على الشفت.');
    return Success(_shifts[i]);
  }

  @override
  Future<Result<Shift>> markAttendance(
      String shiftId, String memberId, AttendanceState state) async {
    await _latency();
    final i = _shifts.indexWhere((s) => s.id == shiftId);
    if (i < 0) return const Failure('لم يُعثر على الشفت.');
    return Success(_shifts[i]);
  }
}
