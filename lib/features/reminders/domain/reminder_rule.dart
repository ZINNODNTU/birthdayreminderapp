import 'package:flutter/material.dart';

import '../../../models/birthday.dart';

/// Configuration for a single reminder rule on a birthday. Phase 4
/// ships one reminder per birthday; multi-rule is future work.
class ReminderRule {
  const ReminderRule({
    required this.daysBefore,
    required this.time,
    required this.enabled,
  });

  /// Whole days before the birthday occurrence to fire.
  final int daysBefore;

  /// Wall-clock time of day (hour:minute) for the reminder.
  final TimeOfDay time;

  /// If false, no schedule should exist for this birthday.
  final bool enabled;

  /// Build a rule directly from the on-record [Birthday] fields.
  factory ReminderRule.fromBirthday(Birthday birthday) => ReminderRule(
    daysBefore: birthday.remindBeforeDays,
    time: birthday.remindTime,
    enabled: birthday.isRecurringNotificationEnabled,
  );
}
