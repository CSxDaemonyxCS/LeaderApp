import 'dart:math';

import '../../../core/result/result.dart';
import '../../team/domain/team_models.dart';
import '../domain/workshop_models.dart';
import '../domain/workshop_repository.dart';

class MockWorkshopRepository implements WorkshopRepository {
  MockWorkshopRepository();
  final _rand = Random(51);

  final List<Workshop> _workshops = [
    Workshop(
      id: 'w1',
      name: 'الإسعاف الأولي المتقدم',
      at: DateTime.now().add(const Duration(days: 4, hours: 3)),
      location: 'قاعة الشعلان الكبرى',
      capacity: 20, registered: 18, guests: 3,
      status: WorkshopStatus.scheduled,
      organizingTeam: const [
        TeamMember(id: 'm2', name: 'ليلى ياسين', initials: 'لي',
            role: TeamRole.lead, detachmentId: 'd_dam_central',
            attendance: AttendanceState.present),
        TeamMember(id: 'm8', name: 'دانا عمر', initials: 'دع',
            role: TeamRole.medic, detachmentId: 'd_dam_central',
            attendance: AttendanceState.present),
      ],
    ),
    Workshop(
      id: 'w2',
      name: 'إدارة الحوادث الجماعية',
      at: DateTime.now().add(const Duration(days: 11, hours: 2)),
      location: 'قاعة داريا التدريبية',
      capacity: 30, registered: 12, guests: 2,
      status: WorkshopStatus.scheduled,
      organizingTeam: const [
        TeamMember(id: 'm11', name: 'ماجد صالح', initials: 'مص',
            role: TeamRole.lead, detachmentId: 'd_dam_rural',
            attendance: AttendanceState.present),
      ],
    ),
    Workshop(
      id: 'w3',
      name: 'إنعاش قلبي رئوي — تجديد',
      at: DateTime.now().subtract(const Duration(days: 3)),
      location: 'قاعة الشعلان',
      capacity: 25, registered: 25, guests: 0,
      status: WorkshopStatus.done,
      organizingTeam: const [
        TeamMember(id: 'm1', name: 'أحمد كنعان', initials: 'أك',
            role: TeamRole.lead, detachmentId: 'd_dam_central',
            attendance: AttendanceState.present),
      ],
    ),
  ];

  final List<WorkshopParticipant> _parts = [
    const WorkshopParticipant(id: 'p1', workshopId: 'w1', name: 'أحمد كنعان',
        initials: 'أك', kind: ParticipantKind.member,
        attendance: AttendanceState.present),
    const WorkshopParticipant(id: 'p2', workshopId: 'w1', name: 'نور الحسن',
        initials: 'نح', kind: ParticipantKind.member,
        attendance: AttendanceState.present),
    const WorkshopParticipant(id: 'p3', workshopId: 'w1', name: 'رنا سعيد',
        initials: 'رس', kind: ParticipantKind.member,
        attendance: AttendanceState.notInvited),
    const WorkshopParticipant(id: 'p4', workshopId: 'w1', name: 'زيد الحلبي',
        initials: 'زح', kind: ParticipantKind.guest,
        attendance: AttendanceState.present),
    const WorkshopParticipant(id: 'p5', workshopId: 'w1', name: 'ميس شامي',
        initials: 'مش', kind: ParticipantKind.guest,
        attendance: AttendanceState.late),
    const WorkshopParticipant(id: 'p6', workshopId: 'w1', name: 'خالد عساف',
        initials: 'خع', kind: ParticipantKind.guest,
        attendance: AttendanceState.notInvited),
  ];

  Future<void> _latency() => Future<void>.delayed(
        Duration(milliseconds: 400 + _rand.nextInt(400)),
      );

  @override
  Future<Result<List<Workshop>>> list() async {
    await _latency();
    return Success(List.of(_workshops));
  }

  @override
  Future<Result<Workshop>> byId(String id) async {
    await _latency();
    final w = _workshops.firstWhere((e) => e.id == id,
        orElse: () => _workshops.first);
    return Success(w);
  }

  @override
  Future<Result<Workshop>> create({
    required String name,
    required DateTime at,
    required String location,
    required int capacity,
  }) async {
    await _latency();
    final w = Workshop(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      name: name, at: at, location: location, capacity: capacity,
      registered: 0, guests: 0,
      status: WorkshopStatus.scheduled,
      organizingTeam: const [],
    );
    _workshops.add(w);
    return Success(w);
  }

  @override
  Future<Result<Workshop>> update(Workshop w) async {
    await _latency();
    final i = _workshops.indexWhere((e) => e.id == w.id);
    if (i >= 0) _workshops[i] = w;
    return Success(w);
  }

  @override
  Future<Result<List<WorkshopParticipant>>> participants(String workshopId) async {
    await _latency();
    return Success(_parts.where((p) => p.workshopId == workshopId).toList());
  }

  @override
  Future<Result<WorkshopParticipant>> setParticipantAttendance(
      String participantId, AttendanceState state) async {
    await _latency();
    final i = _parts.indexWhere((p) => p.id == participantId);
    if (i < 0) return const Failure('لم يُعثر على المشارك.');
    _parts[i] = _parts[i].copyWith(attendance: state);
    return Success(_parts[i]);
  }
}
