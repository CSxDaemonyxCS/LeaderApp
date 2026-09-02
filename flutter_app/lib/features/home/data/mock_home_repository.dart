import 'dart:math';

import '../../../core/result/result.dart';
import '../../shift/domain/shift_models.dart';
import '../../team/domain/team_models.dart';
import '../domain/home_models.dart';
import '../domain/home_repository.dart';

/// The Home summary for the signed-in user's active detachment.
///
/// ASSUMPTION: with open decision #6 (Home with several detachments) still
/// unruled, the mock reports a single active detachment — `d_dam_central`.
///
/// Every figure below is consistent with the other mocks: the active shift is
/// `sh2` from `MockShiftRepository`, the three decisions point at real records
/// (`sh3`, item `i4`), the low-stock count is d_dam_central's low + empty
/// lines, and the attendance rate is the last day of that detachment's series.
class MockHomeRepository implements HomeRepository {
  MockHomeRepository();

  final _rand = Random(61);

  Future<void> _latency() => Future<void>.delayed(
        Duration(milliseconds: 320 + _rand.nextInt(300)),
      );

  @override
  Future<Result<HomeSummary>> summary() async {
    await _latency();
    return Success(HomeSummary(
      detachmentName: 'مفرزة دمشق المركزية',
      centerName: 'مركز الشعلان',
      activeShift: Shift(
        id: 'sh2',
        detachmentId: 'd_dam_central',
        // The evening shift of the current day, so Home always has a live
        // shift to show whenever the app is opened.
        date: dateOnly(DateTime.now()),
        centerName: 'مركز الشعلان',
        startMinutes: 14 * 60,
        endMinutes: 20 * 60,
        needed: 10,
        attendees: const [
          TeamMember(id: 'm1', name: 'أحمد كنعان', initials: 'أك',
              role: TeamRole.lead, detachmentId: 'd_dam_central',
              attendance: AttendanceState.present),
          TeamMember(id: 'm3', name: 'سامي درويش', initials: 'سد',
              role: TeamRole.medic, detachmentId: 'd_dam_central',
              attendance: AttendanceState.late),
          TeamMember(id: 'm5', name: 'ياسر البكري', initials: 'يب',
              role: TeamRole.volunteer, detachmentId: 'd_dam_central',
              attendance: AttendanceState.absent),
          TeamMember(id: 'm8', name: 'دانا عمر', initials: 'دع',
              role: TeamRole.medic, detachmentId: 'd_dam_central',
              attendance: AttendanceState.present),
        ],
      ),
      lockRemaining: const Duration(minutes: 47, seconds: 12),
      attendancePresent: 5,
      attendanceTotal: 7,
      decisions: const [
        HomeDecisionItem(id: 'dec1', kind: DecisionKind.unfilledShift,
            title: 'شفت ٢٠–٠٢ · المهاجرين',
            subtitle: 'تحتاج ٣ متطوعين لسدّ التغطية',
            actionLabel: 'إسناد'),
        HomeDecisionItem(id: 'dec2', kind: DecisionKind.expiringStock,
            title: 'سالبوتامول بخّاخ',
            subtitle: 'تنتهي خلال ١٠ أيام · المخزون صفر',
            actionLabel: 'مراجعة'),
        HomeDecisionItem(id: 'dec3', kind: DecisionKind.joinRequest,
            title: 'طلب انضمام · مهند سعدون',
            subtitle: 'مقدَّم قبل ٣ ساعات',
            actionLabel: 'قرار'),
      ],
      workshopsThisWeek: 3,
      attendanceRatePercent: 90,
      stockLowCount: 3,
    ));
  }
}
