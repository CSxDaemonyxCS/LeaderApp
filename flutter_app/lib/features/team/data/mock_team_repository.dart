import 'dart:math';

import '../../../core/result/result.dart';
import '../domain/team_models.dart';
import '../domain/team_repository.dart';

class MockTeamRepository implements TeamRepository {
  MockTeamRepository();

  final _rand = Random(21);

  final List<TeamMember> _members = [
    // dam_central
    const TeamMember(id: 'm1', name: 'أحمد كنعان', initials: 'أك',
        role: TeamRole.lead, detachmentId: 'd_dam_central',
        attendance: AttendanceState.present, phoneMasked: '+963 9xx xx xx 12'),
    const TeamMember(id: 'm2', name: 'ليلى ياسين', initials: 'لي',
        role: TeamRole.medic, detachmentId: 'd_dam_central',
        attendance: AttendanceState.present),
    const TeamMember(id: 'm3', name: 'سامي درويش', initials: 'سد',
        role: TeamRole.medic, detachmentId: 'd_dam_central',
        attendance: AttendanceState.late),
    const TeamMember(id: 'm4', name: 'نور الحسن', initials: 'نح',
        role: TeamRole.volunteer, detachmentId: 'd_dam_central',
        attendance: AttendanceState.present),
    const TeamMember(id: 'm5', name: 'ياسر البكري', initials: 'يب',
        role: TeamRole.volunteer, detachmentId: 'd_dam_central',
        attendance: AttendanceState.absent),
    const TeamMember(id: 'm6', name: 'رنا سعيد', initials: 'رس',
        role: TeamRole.trainee, detachmentId: 'd_dam_central',
        attendance: AttendanceState.notInvited),
    const TeamMember(id: 'm7', name: 'طارق خالد', initials: 'طخ',
        role: TeamRole.volunteer, detachmentId: 'd_dam_central',
        attendance: AttendanceState.present),
    const TeamMember(id: 'm8', name: 'دانا عمر', initials: 'دع',
        role: TeamRole.medic, detachmentId: 'd_dam_central',
        attendance: AttendanceState.present),
    const TeamMember(id: 'm9', name: 'علي منصور', initials: 'عم',
        role: TeamRole.volunteer, detachmentId: 'd_dam_central',
        attendance: AttendanceState.absent),
    const TeamMember(id: 'm10', name: 'هند شحادة', initials: 'هش',
        role: TeamRole.volunteer, detachmentId: 'd_dam_central',
        attendance: AttendanceState.present),
    // dam_rural
    const TeamMember(id: 'm11', name: 'ماجد صالح', initials: 'مص',
        role: TeamRole.lead, detachmentId: 'd_dam_rural',
        attendance: AttendanceState.present),
    const TeamMember(id: 'm12', name: 'ريم قاسم', initials: 'رق',
        role: TeamRole.medic, detachmentId: 'd_dam_rural',
        attendance: AttendanceState.present),
    const TeamMember(id: 'm13', name: 'حسام عابد', initials: 'حع',
        role: TeamRole.volunteer, detachmentId: 'd_dam_rural',
        attendance: AttendanceState.late),
    // homs
    const TeamMember(id: 'm14', name: 'أمين رياض', initials: 'أر',
        role: TeamRole.lead, detachmentId: 'd_homs',
        attendance: AttendanceState.present),
    // coast
    const TeamMember(id: 'm15', name: 'كنان عيسى', initials: 'كع',
        role: TeamRole.lead, detachmentId: 'd_coast',
        attendance: AttendanceState.present),
  ];

  Future<void> _latency() => Future<void>.delayed(
        Duration(milliseconds: 400 + _rand.nextInt(400)),
      );

  @override
  Future<Result<List<TeamMember>>> listForDetachment(String detachmentId) async {
    await _latency();
    return Success(
      _members.where((m) => m.detachmentId == detachmentId).toList(),
    );
  }

  @override
  Future<Result<TeamMember>> assignRole(String memberId, TeamRole role) async {
    await _latency();
    final i = _members.indexWhere((m) => m.id == memberId);
    if (i < 0) return const Failure('لم يُعثر على العضو.');
    _members[i] = _members[i].copyWith(role: role);
    return Success(_members[i]);
  }

  @override
  Future<Result<TeamMember>> setAttendance(
      String memberId, AttendanceState state) async {
    await _latency();
    final i = _members.indexWhere((m) => m.id == memberId);
    if (i < 0) return const Failure('لم يُعثر على العضو.');
    _members[i] = _members[i].copyWith(attendance: state);
    return Success(_members[i]);
  }
}
