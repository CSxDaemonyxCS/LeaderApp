import 'dart:math';

import '../../../core/result/result.dart';
import '../../shift/domain/shift_models.dart';
import '../../team/domain/team_models.dart';
import '../domain/home_models.dart';
import '../domain/home_repository.dart';

class MockHomeRepository implements HomeRepository {
  MockHomeRepository();
  final _rand = Random(61);

  Future<void> _latency() => Future<void>.delayed(
        Duration(milliseconds: 400 + _rand.nextInt(400)),
      );

  @override
  Future<Result<HomeSummary>> summary() async {
    await _latency();
    return const Success(HomeSummary(
      detachmentName: 'مفرزة دمشق المركزية',
      centerName: 'مركز الشعلان',
      activeShift: Shift(
        id: 'sh2',
        detachmentId: 'd_dam_central',
        centerName: 'مركز الشعلان',
        startHour: 14,
        endHour: 20,
        assigned: 7, needed: 10, hasCoverageGap: true,
        attendees: [
          TeamMember(id: 'm1', name: 'أحمد كنعان', initials: 'أك',
              role: TeamRole.lead, detachmentId: 'd_dam_central',
              attendance: AttendanceState.present),
        ],
      ),
      lockRemaining: Duration(minutes: 47, seconds: 12),
      attendancePresent: 7,
      attendanceTotal: 10,
      decisions: [
        HomeDecisionItem(id: 'dec1', kind: DecisionKind.unfilledShift,
            title: 'شفت ٢٠–٠٢ · المهاجرين',
            subtitle: 'تحتاج ٣ متطوعين لسدّ التغطية',
            actionLabel: 'إسناد'),
        HomeDecisionItem(id: 'dec2', kind: DecisionKind.expiringStock,
            title: 'سالبوتامول بخّاخ',
            subtitle: 'تنتهي خلال ١٠ أيام · ٦ قطع',
            actionLabel: 'مراجعة'),
        HomeDecisionItem(id: 'dec3', kind: DecisionKind.joinRequest,
            title: 'طلب انضمام · مهند سعدون',
            subtitle: 'مقدَّم قبل ٣ ساعات',
            actionLabel: 'قرار'),
      ],
      workshopsThisWeek: 2,
      attendanceRatePercent: 91,
      stockLowCount: 6,
    ));
  }
}
