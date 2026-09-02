import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../../detachment/data/detachment_providers.dart';
import '../domain/tenant_models.dart';
import '../domain/tenant_repository.dart';
import 'mock_tenant_repository.dart';

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  // Counts on a tenant card are read from the detachment repository, never
  // stored twice — see `MockTenantRepository`.
  return MockTenantRepository(ref.watch(detachmentRepositoryProvider));
});

/// The tenant list, optionally filtered by a search string.
final tenantListProvider =
    FutureProvider.autoDispose.family<Result<List<Tenant>>, String>(
        (ref, query) async {
  return ref.read(tenantRepositoryProvider).list(query: query);
});

final tenantByIdProvider =
    FutureProvider.autoDispose.family<Result<Tenant>, String>((ref, id) async {
  return ref.read(tenantRepositoryProvider).byId(id);
});
