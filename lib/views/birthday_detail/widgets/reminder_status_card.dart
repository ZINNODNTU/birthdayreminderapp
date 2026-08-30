import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder_status.dart';

class ReminderStatusCard extends StatelessWidget {
  const ReminderStatusCard({
    super.key,
    required this.status,
    required this.message,
    this.nextFireAt,
    required this.rescheduling,
    required this.repeatAnnually,
    required this.onReschedule,
  });

  final ReminderStatus status;
  final String? message;
  final DateTime? nextFireAt;
  final bool rescheduling;
  final bool repeatAnnually;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case ReminderStatus.scheduled:
        color = Colors.green.shade600;
        label = 'Đã lên lịch';
        break;
      case ReminderStatus.notScheduled:
        color = Colors.orange.shade700;
        label = 'Chưa lên lịch';
        break;
      case ReminderStatus.phantom:
        color = Colors.red.shade700;
        label = 'Mất lịch — cần đồng bộ';
        break;
      case ReminderStatus.past:
        color = Colors.orange.shade700;
        label = 'Đã quá thời gian';
        break;
      case ReminderStatus.permissionDenied:
        color = Colors.red.shade700;
        label = 'Chưa cấp quyền';
        break;
      case ReminderStatus.unknown:
        color = Colors.grey.shade600;
        label = 'Đang kiểm tra';
        break;
      case ReminderStatus.disabled:
        color = Colors.grey.shade600;
        label = 'Đã tắt';
        break;
    }
    final bool rescheduleEnabled = status != ReminderStatus.disabled;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: color),
                const SizedBox(width: 8),
                Text(
                  'Trạng thái nhắc',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (nextFireAt != null)
              Text(
                'Lần nhắc kế tiếp: ${DateFormat('dd/MM/yyyy HH:mm').format(nextFireAt!)}',
              ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(message!),
              ),
            if (status == ReminderStatus.scheduled ||
                status == ReminderStatus.notScheduled ||
                status == ReminderStatus.phantom ||
                status == ReminderStatus.past)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Text('Lặp lại hằng năm: '),
                    Text(
                      repeatAnnually ? 'Có' : 'Không',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed:
                    rescheduleEnabled && !rescheduling ? onReschedule : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Đặt lại lịch nhắc'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
