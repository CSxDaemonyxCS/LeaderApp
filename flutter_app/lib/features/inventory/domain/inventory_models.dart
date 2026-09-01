enum StockLevel { ok, low, empty }

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.detachmentId,
    required this.name,
    required this.unit,
    required this.currentStock,
    required this.minimum,
    required this.expiresOn,
    required this.level,
  });

  final String id;
  final String detachmentId;
  final String name;
  final String unit;
  final int currentStock;
  final int minimum;
  final DateTime? expiresOn;
  final StockLevel level;

  int? get daysToExpiry =>
      expiresOn?.difference(DateTime.now()).inDays;

  bool get belowMinimum => currentStock < minimum;

  InventoryItem copyWith({int? currentStock, StockLevel? level}) => InventoryItem(
        id: id,
        detachmentId: detachmentId,
        name: name,
        unit: unit,
        currentStock: currentStock ?? this.currentStock,
        minimum: minimum,
        expiresOn: expiresOn,
        level: level ?? this.level,
      );

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
        id: j['id'] as String,
        detachmentId: j['detachmentId'] as String,
        name: j['name'] as String,
        unit: j['unit'] as String,
        currentStock: j['currentStock'] as int,
        minimum: j['minimum'] as int,
        expiresOn: j['expiresOn'] == null
            ? null
            : DateTime.parse(j['expiresOn'] as String),
        level: StockLevel.values.firstWhere((l) => l.name == j['level']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'detachmentId': detachmentId,
        'name': name,
        'unit': unit,
        'currentStock': currentStock,
        'minimum': minimum,
        if (expiresOn != null) 'expiresOn': expiresOn!.toIso8601String(),
        'level': level.name,
      };
}

enum MovementDirection { inflow, outflow }

class InventoryMovement {
  const InventoryMovement({
    required this.id,
    required this.itemId,
    required this.direction,
    required this.quantity,
    required this.reason,
    required this.at,
  });

  final String id;
  final String itemId;
  final MovementDirection direction;
  final int quantity;
  final String reason;
  final DateTime at;

  factory InventoryMovement.fromJson(Map<String, dynamic> j) =>
      InventoryMovement(
        id: j['id'] as String,
        itemId: j['itemId'] as String,
        direction: MovementDirection.values
            .firstWhere((d) => d.name == j['direction']),
        quantity: j['quantity'] as int,
        reason: j['reason'] as String,
        at: DateTime.parse(j['at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'direction': direction.name,
        'quantity': quantity,
        'reason': reason,
        'at': at.toIso8601String(),
      };
}
