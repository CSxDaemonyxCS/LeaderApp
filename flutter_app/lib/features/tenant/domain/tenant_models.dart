/// A tenant is the umbrella a group of detachments belongs to — one branch,
/// one organisation, one operating area. Several detachments in the same
/// place, run by the same people, under one name.
///
/// Deliberately thin: creating one asks for a name and nothing else. Every
/// operational field lives on the detachments inside it, because that is
/// where the work happens.
enum TenantStatus { active, archived }

class Tenant {
  const Tenant({
    required this.id,
    required this.name,
    required this.createdAt,
    this.notes,
    this.status = TenantStatus.active,
    this.detachmentCount = 0,
    this.memberCount = 0,
    this.coveragePercent = 0,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String? notes;
  final TenantStatus status;

  /// The three roll-ups shown on the tenant card. They are **derived**, not
  /// stored: `MockTenantRepository` recomputes them from the detachments it
  /// is handed on every read, so a card can never show a count that the list
  /// underneath it disagrees with.
  final int detachmentCount;
  final int memberCount;
  final int coveragePercent;

  Tenant copyWith({
    String? name,
    String? notes,
    TenantStatus? status,
    int? detachmentCount,
    int? memberCount,
    int? coveragePercent,
  }) =>
      Tenant(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        notes: notes ?? this.notes,
        status: status ?? this.status,
        detachmentCount: detachmentCount ?? this.detachmentCount,
        memberCount: memberCount ?? this.memberCount,
        coveragePercent: coveragePercent ?? this.coveragePercent,
      );

  factory Tenant.fromJson(Map<String, dynamic> j) => Tenant(
        id: j['id'] as String,
        name: j['name'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        notes: j['notes'] as String?,
        status: TenantStatus.values.firstWhere((s) => s.name == j['status']),
        detachmentCount: (j['detachmentCount'] as int?) ?? 0,
        memberCount: (j['memberCount'] as int?) ?? 0,
        coveragePercent: (j['coveragePercent'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        if (notes != null) 'notes': notes,
        'status': status.name,
        'detachmentCount': detachmentCount,
        'memberCount': memberCount,
        'coveragePercent': coveragePercent,
      };
}
