import 'dart:math';

import '../../../core/result/result.dart';
import '../domain/inventory_models.dart';
import '../domain/inventory_repository.dart';

class MockInventoryRepository implements InventoryRepository {
  MockInventoryRepository();
  final _rand = Random(41);

  final List<InventoryItem> _items = [
    InventoryItem(
      id: 'i1', detachmentId: 'd_dam_central',
      name: 'أدرينالين ١ ملغ/مل', unit: 'أمبولة',
      currentStock: 4, minimum: 12,
      expiresOn: DateTime.now().add(const Duration(days: 22)),
      level: StockLevel.low,
    ),
    InventoryItem(
      id: 'i2', detachmentId: 'd_dam_central',
      name: 'باراسيتامول ٥٠٠ ملغ', unit: 'شريط',
      currentStock: 6, minimum: 20,
      expiresOn: DateTime.now().add(const Duration(days: 120)),
      level: StockLevel.low,
    ),
    const InventoryItem(
      id: 'i3', detachmentId: 'd_dam_central',
      name: 'شاش طبي ١٠سم', unit: 'رول',
      currentStock: 32, minimum: 15,
      expiresOn: null,
      level: StockLevel.ok,
    ),
    InventoryItem(
      id: 'i4', detachmentId: 'd_dam_central',
      name: 'سالبوتامول بخّاخ', unit: 'قطعة',
      currentStock: 0, minimum: 6,
      expiresOn: DateTime.now().add(const Duration(days: 10)),
      level: StockLevel.empty,
    ),
    InventoryItem(
      id: 'i5', detachmentId: 'd_dam_central',
      name: 'دِكستروز ٥٪', unit: 'كيس',
      currentStock: 24, minimum: 10,
      expiresOn: DateTime.now().add(const Duration(days: 300)),
      level: StockLevel.ok,
    ),
    const InventoryItem(
      id: 'i6', detachmentId: 'd_dam_rural',
      name: 'كمّامة N95', unit: 'قطعة',
      currentStock: 120, minimum: 30,
      expiresOn: null,
      level: StockLevel.ok,
    ),
  ];

  final List<InventoryMovement> _movements = [
    InventoryMovement(id: 'mv1', itemId: 'i1',
        direction: MovementDirection.outflow,
        quantity: 2, reason: 'طوارئ · ٢ أغسطس',
        at: DateTime.now().subtract(const Duration(days: 3))),
    InventoryMovement(id: 'mv2', itemId: 'i1',
        direction: MovementDirection.inflow,
        quantity: 6, reason: 'تسليم من المستودع المركزي',
        at: DateTime.now().subtract(const Duration(days: 10))),
    InventoryMovement(id: 'mv3', itemId: 'i2',
        direction: MovementDirection.outflow,
        quantity: 4, reason: 'صرف ورشة',
        at: DateTime.now().subtract(const Duration(days: 1))),
  ];

  Future<void> _latency() => Future<void>.delayed(
        Duration(milliseconds: 400 + _rand.nextInt(400)),
      );

  @override
  Future<Result<List<InventoryItem>>> listForDetachment(String detachmentId) async {
    await _latency();
    return Success(_items.where((i) => i.detachmentId == detachmentId).toList());
  }

  @override
  Future<Result<InventoryItem>> byId(String id) async {
    await _latency();
    final it = _items.firstWhere((e) => e.id == id, orElse: () => _items.first);
    return Success(it);
  }

  @override
  Future<Result<List<InventoryMovement>>> movementsForItem(String itemId) async {
    await _latency();
    return Success(_movements.where((m) => m.itemId == itemId).toList());
  }

  @override
  Future<Result<InventoryItem>> addMovement({
    required String itemId,
    required MovementDirection direction,
    required int quantity,
    required String reason,
  }) async {
    await _latency();
    final i = _items.indexWhere((e) => e.id == itemId);
    if (i < 0) return const Failure('لم يُعثر على الصنف.');
    final delta = direction == MovementDirection.inflow ? quantity : -quantity;
    final newStock = (_items[i].currentStock + delta).clamp(0, 99999);
    final level = newStock == 0
        ? StockLevel.empty
        : newStock < _items[i].minimum
            ? StockLevel.low
            : StockLevel.ok;
    _items[i] = _items[i].copyWith(currentStock: newStock, level: level);
    _movements.add(InventoryMovement(
      id: 'mv_${DateTime.now().millisecondsSinceEpoch}',
      itemId: itemId,
      direction: direction,
      quantity: quantity,
      reason: reason,
      at: DateTime.now(),
    ));
    return Success(_items[i]);
  }
}
