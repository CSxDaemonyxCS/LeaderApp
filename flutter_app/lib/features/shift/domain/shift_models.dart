import '../../team/domain/team_models.dart';

class Shift {
  const Shift({
    required this.id,
    required this.detachmentId,
    required this.centerName,
    required this.startHour,
    required this.endHour,
    required this.assigned,
    required this.needed,
    required this.hasCoverageGap,
    required this.attendees,
  });

  final String id;
  final String detachmentId;
  final String centerName;
  final int startHour;
  final int endHour;
  final int assigned;
  final int needed;
  final bool hasCoverageGap;
  final List<TeamMember> attendees;

  int get gap => (needed - assigned).clamp(0, needed);

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
        id: j['id'] as String,
        detachmentId: j['detachmentId'] as String,
        centerName: j['centerName'] as String,
        startHour: j['startHour'] as int,
        endHour: j['endHour'] as int,
        assigned: j['assigned'] as int,
        needed: j['needed'] as int,
        hasCoverageGap: j['hasCoverageGap'] as bool,
        attendees: (j['attendees'] as List)
            .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'detachmentId': detachmentId,
        'centerName': centerName,
        'startHour': startHour,
        'endHour': endHour,
        'assigned': assigned,
        'needed': needed,
        'hasCoverageGap': hasCoverageGap,
        'attendees': attendees.map((a) => a.toJson()).toList(),
      };
}
