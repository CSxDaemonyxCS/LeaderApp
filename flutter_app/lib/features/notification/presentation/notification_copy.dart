import 'package:flutter/material.dart';

import '../../../core/format/app_date.dart';
import '../../../core/motion/animated_counter.dart';
import '../../../l10n/strings.dart';
import '../domain/notification_models.dart';
import '../domain/notification_selectors.dart';

/// Turns a value into the words and the icon a row shows.
///
/// Separated from the widget so the model can stay copy-free (a test asserts
/// on kinds and counts, never on translated text) and from the selectors so
/// the domain stays free of Flutter. Nothing here decides *whether* a row
/// exists — only how the one the selectors produced reads.

IconData notificationIcon(NotificationKind kind) => switch (kind) {
      NotificationKind.syncConflict => Icons.fact_check_outlined,
      NotificationKind.syncFailed => Icons.sync_problem_rounded,
      NotificationKind.shiftUnderstaffed => Icons.person_add_alt_rounded,
      NotificationKind.shiftAttendanceMissing => Icons.how_to_reg_outlined,
      NotificationKind.shiftStartingSoon => Icons.schedule_rounded,
      NotificationKind.stockDepleted => Icons.inventory_2_outlined,
      NotificationKind.stockLow => Icons.trending_down_rounded,
      NotificationKind.stockExpiring => Icons.event_busy_rounded,
    };

String notificationTitle(NotificationKind kind) => switch (kind) {
      NotificationKind.syncConflict => S.notifSyncConflictTitle,
      NotificationKind.syncFailed => S.notifSyncFailedTitle,
      NotificationKind.shiftUnderstaffed => S.notifShiftUnderstaffedTitle,
      NotificationKind.shiftAttendanceMissing => S.notifShiftAttendanceTitle,
      NotificationKind.shiftStartingSoon => S.notifShiftSoonTitle,
      NotificationKind.stockDepleted => S.notifStockDepletedTitle,
      NotificationKind.stockLow => S.notifStockLowTitle,
      NotificationKind.stockExpiring => S.notifStockExpiringTitle,
    };

/// The one-line detail under the title: what the record is, then what is
/// wrong with it. Both halves come from the notification itself — the record
/// name it was built with and the magnitude the selector measured — so a row
/// never claims a figure the feed did not derive.
String notificationSubtitle(AppNotification n) {
  final detail = switch (n.kind) {
    NotificationKind.syncConflict => S.notifSyncConflictBody,
    NotificationKind.syncFailed => S.notifSyncFailedBody,
    NotificationKind.shiftUnderstaffed => S.notifShiftUnderstaffedBody
        .replaceFirst('%d', toArabicIndic(n.count.toString())),
    NotificationKind.shiftAttendanceMissing => S.notifShiftAttendanceBody
        .replaceFirst('%d', toArabicIndic(n.count.toString())),
    NotificationKind.shiftStartingSoon =>
      S.notifShiftSoonBody.replaceFirst('%s', AppDate.time(n.occurredAt)),
    NotificationKind.stockDepleted => S.notifStockDepletedBody,
    NotificationKind.stockLow =>
      S.notifStockLowBody.replaceFirst('%d', toArabicIndic(n.count.toString())),
    NotificationKind.stockExpiring => S.notifStockExpiringBody.replaceFirst(
        '%s',
        AppDate.dayMonth(
          n.occurredAt,
        )),
  };

  final label = n.recordLabel;
  return label == null || label.isEmpty ? detail : '$label · $detail';
}

/// The trailing timestamp: a clock time for something on today's page, a date
/// for anything else. A day and a time together is more than a scanning eye
/// needs, and the row is already inside a group that says which day it is.
String notificationTimeLabel(DateTime occurredAt, DateTime now) {
  final sameDay = occurredAt.year == now.year &&
      occurredAt.month == now.month &&
      occurredAt.day == now.day;
  return sameDay ? AppDate.time(occurredAt) : AppDate.dayMonth(occurredAt);
}

String notificationGroupLabel(NotificationGroup group) => switch (group) {
      NotificationGroup.upcoming => S.notificationsGroupUpcoming,
      NotificationGroup.today => S.notificationsGroupToday,
      NotificationGroup.yesterday => S.notificationsGroupYesterday,
      NotificationGroup.earlier => S.notificationsGroupEarlier,
    };

/// How many unread rows there are, in words — the bell's accessible label.
String unreadNotificationsLabel(int count) => switch (count) {
      0 => S.notificationsNoneUnread,
      1 => S.notificationsUnreadOne,
      _ => S.notificationsUnreadMany
          .replaceFirst('%d', toArabicIndic(count.toString())),
    };
