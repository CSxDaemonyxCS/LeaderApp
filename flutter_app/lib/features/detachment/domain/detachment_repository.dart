import '../../../core/result/result.dart';
import 'detachment_models.dart';

abstract class DetachmentRepository {
  /// [tenantId] scopes the list to one tenant. Passing null lists every
  /// detachment the session can see, which is what the unscoped list screen
  /// and the tenant roll-ups both want.
  Future<Result<List<Detachment>>> list({
    String? tenantId,
    DetachmentStatus? filter,
    String? query,
  });

  Future<Result<Detachment>> byId(String id);

  Future<Result<Detachment>> create({
    required String tenantId,
    required String name,
    required String region,
    required String mainCenter,
    String? notes,
  });

  Future<Result<Detachment>> update(Detachment d);

  /// Removes one detachment. Its members, shifts, and stock go with it — they
  /// have no meaning outside the container.
  Future<Result<void>> delete(String id);

  /// Cascade used when a whole tenant is deleted. Returns how many
  /// detachments were removed.
  Future<Result<int>> deleteAllInTenant(String tenantId);

  Future<Result<DetachmentStats>> stats(String id);
}
