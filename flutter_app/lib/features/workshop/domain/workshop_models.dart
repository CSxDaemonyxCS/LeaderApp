import '../../team/domain/team_models.dart';

enum WorkshopStatus { scheduled, ongoing, done }

/// Whether a person has paid the workshop's registration fee.
///
/// Deliberately used as a *nullable* type everywhere: `null` is a third,
/// meaningful state — "not recorded yet" — and it is the state most people
/// are in before the door opens. Collapsing it into `unpaid` would turn a
/// missing record into an accusation.
enum PaymentStatus { paid, unpaid }

class Workshop {
  const Workshop({
    required this.id,
    required this.name,
    required this.at,
    required this.location,
    required this.capacity,
    required this.registered,
    required this.guests,
    required this.status,
    required this.organizingTeam,
    this.registrationFee = 0,
  });

  final String id;
  final String name;
  final DateTime at;
  final String location;
  final int capacity;
  final int registered;
  final int guests;
  final WorkshopStatus status;
  final List<TeamMember> organizingTeam;

  /// What one seat costs. `0` means the workshop is free, and the statistics
  /// screen says so instead of printing a zero total.
  final double registrationFee;

  bool get isFull => registered >= capacity;

  Workshop copyWith({
    String? name,
    DateTime? at,
    String? location,
    int? capacity,
    int? registered,
    int? guests,
    WorkshopStatus? status,
    double? registrationFee,
  }) =>
      Workshop(
        id: id,
        name: name ?? this.name,
        at: at ?? this.at,
        location: location ?? this.location,
        capacity: capacity ?? this.capacity,
        registered: registered ?? this.registered,
        guests: guests ?? this.guests,
        status: status ?? this.status,
        organizingTeam: organizingTeam,
        registrationFee: registrationFee ?? this.registrationFee,
      );

  factory Workshop.fromJson(Map<String, dynamic> j) => Workshop(
        id: j['id'] as String,
        name: j['name'] as String,
        at: DateTime.parse(j['at'] as String),
        location: j['location'] as String,
        capacity: j['capacity'] as int,
        registered: j['registered'] as int,
        guests: j['guests'] as int,
        status: WorkshopStatus.values.firstWhere((s) => s.name == j['status']),
        organizingTeam: (j['organizingTeam'] as List)
            .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
            .toList(),
        registrationFee: (j['registrationFee'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'at': at.toIso8601String(),
        'location': location,
        'capacity': capacity,
        'registered': registered,
        'guests': guests,
        'status': status.name,
        'organizingTeam': organizingTeam.map((t) => t.toJson()).toList(),
        'registrationFee': registrationFee,
      };
}

enum ParticipantKind { member, guest }

class WorkshopParticipant {
  const WorkshopParticipant({
    required this.id,
    required this.workshopId,
    required this.name,
    required this.initials,
    required this.kind,
    required this.attendance,
    this.paymentStatus,
  });

  final String id;
  final String workshopId;
  final String name;
  final String initials;
  final ParticipantKind kind;
  final AttendanceState attendance;

  /// `null` until somebody records it — see [PaymentStatus].
  final PaymentStatus? paymentStatus;

  WorkshopParticipant copyWith({
    AttendanceState? attendance,
    PaymentStatus? paymentStatus,
  }) =>
      WorkshopParticipant(
        id: id,
        workshopId: workshopId,
        name: name,
        initials: initials,
        kind: kind,
        attendance: attendance ?? this.attendance,
        paymentStatus: paymentStatus ?? this.paymentStatus,
      );

  factory WorkshopParticipant.fromJson(Map<String, dynamic> j) =>
      WorkshopParticipant(
        id: j['id'] as String,
        workshopId: j['workshopId'] as String,
        name: j['name'] as String,
        initials: j['initials'] as String,
        kind: ParticipantKind.values.firstWhere((k) => k.name == j['kind']),
        attendance: attendanceStateFromWire(
          (j['attendance'] as String?) ?? 'notCheckedIn',
        ),
        paymentStatus: switch (j['paymentStatus'] as String?) {
          'paid' => PaymentStatus.paid,
          'unpaid' => PaymentStatus.unpaid,
          _ => null,
        },
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workshopId': workshopId,
        'name': name,
        'initials': initials,
        'kind': kind.name,
        'attendance': attendance.name,
        if (paymentStatus != null) 'paymentStatus': paymentStatus!.name,
      };
}
