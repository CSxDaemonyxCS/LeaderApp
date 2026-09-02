import 'dart:math';

import '../../../core/result/result.dart';
import '../../team/domain/team_models.dart';
import '../domain/workshop_models.dart';
import '../domain/workshop_repository.dart';

/// In-memory workshops. Workshops are organisation-level — they carry no
/// detachment id (see `CAPABILITIES.md` §0, ruling B/Q2).
///
/// The seed covers all three statuses and both the full and the
/// under-subscribed case, so the list, the detail header, and the stats tab
/// all have something real to render.
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
        TeamMember(id: 'm12', name: 'ريم قاسم', initials: 'رق',
            role: TeamRole.medic, detachmentId: 'd_dam_rural',
            attendance: AttendanceState.notInvited),
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
    Workshop(
      id: 'w4',
      name: 'فرز المصابين في الميدان',
      at: DateTime.now().add(const Duration(days: 2, hours: 5)),
      location: 'مركز الوعر — القاعة الشمالية',
      capacity: 16, registered: 16, guests: 4,
      status: WorkshopStatus.scheduled,
      organizingTeam: const [
        TeamMember(id: 'm14', name: 'أمين رياض', initials: 'أر',
            role: TeamRole.lead, detachmentId: 'd_homs',
            attendance: AttendanceState.present),
      ],
    ),
    Workshop(
      id: 'w5',
      name: 'التعامل مع حالات الاختناق',
      at: DateTime.now().subtract(const Duration(hours: 1)),
      location: 'مركز اللاذقية',
      capacity: 12, registered: 10, guests: 1,
      status: WorkshopStatus.ongoing,
      organizingTeam: const [
        TeamMember(id: 'm15', name: 'كنان عيسى', initials: 'كع',
            role: TeamRole.lead, detachmentId: 'd_coast',
            attendance: AttendanceState.present),
        TeamMember(id: 'm23', name: 'ميساء بدر', initials: 'مب',
            role: TeamRole.medic, detachmentId: 'd_coast',
            attendance: AttendanceState.late),
      ],
    ),
    Workshop(
      id: 'w6',
      name: 'مبادئ الإسعاف للمتطوعين الجدد',
      at: DateTime.now().subtract(const Duration(days: 25)),
      location: 'قاعة داريا التدريبية',
      capacity: 40, registered: 33, guests: 6,
      status: WorkshopStatus.done,
      organizingTeam: const [
        TeamMember(id: 'm11', name: 'ماجد صالح', initials: 'مص',
            role: TeamRole.lead, detachmentId: 'd_dam_rural',
            attendance: AttendanceState.present),
      ],
    ),
  ];

  final List<WorkshopParticipant> _parts = [
    // ---- w1 ----
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

    // ---- w2 ----
    const WorkshopParticipant(id: 'p7', workshopId: 'w2', name: 'حسام عابد',
        initials: 'حع', kind: ParticipantKind.member,
        attendance: AttendanceState.notInvited),
    const WorkshopParticipant(id: 'p8', workshopId: 'w2', name: 'سلمى نجّار',
        initials: 'سن', kind: ParticipantKind.member,
        attendance: AttendanceState.notInvited),
    const WorkshopParticipant(id: 'p9', workshopId: 'w2', name: 'عمر الدالاتي',
        initials: 'عد', kind: ParticipantKind.guest,
        attendance: AttendanceState.notInvited),

    // ---- w3 (finished — a full attendance record) ----
    const WorkshopParticipant(id: 'p10', workshopId: 'w3', name: 'ليلى ياسين',
        initials: 'لي', kind: ParticipantKind.member,
        attendance: AttendanceState.present),
    const WorkshopParticipant(id: 'p11', workshopId: 'w3', name: 'سامي درويش',
        initials: 'سد', kind: ParticipantKind.member,
        attendance: AttendanceState.late),
    const WorkshopParticipant(id: 'p12', workshopId: 'w3', name: 'ياسر البكري',
        initials: 'يب', kind: ParticipantKind.member,
        attendance: AttendanceState.absent),
    const WorkshopParticipant(id: 'p13', workshopId: 'w3', name: 'هند شحادة',
        initials: 'هش', kind: ParticipantKind.member,
        attendance: AttendanceState.present),
    const WorkshopParticipant(id: 'p14', workshopId: 'w3', name: 'طارق خالد',
        initials: 'طخ', kind: ParticipantKind.member,
        attendance: AttendanceState.present),

    // ---- w4 ----
    const WorkshopParticipant(id: 'p15', workshopId: 'w4', name: 'غادة الحموي',
        initials: 'غح', kind: ParticipantKind.member,
        attendance: AttendanceState.notInvited),
    const WorkshopParticipant(id: 'p16', workshopId: 'w4', name: 'وسيم الديب',
        initials: 'ود', kind: ParticipantKind.member,
        attendance: AttendanceState.notInvited),
    const WorkshopParticipant(id: 'p17', workshopId: 'w4', name: 'ريما خضور',
        initials: 'رخ', kind: ParticipantKind.guest,
        attendance: AttendanceState.notInvited),

    // ---- w5 (running now — attendance is being taken) ----
    const WorkshopParticipant(id: 'p18', workshopId: 'w5', name: 'رامي سلوم',
        initials: 'رس', kind: ParticipantKind.member,
        attendance: AttendanceState.present),
    const WorkshopParticipant(id: 'p19', workshopId: 'w5', name: 'جود الحلاق',
        initials: 'جح', kind: ParticipantKind.member,
        attendance: AttendanceState.late),
    const WorkshopParticipant(id: 'p20', workshopId: 'w5', name: 'نبيل مرعي',
        initials: 'نم', kind: ParticipantKind.guest,
        attendance: AttendanceState.absent),

    // w6 keeps no participant record — an old workshop whose sheet was never
    // digitised. The Members tab must render its empty state for it.
  ];

  Future<void> _latency() => Future<void>.delayed(
        Duration(milliseconds: 260 + _rand.nextInt(320)),
      );

  @override
  Future<Result<List<Workshop>>> list() async {
    await _latency();
    final out = List.of(_workshops)..sort((a, b) => a.at.compareTo(b.at));
    return Success(out);
  }

  @override
  Future<Result<Workshop>> byId(String id) async {
    await _latency();
    final i = _workshops.indexWhere((e) => e.id == id);
    // Never fall back to another workshop's record.
    if (i < 0) return const Failure('لم يُعثر على الورشة.', code: 'not_found');
    return Success(_workshops[i]);
  }

  @override
  Future<Result<Workshop>> create({
    required String name,
    required DateTime at,
    required String location,
    required int capacity,
  }) async {
    await _latency();
    if (capacity <= 0) {
      return const Failure('السعة يجب أن تكون أكبر من صفر.', code: 'validation');
    }
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
    if (i < 0) return const Failure('لم يُعثر على الورشة.', code: 'not_found');
    _workshops[i] = w;
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
    if (i < 0) return const Failure('لم يُعثر على المشارك.', code: 'not_found');
    _parts[i] = _parts[i].copyWith(attendance: state);
    return Success(_parts[i]);
  }
}
