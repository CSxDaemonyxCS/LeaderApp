import '../motion/animated_counter.dart';

/// Date and time rendering for an Arabic-first UI.
///
/// Written by hand rather than through `intl`'s `DateFormat` because the
/// Arabic date symbols are only loaded once `initializeDateFormatting` has
/// run, and this app must render correctly on its very first frame with no
/// asynchronous setup. The shapes here are the only ones the UI needs.
abstract final class AppDate {
  static const List<String> _months = [
    'كانون الثاني',
    'شباط',
    'آذار',
    'نيسان',
    'أيار',
    'حزيران',
    'تموز',
    'آب',
    'أيلول',
    'تشرين الأول',
    'تشرين الثاني',
    'كانون الأول',
  ];

  /// `١٢ أيلول`
  static String dayMonth(DateTime d) =>
      '${toArabicIndic(d.day.toString())} ${_months[d.month - 1]}';

  /// `١٢ أيلول · ١٤:٣٠`
  static String dayMonthTime(DateTime d) => '${dayMonth(d)} · ${time(d)}';

  /// `١٤:٣٠` — always rendered left-to-right by the caller.
  static String time(DateTime d) =>
      '${toArabicIndic(d.hour.toString().padLeft(2, '0'))}:'
      '${toArabicIndic(d.minute.toString().padLeft(2, '0'))}';

  /// Arabic weekday names indexed by `DateTime.weekday` (1 = Monday).
  static const List<String> _weekdays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  /// `السبت` from a `DateTime.weekday` value.
  static String weekdayName(int weekday) => _weekdays[weekday - 1];

  /// `الأحد` from a date.
  static String weekdayOf(DateTime d) => weekdayName(d.weekday);

  /// `٠٨:٣٠` from minutes since midnight. Minutes past 24h wrap, so a night
  /// shift's end reads as `٠٢:٠٠` rather than `٢٦:٠٠`.
  static String hm(int minutes) {
    final m = minutes % (24 * 60);
    return '${toArabicIndic((m ~/ 60).toString().padLeft(2, '0'))}:'
        '${toArabicIndic((m % 60).toString().padLeft(2, '0'))}';
  }

  /// `٠٨:٠٠ – ١٤:٠٠` from two minute offsets.
  static String minuteRange(int startMinutes, int endMinutes) =>
      '${hm(startMinutes)} – ${hm(endMinutes)}';

  /// `١٢ أيلول – ١٨ أيلول` for a week beginning at [weekStart].
  static String weekRange(DateTime weekStart) => '${dayMonth(weekStart)} – '
      '${dayMonth(weekStart.add(const Duration(days: 6)))}';

  /// `٠٨:٠٠ – ١٤:٠٠` from two whole hours.
  static String hourRange(int startHour, int endHour) =>
      '${toArabicIndic(startHour.toString().padLeft(2, '0'))}:٠٠ – '
      '${toArabicIndic(endHour.toString().padLeft(2, '0'))}:٠٠';

  /// Whole days between now and [d]; negative when [d] is in the past.
  static int daysFromNow(DateTime d) => DateTime(d.year, d.month, d.day)
      .difference(DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ))
      .inDays;

  /// `قبل ٣ أيام` / `بعد ٤ أيام` / `اليوم`.
  static String relativeDays(DateTime d) {
    final n = daysFromNow(d);
    if (n == 0) return 'اليوم';
    if (n == 1) return 'غدا';
    if (n == -1) return 'أمس';
    final abs = toArabicIndic(n.abs().toString());
    return n > 0 ? 'بعد $abs يوما' : 'قبل $abs يوما';
  }
}
