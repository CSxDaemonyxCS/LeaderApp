import 'dart:math';

import '../../../core/result/result.dart';
import '../domain/team_models.dart';
import '../domain/team_repository.dart';

/// In-memory roster. Every detachment seeded in `MockDetachmentRepository`
/// has members here except the archived one, so per-detachment isolation is
/// visible on every list.
///
/// The list is mutable and survives for the life of the process, so an add,
/// an edit, and a delete all persist across navigation the way they will
/// against the real backend.
class MockTeamRepository implements TeamRepository {
  MockTeamRepository();

  final _rand = Random(21);

  /// Feeds the ids of members created at runtime. Seeded past the highest
  /// seeded id so a new member can never collide with one below.
  int _nextId = 26;

  final List<TeamMember> _members = [
    // ---- d_dam_central (10) ----
    TeamMember(id: 'm1', name: 'أحمد كنعان',
        initials: TeamMember.initialsOf('أحمد كنعان'),
        department: 'الإسعاف', personalNumber: '101',
        role: TeamRole.lead, detachmentId: 'd_dam_central',
        attendance: AttendanceState.present, phoneMasked: '+963 9xx xx xx 12'),
    TeamMember(id: 'm2', name: 'ليلى ياسين',
        initials: TeamMember.initialsOf('ليلى ياسين'),
        department: 'الإسعاف', personalNumber: '102',
        role: TeamRole.medic, detachmentId: 'd_dam_central',
        attendance: AttendanceState.present, phoneMasked: '+963 9xx xx xx 44'),
    TeamMember(id: 'm3', name: 'سامي درويش',
        initials: TeamMember.initialsOf('سامي درويش'),
        department: 'الإسعاف', personalNumber: '103',
        role: TeamRole.medic, detachmentId: 'd_dam_central',
        attendance: AttendanceState.late, phoneMasked: '+963 9xx xx xx 08'),
    TeamMember(id: 'm4', name: 'نور الحسن',
        initials: TeamMember.initialsOf('نور الحسن'),
        department: 'الإسناد اللوجستي', personalNumber: '104',
        role: TeamRole.volunteer, detachmentId: 'd_dam_central',
        attendance: AttendanceState.present),
    TeamMember(id: 'm5', name: 'ياسر البكري',
        initials: TeamMember.initialsOf('ياسر البكري'),
        department: 'الإسناد اللوجستي', personalNumber: '105',
        role: TeamRole.volunteer, detachmentId: 'd_dam_central',
        attendance: AttendanceState.absent),
    TeamMember(id: 'm6', name: 'رنا سعيد',
        initials: TeamMember.initialsOf('رنا سعيد'),
        department: 'التدريب', personalNumber: '106',
        role: TeamRole.trainee, detachmentId: 'd_dam_central',
        attendance: AttendanceState.notInvited),
    TeamMember(id: 'm7', name: 'طارق خالد',
        initials: TeamMember.initialsOf('طارق خالد'),
        department: 'الاتصالات', personalNumber: '107',
        role: TeamRole.volunteer, detachmentId: 'd_dam_central',
        attendance: AttendanceState.present),
    TeamMember(id: 'm8', name: 'دانا عمر',
        initials: TeamMember.initialsOf('دانا عمر'),
        department: 'الإسعاف', personalNumber: '108',
        role: TeamRole.medic, detachmentId: 'd_dam_central',
        attendance: AttendanceState.present, phoneMasked: '+963 9xx xx xx 71'),
    TeamMember(id: 'm9', name: 'علي منصور',
        initials: TeamMember.initialsOf('علي منصور'),
        department: 'الإسناد اللوجستي', personalNumber: '109',
        role: TeamRole.volunteer, detachmentId: 'd_dam_central',
        attendance: AttendanceState.absent),
    TeamMember(id: 'm10', name: 'هند شحادة',
        initials: TeamMember.initialsOf('هند شحادة'),
        department: 'الاتصالات', personalNumber: '110',
        role: TeamRole.volunteer, detachmentId: 'd_dam_central',
        attendance: AttendanceState.present),

    // ---- d_dam_rural (6) ----
    TeamMember(id: 'm11', name: 'ماجد صالح',
        initials: TeamMember.initialsOf('ماجد صالح'),
        department: 'الإسعاف', personalNumber: '201',
        role: TeamRole.lead, detachmentId: 'd_dam_rural',
        attendance: AttendanceState.present, phoneMasked: '+963 9xx xx xx 30'),
    TeamMember(id: 'm12', name: 'ريم قاسم',
        initials: TeamMember.initialsOf('ريم قاسم'),
        department: 'الإسعاف', personalNumber: '202',
        role: TeamRole.medic, detachmentId: 'd_dam_rural',
        attendance: AttendanceState.present),
    TeamMember(id: 'm13', name: 'حسام عابد',
        initials: TeamMember.initialsOf('حسام عابد'),
        department: 'الإسناد اللوجستي', personalNumber: '203',
        role: TeamRole.volunteer, detachmentId: 'd_dam_rural',
        attendance: AttendanceState.late),
    TeamMember(id: 'm16', name: 'سلمى نجّار',
        initials: TeamMember.initialsOf('سلمى نجّار'),
        department: 'الإسعاف', personalNumber: '204',
        role: TeamRole.medic, detachmentId: 'd_dam_rural',
        attendance: AttendanceState.present),
    TeamMember(id: 'm17', name: 'بشار الأحمد',
        initials: TeamMember.initialsOf('بشار الأحمد'),
        department: 'التدريب', personalNumber: '205',
        role: TeamRole.trainee, detachmentId: 'd_dam_rural',
        attendance: AttendanceState.notInvited),
    TeamMember(id: 'm18', name: 'لمى حجازي',
        initials: TeamMember.initialsOf('لمى حجازي'),
        department: 'الاتصالات', personalNumber: '206',
        role: TeamRole.volunteer, detachmentId: 'd_dam_rural',
        attendance: AttendanceState.absent),

    // ---- d_homs (5) ----
    TeamMember(id: 'm14', name: 'أمين رياض',
        initials: TeamMember.initialsOf('أمين رياض'),
        department: 'الإسعاف', personalNumber: '301',
        role: TeamRole.lead, detachmentId: 'd_homs',
        attendance: AttendanceState.present, phoneMasked: '+963 9xx xx xx 55'),
    TeamMember(id: 'm19', name: 'غادة الحموي',
        initials: TeamMember.initialsOf('غادة الحموي'),
        department: 'الإسعاف', personalNumber: '302',
        role: TeamRole.medic, detachmentId: 'd_homs',
        attendance: AttendanceState.present),
    TeamMember(id: 'm20', name: 'وسيم الديب',
        initials: TeamMember.initialsOf('وسيم الديب'),
        department: 'الإسناد اللوجستي', personalNumber: '303',
        role: TeamRole.volunteer, detachmentId: 'd_homs',
        attendance: AttendanceState.late),
    TeamMember(id: 'm21', name: 'رغد الشامي',
        initials: TeamMember.initialsOf('رغد الشامي'),
        department: 'الاتصالات', personalNumber: '304',
        role: TeamRole.volunteer, detachmentId: 'd_homs',
        attendance: AttendanceState.present),
    TeamMember(id: 'm22', name: 'فادي عزّام',
        initials: TeamMember.initialsOf('فادي عزّام'),
        department: 'التدريب', personalNumber: '305',
        role: TeamRole.trainee, detachmentId: 'd_homs',
        attendance: AttendanceState.notInvited),

    // ---- d_coast (4) ----
    TeamMember(id: 'm15', name: 'كنان عيسى',
        initials: TeamMember.initialsOf('كنان عيسى'),
        department: 'الإسعاف', personalNumber: '401',
        role: TeamRole.lead, detachmentId: 'd_coast',
        attendance: AttendanceState.present, phoneMasked: '+963 9xx xx xx 63'),
    TeamMember(id: 'm23', name: 'ميساء بدر',
        initials: TeamMember.initialsOf('ميساء بدر'),
        department: 'الإسعاف', personalNumber: '402',
        role: TeamRole.medic, detachmentId: 'd_coast',
        attendance: AttendanceState.present),
    TeamMember(id: 'm24', name: 'رامي سلوم',
        initials: TeamMember.initialsOf('رامي سلوم'),
        department: 'الإسناد اللوجستي', personalNumber: '403',
        role: TeamRole.volunteer, detachmentId: 'd_coast',
        attendance: AttendanceState.absent),
    TeamMember(id: 'm25', name: 'جود الحلاق',
        initials: TeamMember.initialsOf('جود الحلاق'),
        department: 'الاتصالات', personalNumber: '404',
        role: TeamRole.volunteer, detachmentId: 'd_coast',
        attendance: AttendanceState.present),

    // d_north_arch is archived and deliberately has no roster.
  ];

  Future<void> _latency() => Future<void>.delayed(
        Duration(milliseconds: 260 + _rand.nextInt(320)),
      );

  /// A member's number identifies them inside their own detachment, so it has
  /// to be unique there. [exceptId] lets an edit keep its own number.
  bool _numberTaken(String detachmentId, String number, {String? exceptId}) =>
      _members.any((m) =>
          m.detachmentId == detachmentId &&
          m.personalNumber == number &&
          m.id != exceptId);

  @override
  Future<Result<List<TeamMember>>> listForDetachment(String detachmentId) async {
    await _latency();
    return Success(
      _members.where((m) => m.detachmentId == detachmentId).toList(),
    );
  }

  @override
  Future<Result<TeamMember>> byId(String memberId) async {
    await _latency();
    final i = _members.indexWhere((m) => m.id == memberId);
    if (i < 0) return const Failure('لم يُعثر على العضو.', code: 'not_found');
    return Success(_members[i]);
  }

  @override
  Future<Result<TeamMember>> create({
    required String detachmentId,
    required String name,
    required String department,
    required String personalNumber,
    required TeamRole role,
  }) async {
    await _latency();
    if (_numberTaken(detachmentId, personalNumber)) {
      return const Failure(
        'هذا الرقم مستخدم لعضو آخر في المفرزة.',
        code: 'number_taken',
      );
    }
    final member = TeamMember(
      id: 'm${_nextId++}',
      name: name,
      initials: TeamMember.initialsOf(name),
      department: department,
      personalNumber: personalNumber,
      role: role,
      detachmentId: detachmentId,
      // A member who has just been added has not been invited to anything
      // yet, so no attendance has been taken for them.
      attendance: AttendanceState.notInvited,
    );
    _members.add(member);
    return Success(member);
  }

  @override
  Future<Result<TeamMember>> update(TeamMember member) async {
    await _latency();
    final i = _members.indexWhere((m) => m.id == member.id);
    if (i < 0) return const Failure('لم يُعثر على العضو.', code: 'not_found');
    if (_numberTaken(member.detachmentId, member.personalNumber,
        exceptId: member.id)) {
      return const Failure(
        'هذا الرقم مستخدم لعضو آخر في المفرزة.',
        code: 'number_taken',
      );
    }
    _members[i] = member;
    return Success(member);
  }

  @override
  Future<Result<void>> delete(String memberId) async {
    await _latency();
    final i = _members.indexWhere((m) => m.id == memberId);
    if (i < 0) return const Failure('لم يُعثر على العضو.', code: 'not_found');
    _members.removeAt(i);
    return const Success(null);
  }

  @override
  Future<Result<TeamMember>> assignRole(String memberId, TeamRole role) async {
    await _latency();
    final i = _members.indexWhere((m) => m.id == memberId);
    if (i < 0) return const Failure('لم يُعثر على العضو.', code: 'not_found');
    _members[i] = _members[i].copyWith(role: role);
    return Success(_members[i]);
  }

  @override
  Future<Result<TeamMember>> setAttendance(
      String memberId, AttendanceState state) async {
    await _latency();
    final i = _members.indexWhere((m) => m.id == memberId);
    if (i < 0) return const Failure('لم يُعثر على العضو.', code: 'not_found');
    _members[i] = _members[i].copyWith(attendance: state);
    return Success(_members[i]);
  }
}
