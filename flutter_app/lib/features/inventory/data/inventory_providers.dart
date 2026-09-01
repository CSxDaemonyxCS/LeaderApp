import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../domain/inventory_models.dart';
import '../domain/inventory_repository.dart';
import 'mock_inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return MockInventoryRepository();
});

final inventoryListProvider =
    FutureProvider.family<Result<List<InventoryItem>>, String>(
        (ref, detId) async {
  return ref.read(inventoryRepositoryProvider).listForDetachment(detId);
});

final inventoryItemProvider =
    FutureProvider.family<Result<InventoryItem>, String>((ref, id) async {
  return ref.read(inventoryRepositoryProvider).byId(id);
});

final inventoryMovementsProvider =
    FutureProvider.family<Result<List<InventoryMovement>>, String>(
        (ref, itemId) async {
  return ref.read(inventoryRepositoryProvider).movementsForItem(itemId);
});
