import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../domain/detachment_models.dart';
import '../domain/detachment_repository.dart';
import 'mock_detachment_repository.dart';

final detachmentRepositoryProvider = Provider<DetachmentRepository>((ref) {
  return MockDetachmentRepository();
});

/// Cache key for one detachment list.
///
/// A record-shaped key rather than three loose arguments: Dart gives records
/// value equality for free, so two tenants can never collide on one cache
/// entry (`DETACHMENT-SCOPING.md` §2, rule 1).
class DetachmentListQuery {
  const DetachmentListQuery({this.tenantId, this.filter, this.query});

  final String? tenantId;
  final DetachmentStatus? filter;
  final String? query;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetachmentListQuery &&
          other.tenantId == tenantId &&
          other.filter == filter &&
          other.query == query;

  @override
  int get hashCode => Object.hash(tenantId, filter, query);
}

/// `autoDispose` on purpose — rule 2. Leaving a tenant drops its list, so
/// coming back re-enters the loading state and refetches instead of showing
/// what was true minutes ago.
final detachmentListProvider = FutureProvider.autoDispose
    .family<Result<List<Detachment>>, DetachmentListQuery>((ref, q) async {
  return ref.read(detachmentRepositoryProvider).list(
        tenantId: q.tenantId,
        filter: q.filter,
        query: q.query,
      );
});

final detachmentByIdProvider = FutureProvider.autoDispose
    .family<Result<Detachment>, String>((ref, id) async {
  return ref.read(detachmentRepositoryProvider).byId(id);
});

final detachmentStatsProvider = FutureProvider.autoDispose
    .family<Result<DetachmentStats>, String>((ref, id) async {
  return ref.read(detachmentRepositoryProvider).stats(id);
});
