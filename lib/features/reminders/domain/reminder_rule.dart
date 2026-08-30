import 'package:flutter/material.dart';

import '../../../models/birthday.dart';

/// Configuration for a single reminder rule on a birthday. V3 contract:
///
///   * `enabled` reflects the user's "Bật thông báo" toggle (formerly
///     `isRecurringNotificationEnabled` in the SQLite row). The legacy
///     DB column is kept for backwards compatibility but its semantic
///     in product logic is now "notifications are turned on".
///   * `recurring` reflects the user's "Lặp lại hằng năm" toggle.
///   * The "Thông báo lặp" UI option is gone; the column value is
///     repurposed to "Bật thông báo" so existing data keeps meaning.
class ReminderRule {
  const ReminderRule({
    required this.daysBefore,
    required this.time,
    required this.enabled,
    this.recurring = true,
  });

  /// Whole days before the birthday occurrence to fire.
  final int daysBefore;

  /// Wall-clock time of day (hour:minute) for the reminder.
  final TimeOfDay time;

  /// True when the user has notifications turned on for this birthday.
  /// When false the scheduler must cancel any managed entry.
  final bool enabled;

  /// True when the reminder repeats annually. When false the user has
  /// chosen a one-shot reminder (the next single occurrence only).
  final bool recurring;

  /// Build a rule directly from the on-record [Birthday] fields.
  factory ReminderRule.fromBirthday(Birthday birthday) => ReminderRule(
    daysBefore: birthday.remindBeforeDays < 0 ? 0 : birthday.remindBeforeDays,
    time: birthday.remindTime,
    enabled: birthday.isRecurringNotificationEnabled,
    recurring: birthday.repeatAnnually,
  );
}
