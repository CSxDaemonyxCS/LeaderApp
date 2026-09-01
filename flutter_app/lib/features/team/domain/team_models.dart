enum TeamRole { lead, medic, trainee, volunteer }

enum AttendanceState { present, late, absent, notInvited }

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.initials,
    required this.role,
    required this.detachmentId,
    required this.attendance,
    this.phoneMasked,
  });

  final String id;
  final String name;
  final String initials;
  final TeamRole role;
  final String detachmentId;
  final AttendanceState attendance;
  final String? phoneMasked;

  TeamMember copyWith({TeamRole? role, AttendanceState? attendance}) =>
      TeamMember(
        id: id,
        name: name,
        initials: initials,
        role: role ?? this.role,
        detachmentId: detachmentId,
        attendance: attendance ?? this.attendance,
        phoneMasked: phoneMasked,
      );

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
        id: j['id'] as String,
        name: j['name'] as String,
        initials: j['initials'] as String,
        role: TeamRole.values.firstWhere((r) => r.name == j['role']),
        detachmentId: j['detachmentId'] as String,
        attendance: AttendanceState.values
            .firstWhere((a) => a.name == j['attendance']),
        phoneMasked: j['phoneMasked'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initials': initials,
        'role': role.name,
        'detachmentId': detachmentId,
        'attendance': attendance.name,
        if (phoneMasked != null) 'phoneMasked': phoneMasked,
      };
}
