import '../../../core/result/result.dart';
import 'tenant_models.dart';

abstract class TenantRepository {
  Future<Result<List<Tenant>>> list({String? query});

  Future<Result<Tenant>> byId(String id);

  /// A name is the whole form. Everything else is optional.
  Future<Result<Tenant>> create({required String name, String? notes});

  Future<Result<Tenant>> update(Tenant tenant);

  /// Removes the tenant **and everything inside it**. The caller has already
  /// confirmed; the repository does not ask again.
  Future<Result<void>> delete(String id);
}
