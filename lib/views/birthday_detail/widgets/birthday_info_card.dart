import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/birthday.dart';
import '../../../l10n/l10n_extensions.dart';

/// Displays birthday information in a card.
class BirthdayInfoCard extends StatelessWidget {
  const BirthdayInfoCard({
    super.key,
    required this.birthday,
    required this.age,
    required this.dateFormat,
  });

  final Birthday birthday;
  final int age;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(context.l10n.name, birthday.name, context),
            _buildInfoRow(context.l10n.age, '$age', context),
            if (birthday.gender != null)
              _buildInfoRow(context.l10n.gender, birthday.gender!, context),
            if (birthday.nickname != null)
              _buildInfoRow(context.l10n.nickname, birthday.nickname!, context),
            if (birthday.relationship != null)
              _buildInfoRow(
                context.l10n.relationship,
                birthday.relationship!,
                context,
              ),
            _buildInfoRow(
              context.l10n.solarBirthday,
              dateFormat.format(birthday.solarBirthday),
              context,
            ),
            _buildInfoRow(
              context.l10n.lunarBirthday,
              '${birthday.lunarBirthday.day.toString().padLeft(2, '0')}/${birthday.lunarBirthday.month.toString().padLeft(2, '0')}',
              context,
            ),
            _buildInfoRow(
              context.l10n.calendarType,
              birthday.calendarType == CalendarType.solar
                  ? context.l10n.solar
                  : context.l10n.lunar,
              context,
            ),
            _buildInfoRow(
              context.l10n.repeatAnnually,
              birthday.repeatAnnually ? context.l10n.yes : context.l10n.no,
              context,
            ),
            _buildInfoRow(
              context.l10n.remindBefore,
              context.l10n.days(birthday.remindBeforeDays),
              context,
            ),
            _buildInfoRow(
              context.l10n.notificationTime,
              birthday.remindTime.format(context),
              context,
            ),
            _buildInfoRow(
              context.l10n.enableNotification,
              birthday.isRecurringNotificationEnabled
                  ? context.l10n.enabled
                  : context.l10n.disabled,
              context,
            ),
            if (birthday.note != null && birthday.note!.isNotEmpty)
              _buildInfoRow(context.l10n.note, birthday.note!, context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: Colors.grey.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
