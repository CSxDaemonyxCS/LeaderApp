import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date.dart';
import '../../../core/motion/animated_counter.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/motion/press_scale.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sheet_scaffold.dart';
import '../../../l10n/strings.dart';
import '../data/shift_providers.dart';
import '../domain/shift_models.dart';

/// Create or edit one shift.
///
/// The whole design of this sheet is one decision: **nobody should have to
/// operate a time picker to schedule an ordinary shift.** Three presets cover
/// what a detachment actually runs, so the common case is two taps — pick the
/// period, save. The custom row is there for the exception, not the rule, and
/// the number of people needed is a stepper rather than a keyboard field
/// because it is always a small number and always adjusted by one.
Future<bool> showShiftEditor({
  required BuildContext context,
  required String detachmentId,
  required DateTime date,
  required String defaultCenter,
  Shift? existing,
}) async {
  final saved = await showAppSheet<bool>(
    context: context,
    title: existing == null
        ? '${S.addShift} · ${AppDate.weekdayOf(date)}'
        : S.editShift,
    child: _ShiftEditor(
      detachmentId: detachmentId,
      date: date,
      defaultCenter: defaultCenter,
      existing: existing,
    ),
  );
  return saved ?? false;
}

class _ShiftEditor extends ConsumerStatefulWidget {
  const _ShiftEditor({
    required this.detachmentId,
    required this.date,
    required this.defaultCenter,
    this.existing,
  });

  final String detachmentId;
  final DateTime date;
  final String defaultCenter;
  final Shift? existing;

  @override
  ConsumerState<_ShiftEditor> createState() => _ShiftEditorState();
}

class _ShiftEditorState extends ConsumerState<_ShiftEditor> {
  late final TextEditingController _center;
  late ShiftPeriod _period;
  late int _start;
  late int _end;
  late int _needed;
  bool _repeat = false;
  bool _busy = false;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _center = TextEditingController(text: e?.centerName ?? widget.defaultCenter);
    // A new shift opens on the morning preset rather than on an empty form.
    // A default that is right most of the time is the difference between
    // "fill this in" and "confirm this".
    _period = e == null ? ShiftPeriod.morning : e.period;
    final times = _period.times;
    _start = e?.startMinutes ?? times!.$1;
    _end = e?.endMinutes ?? times!.$2;
    _needed = e?.needed ?? 6;
  }

  @override
  void dispose() {
    _center.dispose();
    super.dispose();
  }

  void _pickPeriod(ShiftPeriod p) {
    setState(() {
      _period = p;
      final t = p.times;
      if (t != null) {
        _start = t.$1;
        _end = t.$2;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      final minutes = picked.hour * 60 + picked.minute;
      if (isStart) {
        _start = minutes;
      } else {
        _end = minutes;
      }
      // Editing a time by hand is what makes a shift custom. Saying so keeps
      // the preset row honest instead of leaving "morning" selected next to
      // 09:15.
      _period = ShiftPeriodTimes.match(_start, _end);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final crosses = _end <= _start;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isNew) ...[
            Row(children: [
              Icon(Icons.lightbulb_outline_rounded, size: 15, color: c.ink3),
              const SizedBox(width: 8),
              Expanded(
                child: Text(S.guideAddShift,
                    style:
                        TextStyle(color: c.ink3, fontSize: 12, height: 1.5)),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
          ],

          const _Label(S.shiftPeriod),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            for (final p in ShiftPeriod.values) ...[
              Expanded(
                child: _PeriodTile(
                  period: p,
                  selected: _period == p,
                  onTap: () => _pickPeriod(p),
                ),
              ),
              if (p != ShiftPeriod.values.last) const SizedBox(width: 6),
            ],
          ]),

          const SizedBox(height: AppSpacing.lg),
          Row(children: [
            Expanded(
              child: _TimeField(
                label: S.shiftStart,
                value: AppDate.hm(_start),
                onTap: () => _pickTime(isStart: true),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TimeField(
                label: S.shiftEnd,
                value: AppDate.hm(_end),
                onTap: () => _pickTime(isStart: false),
              ),
            ),
          ]),
          if (crosses) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Icon(Icons.nightlight_round, size: 14, color: c.info),
              const SizedBox(width: 6),
              Text(S.crossesMidnight,
                  style: TextStyle(color: c.info, fontSize: 12)),
            ]),
          ],

          const SizedBox(height: AppSpacing.lg),
          const _Label(S.shiftCenter),
          const SizedBox(height: 6),
          TextField(
            controller: _center,
            decoration:
                const InputDecoration(hintText: S.detachmentCenterPlaceholder),
          ),

          const SizedBox(height: AppSpacing.lg),
          const _Label(S.shiftNeededLabel),
          const SizedBox(height: 6),
          _Stepper(
            value: _needed,
            min: 1,
            max: 40,
            onChanged: (v) => setState(() => _needed = v),
          ),
          const SizedBox(height: 6),
          Text(S.shiftNeededHelp,
              style: TextStyle(color: c.ink3, fontSize: 12, height: 1.5)),

          if (_isNew) ...[
            const SizedBox(height: AppSpacing.lg),
            _RepeatSwitch(
              value: _repeat,
              weekday: widget.date.weekday,
              onChanged: (v) => setState(() => _repeat = v),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_isNew ? S.addShift : S.saveChanges),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_start == _end) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(S.startAfterEnd)));
      return;
    }
    setState(() => _busy = true);
    final repo = ref.read(shiftRepositoryProvider);
    final result = _isNew
        ? await repo.create(
            detachmentId: widget.detachmentId,
            date: widget.date,
            centerName: _center.text.trim(),
            startMinutes: _start,
            endMinutes: _end,
            needed: _needed,
            repeatWeekly: _repeat,
          )
        : await repo.update(widget.existing!.copyWith(
            centerName: _center.text.trim(),
            startMinutes: _start,
            endMinutes: _end,
            needed: _needed,
          ));

    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_, {stale = false}) {
        ref.invalidate(weekShiftsProvider);
        ref.invalidate(todaysShiftsProvider);
        ref.invalidate(shiftTemplatesProvider);
        Navigator.of(context).pop(true);
      },
      failure: (message, _) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message))),
      offline: (_) => ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(S.offlineTitle))),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: context.c.ink2,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({
    required this.period,
    required this.selected,
    required this.onTap,
  });

  final ShiftPeriod period;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (label, icon) = switch (period) {
      ShiftPeriod.morning => (S.periodMorning, Icons.wb_sunny_outlined),
      ShiftPeriod.evening => (S.periodEvening, Icons.wb_twilight_rounded),
      ShiftPeriod.night => (S.periodNight, Icons.nightlight_round),
      ShiftPeriod.custom => (S.periodCustom, Icons.tune_rounded),
    };
    final times = period.times;
    return PressScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: AnimatedContainer(
        duration: effectiveDuration(context, MotionTokens.short),
        curve: effectiveCurve(context, MotionTokens.standard),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? c.primaryTint : c.surface,
          border: Border.all(color: selected ? c.primary : c.line),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Column(children: [
          Icon(icon, size: 18, color: selected ? c.primary : c.ink3),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                color: selected ? c.primary : c.ink2,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              )),
          if (times != null) ...[
            const SizedBox(height: 2),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                AppDate.minuteRange(times.$1, times.$2),
                style: TextStyle(color: c.ink3, fontSize: 10),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: c.ink2, fontSize: 13)),
        const SizedBox(height: 6),
        PressScale(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.line2),
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Row(children: [
              Icon(Icons.schedule_rounded, size: 18, color: c.ink3),
              const SizedBox(width: 8),
              // A clock reads left-to-right even in an RTL layout.
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(value, style: AppTypography.digits(c.ink, size: 16)),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

/// Plus/minus around a number. No keyboard, so no invalid state to validate
/// and no numeric-keypad detour for a value that is almost always nudged by
/// one.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line2),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(children: [
        _Round(
          icon: Icons.remove_rounded,
          enabled: value > min,
          onTap: () => onChanged(value - 1),
        ),
        Expanded(
          child: Center(
            child: TabularDigits(
              toArabicIndic('$value'),
              style: AppTypography.digits(c.ink, size: 18),
            ),
          ),
        ),
        _Round(
          icon: Icons.add_rounded,
          enabled: value < max,
          onTap: () => onChanged(value + 1),
        ),
      ]),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      enabled: enabled,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? c.primaryTint : c.surface2,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: enabled ? c.primary : c.ink3),
      ),
    );
  }
}

class _RepeatSwitch extends StatelessWidget {
  const _RepeatSwitch({
    required this.value,
    required this.weekday,
    required this.onChanged,
  });

  final bool value;
  final int weekday;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: value ? c.primaryTint : c.surface,
        border: Border.all(color: value ? c.primary : c.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(children: [
        Icon(Icons.repeat_rounded,
            size: 18, color: value ? c.primary : c.ink3),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${S.repeatWeekly} · ${AppDate.weekdayName(weekday)}',
                style: TextStyle(
                  color: value ? c.primary : c.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(S.repeatWeeklyHelp,
                  style: TextStyle(color: c.ink3, fontSize: 11, height: 1.4)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }
}
