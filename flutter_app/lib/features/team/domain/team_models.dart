enum TeamRole { lead, medic, trainee, volunteer }

enum AttendanceState { present, late, absent, notInvited }

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.initials,
    this.department = '',
    this.personalNumber = '',
    required this.role,
    required this.detachmentId,
    required this.attendance,
    this.phoneMasked,
  });

  final String id;
  final String name;

  /// Monogram shown on the roster avatar. Derived from [name] by
  /// [initialsOf] — never typed by hand, so it can never drift from the name
  /// after a rename.
  final String initials;

  /// The member's section inside the detachment ("الإسعاف", "اللوجستيات").
  /// Free text on purpose: the set of sections differs per detachment and no
  /// fixed list has been ruled on.
  ///
  /// Empty outside a detachment roster. `TeamMember` doubles as the
  /// projection of a person into a shift's attendee list and a workshop's
  /// organising team, and neither of those carries a roster record — see
  /// `MockShiftRepository` and `MockWorkshopRepository`. Only
  /// [TeamRepository.create] can mint a roster member, and it requires both
  /// this and [personalNumber].
  final String department;

  /// The number the member picks for themselves. Kept as a string so a
  /// leading zero survives, and unique inside one detachment — see
  /// `MockTeamRepository`. Empty in the same projections as [department].
  final String personalNumber;

  final TeamRole role;
  final String detachmentId;
  final AttendanceState attendance;
  final String? phoneMasked;

  /// First letter of the first two words. Arabic has no case, so this is the
  /// whole rule; a single-word name yields one letter rather than a padded
  /// two.
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words
        .take(2)
        .map((w) => String.fromCharCode(w.runes.first))
        .join();
  }

  TeamMember copyWith({
    String? name,
    String? department,
    String? personalNumber,
    TeamRole? role,
    AttendanceState? attendance,
  }) =>
      TeamMember(
        id: id,
        name: name ?? this.name,
        initials: name == null ? initials : initialsOf(name),
        department: department ?? this.department,
        personalNumber: personalNumber ?? this.personalNumber,
        role: role ?? this.role,
        detachmentId: detachmentId,
        attendance: attendance ?? this.attendance,
        phoneMasked: phoneMasked,
      );

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
        id: j['id'] as String,
        name: j['name'] as String,
        initials: j['initials'] as String,
        department: j['department'] as String,
        personalNumber: j['personalNumber'] as String,
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
        'department': department,
        'personalNumber': personalNumber,
        'role': role.name,
        'detachmentId': detachmentId,
        'attendance': attendance.name,
        if (phoneMasked != null) 'phoneMasked': phoneMasked,
      };
}
