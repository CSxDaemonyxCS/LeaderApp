import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../domain/detachment_models.dart';
import '../domain/detachment_repository.dart';
import 'mock_detachment_repository.dart';

final detachmentRepositoryProvider = Provider<DetachmentRepository>((ref) {
  return MockDetachmentRepository();
});

class DetachmentListQuery {
  const DetachmentListQuery({this.filter, this.query});
  final DetachmentStatus? filter;
  final String? query;
}

final detachmentListProvider =
    FutureProvider.family<Result<List<Detachment>>, DetachmentListQuery>(
        (ref, q) async {
  return ref.read(detachmentRepositoryProvider).list(
        filter: q.filter,
        query: q.query,
      );
});

final detachmentByIdProvider =
    FutureProvider.family<Result<Detachment>, String>((ref, id) async {
  return ref.read(detachmentRepositoryProvider).byId(id);
});

final detachmentStatsProvider =
    FutureProvider.family<Result<DetachmentStats>, String>((ref, id) async {
  return ref.read(detachmentRepositoryProvider).stats(id);
});
