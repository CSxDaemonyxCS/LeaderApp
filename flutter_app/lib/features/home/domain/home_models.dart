import '../../shift/domain/shift_models.dart';

enum DecisionKind { unfilledShift, expiringStock, joinRequest }

class HomeDecisionItem {
  const HomeDecisionItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });

  final String id;
  final DecisionKind kind;
  final String title;
  final String subtitle;
  final String actionLabel;

  factory HomeDecisionItem.fromJson(Map<String, dynamic> j) => HomeDecisionItem(
        id: j['id'] as String,
        kind: DecisionKind.values.firstWhere((k) => k.name == j['kind']),
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        actionLabel: j['actionLabel'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'subtitle': subtitle,
        'actionLabel': actionLabel,
      };
}

class HomeSummary {
  const HomeSummary({
    required this.detachmentName,
    required this.centerName,
    required this.activeShift,
    required this.lockRemaining,
    required this.attendancePresent,
    required this.attendanceTotal,
    required this.decisions,
    required this.workshopsThisWeek,
    required this.attendanceRatePercent,
    required this.stockLowCount,
  });

  final String detachmentName;
  final String centerName;
  final Shift? activeShift;
  final Duration? lockRemaining;
  final int attendancePresent;
  final int attendanceTotal;
  final List<HomeDecisionItem> decisions;
  final int workshopsThisWeek;
  final int attendanceRatePercent;
  final int stockLowCount;

  factory HomeSummary.fromJson(Map<String, dynamic> j) => HomeSummary(
        detachmentName: j['detachmentName'] as String,
        centerName: j['centerName'] as String,
        activeShift: j['activeShift'] == null
            ? null
            : Shift.fromJson(j['activeShift'] as Map<String, dynamic>),
        lockRemaining: j['lockRemainingSec'] == null
            ? null
            : Duration(seconds: j['lockRemainingSec'] as int),
        attendancePresent: j['attendancePresent'] as int,
        attendanceTotal: j['attendanceTotal'] as int,
        decisions: (j['decisions'] as List)
            .map((e) => HomeDecisionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        workshopsThisWeek: j['workshopsThisWeek'] as int,
        attendanceRatePercent: j['attendanceRatePercent'] as int,
        stockLowCount: j['stockLowCount'] as int,
      );

  Map<String, dynamic> toJson() => {
        'detachmentName': detachmentName,
        'centerName': centerName,
        if (activeShift != null) 'activeShift': activeShift!.toJson(),
        if (lockRemaining != null)
          'lockRemainingSec': lockRemaining!.inSeconds,
        'attendancePresent': attendancePresent,
        'attendanceTotal': attendanceTotal,
        'decisions': decisions.map((d) => d.toJson()).toList(),
        'workshopsThisWeek': workshopsThisWeek,
        'attendanceRatePercent': attendanceRatePercent,
        'stockLowCount': stockLowCount,
      };
}
