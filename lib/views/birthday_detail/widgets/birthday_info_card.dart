import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/birthday.dart';

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
            _buildInfoRow('Tên', birthday.name, context),
            _buildInfoRow('Tuổi', '$age', context),
            if (birthday.gender != null)
              _buildInfoRow('Giới tính', birthday.gender!, context),
            if (birthday.nickname != null)
              _buildInfoRow('Biệt danh', birthday.nickname!, context),
            if (birthday.relationship != null)
              _buildInfoRow('Mối quan hệ', birthday.relationship!, context),
            _buildInfoRow(
              'Ngày sinh dương',
              dateFormat.format(birthday.solarBirthday),
              context,
            ),
            _buildInfoRow(
              'Ngày sinh âm',
              '${birthday.lunarBirthday.day.toString().padLeft(2, '0')}/${birthday.lunarBirthday.month.toString().padLeft(2, '0')}',
              context,
            ),
            _buildInfoRow(
              'Loại lịch',
              birthday.calendarType == CalendarType.solar
                  ? 'Dương lịch'
                  : 'Âm lịch',
              context,
            ),
            _buildInfoRow(
              'Lặp lại hằng năm',
              birthday.repeatAnnually ? 'Có' : 'Không',
              context,
            ),
            _buildInfoRow(
              'Nhắc trước',
              '${birthday.remindBeforeDays} ngày',
              context,
            ),
            _buildInfoRow(
              'Thời gian nhắc',
              birthday.remindTime.format(context),
              context,
            ),
            _buildInfoRow(
              'Bật thông báo',
              birthday.isRecurringNotificationEnabled ? 'Bật' : 'Tắt',
              context,
            ),
            if (birthday.note != null && birthday.note!.isNotEmpty)
              _buildInfoRow('Ghi chú', birthday.note!, context),
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
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
