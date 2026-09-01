import '../../../core/result/result.dart';
import 'inventory_models.dart';

abstract class InventoryRepository {
  Future<Result<List<InventoryItem>>> listForDetachment(String detachmentId);
  Future<Result<InventoryItem>> byId(String id);
  Future<Result<List<InventoryMovement>>> movementsForItem(String itemId);
  Future<Result<InventoryItem>> addMovement({
    required String itemId,
    required MovementDirection direction,
    required int quantity,
    required String reason,
  });
}
