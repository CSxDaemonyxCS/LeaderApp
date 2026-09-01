import '../../../core/result/result.dart';
import 'detachment_models.dart';

abstract class DetachmentRepository {
  Future<Result<List<Detachment>>> list({
    DetachmentStatus? filter,
    String? query,
  });

  Future<Result<Detachment>> byId(String id);

  Future<Result<Detachment>> create({
    required String name,
    required String region,
    required String mainCenter,
    String? notes,
  });

  Future<Result<Detachment>> update(Detachment d);

  Future<Result<DetachmentStats>> stats(String id);
}
