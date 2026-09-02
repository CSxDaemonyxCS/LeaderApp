import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/capability.dart';
import '../../../../core/access/capability_guard.dart';
import '../../../../core/format/app_date.dart';
import '../../../../core/motion/animated_counter.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/motion/stagger.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_result.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/refresh_indicator.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/strings.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../../inventory/domain/inventory_models.dart';
import '../../../shell/main_shell.dart';

/// Stock held by one detachment.
///
/// Three filters, because the two questions anyone actually opens this screen
/// with are "what do I need to reorder" and "what is about to expire" — a
/// plain alphabetical list answers neither without reading every row.
class DetachmentStorageTab extends ConsumerStatefulWidget {
  const DetachmentStorageTab({super.key, required this.detachmentId});

  final String detachmentId;

  @override
  ConsumerState<DetachmentStorageTab> createState() => _StorageTabState();
}

enum _StockFilter { all, low, expiring }

class _StorageTabState extends ConsumerState<DetachmentStorageTab> {
  _StockFilter _filter = _StockFilter.all;
  String _query = '';

  String get detachmentId => widget.detachmentId;

  /// Thirty days is the reorder horizon used everywhere in this screen — the
  /// card's amber expiry text uses the same number, so the filter and the
  /// warning colour can never disagree.
  static const int _expiringWithinDays = 30;

  List<InventoryItem> _apply(List<InventoryItem> items) {
    Iterable<InventoryItem> out = items;
    if (_query.trim().isNotEmpty) {
      final q = _query.trim();
      out = out.where((i) => i.name.contains(q) || i.unit.contains(q));
    }
    out = switch (_filter) {
      _StockFilter.all => out,
      _StockFilter.low =>
        out.where((i) => i.level != StockLevel.ok),
      _StockFilter.expiring => out.where((i) {
          final d = i.daysToExpiry;
          return d != null && d <= _expiringWithinDays;
        }),
    };
    return out.toList();
  }

  @override
  Widget build(BuildContext context) {
    final canAdjust =
        ref.capabilities.canIn(detachmentId, Cap.inventoryAdjust);
    final onAdd = ref.whenCan(
      Cap.inventoryItemManage,
      () => context.push('/detachment/$detachmentId/storage/new'),
      detachmentId: detachmentId,
    );

    return AppRefreshIndicator(
      onRefresh: () => ref.refresh(inventoryListProvider(detachmentId).future),
      child: AsyncResultView<List<InventoryItem>>(
        value: ref.watch(inventoryListProvider(detachmentId)),
        onRetry: () => ref.invalidate(inventoryListProvider),
        builder: (context, all, stale) {
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: S.emptyInventory,
              body: S.emptyInventorySub,
              actionLabel: onAdd == null ? null : S.addItem,
              onAction: onAdd,
            );
          }
          final items = _apply(all);
          return FloatingNavPadding(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                  AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: S.searchItems,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // The add action keeps its place at the end of the row; the
                // three filters scroll under it, so a longer filter label
                // never pushes the one control that creates something off
                // the screen.
                Row(children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _Chip(
                          label: S.filterAll,
                          active: _filter == _StockFilter.all,
                          onTap: () =>
                              setState(() => _filter = _StockFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: S.filterLow,
                          active: _filter == _StockFilter.low,
                          onTap: () =>
                              setState(() => _filter = _StockFilter.low),
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: S.filterExpiring,
                          active: _filter == _StockFilter.expiring,
                          onTap: () => setState(
                              () => _filter = _StockFilter.expiring),
                        ),
                      ]),
                    ),
                  ),
                  if (onAdd != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _AddButton(onTap: onAdd),
                  ],
                ]),
                const SizedBox(height: AppSpacing.md),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxl),
                    child: Text(
                      S.noData,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: context.c.ink3, fontSize: 13),
                    ),
                  )
                else
                  for (int i = 0; i < items.length; i++) ...[
                    Stagger(
                      index: i,
                      child: _ItemCard(
                        item: items[i],
                        onTap: () =>
                            _itemSheet(context, ref, items[i], canAdjust),
                      ),
                    ),
                    if (i != items.length - 1) const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _itemSheet(BuildContext context, WidgetRef ref,
      InventoryItem item, bool canAdjust) async {
    await showAppSheet<void>(
      context: context,
      title: item.name,
      child: _ItemSheetBody(
        detachmentId: detachmentId,
        item: item,
        canAdjust: canAdjust,
      ),
    );
  }
}

StatusKind _kindFor(StockLevel level) => switch (level) {
      StockLevel.ok => StatusKind.ok,
      StockLevel.low => StatusKind.warn,
      StockLevel.empty => StatusKind.crit,
    };

String _labelFor(StockLevel level) => switch (level) {
      StockLevel.ok => S.stockOk,
      StockLevel.low => S.stockLowLabel,
      StockLevel.empty => S.stockEmpty,
    };

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onTap});

  final InventoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final days = item.daysToExpiry;
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(item.name,
                    style: TextStyle(
                        color: c.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ),
              StatusChip(
                  kind: _kindFor(item.level), label: _labelFor(item.level)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            // Three facts of unpredictable width — a quantity, a unit name,
            // and an expiry phrase. They wrap rather than compete for one
            // line, so a long unit ("أسطوانة") cannot clip the expiry
            // warning beside it.
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${toArabicIndic(item.currentStock.toString())} ${item.unit}',
                  style: AppTypography.digits(c.ink, size: 16),
                ),
                Text(
                  '${S.minimumLevel} ${toArabicIndic(item.minimum.toString())}',
                  style: TextStyle(color: c.ink3, fontSize: 12),
                ),
                Text(
                  item.expiresOn == null
                      ? S.noExpiry
                      : days != null && days < 0
                          ? S.expired
                          : '${toArabicIndic('${days ?? 0}')} ${S.daysToExpiry}',
                  style: TextStyle(
                    color: days != null &&
                            days <= _StorageTabState._expiringWithinDays
                        ? c.warn
                        : c.ink3,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemSheetBody extends ConsumerStatefulWidget {
  const _ItemSheetBody({
    required this.detachmentId,
    required this.item,
    required this.canAdjust,
  });

  final String detachmentId;
  final InventoryItem item;
  final bool canAdjust;

  @override
  ConsumerState<_ItemSheetBody> createState() => _ItemSheetBodyState();
}

class _ItemSheetBodyState extends ConsumerState<_ItemSheetBody> {
  final _quantity = TextEditingController();
  final _reason = TextEditingController();
  MovementDirection _direction = MovementDirection.outflow;
  bool _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final movements = ref.watch(inventoryMovementsProvider(widget.item.id));
    // Editing the item's definition is a different capability from moving its
    // stock: a medic logs a dispense, a lead decides what the detachment
    // stocks at all.
    final onEdit = ref.whenCan(
      Cap.inventoryItemManage,
      () {
        Navigator.of(context).pop();
        context.push(
          '/detachment/${widget.detachmentId}/storage/${widget.item.id}/edit',
        );
      },
      detachmentId: widget.detachmentId,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                '${S.currentStock}: '
                '${toArabicIndic('${widget.item.currentStock}')}'
                ' ${widget.item.unit}'
                ' · ${S.minimumLevel} '
                '${toArabicIndic('${widget.item.minimum}')}',
                style: TextStyle(color: c.ink3, fontSize: 12),
              ),
            ),
            if (onEdit != null)
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text(S.edit),
                style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          if (widget.canAdjust) ...[
            Row(children: [
              Expanded(
                child: _DirectionButton(
                  label: S.movementIn,
                  icon: Icons.south_west_rounded,
                  selected: _direction == MovementDirection.inflow,
                  onTap: () => setState(
                      () => _direction = MovementDirection.inflow),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DirectionButton(
                  label: S.movementOut,
                  icon: Icons.north_east_rounded,
                  selected: _direction == MovementDirection.outflow,
                  onTap: () => setState(
                      () => _direction = MovementDirection.outflow),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: S.quantity,
                hintText: S.quantityPlaceholder,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(
                labelText: S.reason,
                hintText: S.reasonPlaceholder,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _record,
                child: const Text(S.record),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(S.itemMovements,
              style: TextStyle(
                  color: c.ink3, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          AsyncResultView<List<InventoryMovement>>(
            value: movements,
            onRetry: () => ref.invalidate(inventoryMovementsProvider),
            loading: const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            builder: (context, list, stale) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg),
                    child: Text(S.noMovements,
                        style: TextStyle(color: c.ink3, fontSize: 13)),
                  )
                : Column(
                    children: [
                      for (final m in list) _MovementRow(movement: m),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _record() async {
    final qty = int.tryParse(_quantity.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(S.required)));
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(inventoryRepositoryProvider).addMovement(
          itemId: widget.item.id,
          direction: _direction,
          quantity: qty,
          reason: _reason.text.trim().isEmpty
              ? S.movementSheet
              : _reason.text.trim(),
        );
    ref.invalidate(inventoryListProvider);
    ref.invalidate(inventoryMovementsProvider);
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_, {stale = false}) => Navigator.of(context).pop(),
      failure: (message, _) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message))),
      offline: (_) => ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(S.offlineTitle))),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.primaryTint : c.surface,
          border: Border.all(color: selected ? c.primary : c.line),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: selected ? c.primary : c.ink2),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: selected ? c.primary : c.ink2,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement});

  final InventoryMovement movement;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final inflow = movement.direction == MovementDirection.inflow;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: inflow ? c.okTint : c.warnTint,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Icon(
            inflow ? Icons.south_west_rounded : Icons.north_east_rounded,
            size: 15,
            color: inflow ? c.ok : c.warn,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(movement.reason,
                  style: TextStyle(color: c.ink, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(AppDate.dayMonthTime(movement.at),
                  style: TextStyle(color: c.ink3, fontSize: 11)),
            ],
          ),
        ),
        Text(
          '${inflow ? '+' : '−'}${toArabicIndic(movement.quantity.toString())}',
          style: AppTypography.digits(inflow ? c.ok : c.warn, size: 14),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: active ? c.primary : c.surface,
          border: Border.all(color: active ? c.primary : c.line2),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? c.primaryInk : c.ink2,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 6, AppSpacing.md, 6),
        decoration: BoxDecoration(
          color: c.primaryTint,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.add_rounded, size: 17, color: c.primary),
          const SizedBox(width: 5),
          Text(S.addItem,
              style: TextStyle(
                  color: c.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
