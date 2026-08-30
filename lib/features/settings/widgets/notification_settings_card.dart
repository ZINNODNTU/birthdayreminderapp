import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_logger.dart';
import '../../../services/notification_service.dart';

class NotificationSettingsCard extends StatefulWidget {
  const NotificationSettingsCard({super.key});

  @override
  State<NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<NotificationSettingsCard> {
  NotificationRuntimeSnapshot? _snapshot;
  bool _busy = false;
  String? _lastImmediateError;
  String? _lastScheduledError;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final svc = context.read<NotificationService>();
    final snap = await svc.runtimeSnapshot();
    if (!mounted) return;
    setState(() => _snapshot = snap);
  }

  Future<void> _sendImmediate() async {
    setState(() => _busy = true);
    final svc = context.read<NotificationService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await svc.showTestNotification(
        title: 'Birthday Reminder 🎂',
        body: 'Thông báo thử hoạt động thành công!',
      );
      await _refresh();
      if (!mounted) return;
      if (result.ok) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Đã gửi thông báo thử'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _lastImmediateError = 'not_ok');
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Quyền thông báo chưa được bật.'),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Mở cài đặt',
              onPressed: _openAppSettings,
            ),
          ),
        );
      }
    } catch (e, st) {
      AppLogger.error('NotificationTest', e, st);
      setState(() => _lastImmediateError = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scheduleOneMinuteDiagnostic() async {
    setState(() => _busy = true);
    final svc = context.read<NotificationService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await svc.scheduleOneMinuteDiagnostic(
        title: 'Birthday Reminder 🎂',
        body: 'Thử hệ thống nhắc sinh nhật sau 1 phút — thành công!',
      );
      if (!mounted) return;
      if (result.ok) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Đã đặt lịch thử 1 phút lúc '
              '${result.scheduledAt?.hour.toString().padLeft(2, "0")}'
              ':${result.scheduledAt?.minute.toString().padLeft(2, "0")}.',
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Không thể đặt lịch 1 phút: '
              '${result.failureReason ?? result.error ?? "lỗi không xác định"}',
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e, st) {
      AppLogger.error('NotificationDiag', e, st);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scheduleTenSeconds() async {
    setState(() => _busy = true);
    final svc = context.read<NotificationService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await svc.scheduleTestNotification(
        title: 'Birthday Reminder 🎂',
        body: 'Thông báo thử sau 10 giây hoạt động thành công!',
      );
      await _refresh();
      if (!mounted) return;
      if (result.ok) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '�ã đặt thông báo thử lúc '
              '${result.scheduledAt?.hour.toString().padLeft(2, "0")}'
              ':${result.scheduledAt?.minute.toString().padLeft(2, "0")}.',
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
      } else if (result.failureReason == 'exact_alarm_unavailable') {
        setState(() => _lastScheduledError = 'exact_alarm');
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Thiết bị chưa cấp quyền báo thức chính xác.'),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Cho phép',
              onPressed: _openExactAlarm,
            ),
          ),
        );
      } else if (result.failureReason == 'permission_denied' ||
          result.failureReason == 'notifications_disabled') {
        setState(() => _lastScheduledError = 'permission');
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Quyền thông báo chưa được bật — không thể đặt lịch.',
            ),
            backgroundColor: Colors.orange.shade700,
            action: SnackBarAction(
              label: 'Mở cài đặt',
              onPressed: _openAppSettings,
            ),
          ),
        );
      } else if (result.failureReason == 'no_pending_request') {
        setState(() => _lastScheduledError = 'no_pending');
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Thiết bị không giữ lịch — kiểm tra lại quyền báo thức.',
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      } else {
        setState(() => _lastScheduledError = 'unknown');
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Không thể đặt thông báo thử: '
              '${result.error ?? result.failureReason ?? "lỗi không xác định"}',
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e, st) {
      AppLogger.error('NotificationTest', e, st);
      setState(() => _lastScheduledError = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openAppSettings() async {
    final svc = context.read<NotificationService>();
    await svc.openAppNotificationSettings();
  }

  Future<void> _openExactAlarm() async {
    final svc = context.read<NotificationService>();
    await svc.requestExactAlarmsPermission();
    await svc.openExactAlarmSettings();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snapshot;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thông báo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _StatusRow(
              label: 'Quyền thông báo',
              value:
                  snap == null
                      ? 'Đang kiểm tra'
                      : snap.permissionGranted
                      ? 'Đã cấp'
                      : 'Chưa cấp',
              ok: snap?.permissionGranted ?? false,
            ),
            _StatusRow(
              label: 'Thông báo ứng dụng',
              value:
                  snap == null
                      ? 'Đang kiểm tra'
                      : snap.notificationsEnabled
                      ? 'Đang bật'
                      : 'Đang tắt',
              ok: snap?.notificationsEnabled ?? false,
            ),
            _StatusRow(
              label: 'Báo thức chính xác',
              value:
                  snap == null
                      ? 'Đang kiểm tra'
                      : snap.exactAvailable
                      ? 'Đã cấp'
                      : 'Chưa cấp',
              ok: snap?.exactAvailable ?? false,
            ),
            _StatusRow(
              label: 'Múi giờ thiết bị',
              value: snap?.tzLocalName ?? '—',
              ok: true,
            ),
            _StatusRow(
              label: 'Kênh thông báo',
              value: NotificationService.testChannelName,
              ok: true,
            ),
            if (snap != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'nowLocal=${snap.deviceNow.toLocal()} '
                  'utc=${snap.deviceUtc.toIso8601String()} '
                  'offset=${snap.utcOffsetMinutes}m',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (_lastImmediateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Lỗi gửi tức thì: $_lastImmediateError',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            if (_lastScheduledError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Lỗi đặt lịch: $_lastScheduledError',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  key: const ValueKey('settings_immediate_test'),
                  onPressed: _busy ? null : _sendImmediate,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Gửi thông báo thử'),
                ),
                ElevatedButton.icon(
                  key: const ValueKey('settings_scheduled_test'),
                  onPressed: _busy ? null : _scheduleTenSeconds,
                  icon: const Icon(Icons.schedule),
                  label: const Text('Thử thông báo sau 10 giây'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('settings_open_os'),
                  onPressed: _busy ? null : _openAppSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Mở cài đặt thông báo'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('settings_open_exact'),
                  onPressed: _busy ? null : _openExactAlarm,
                  icon: const Icon(Icons.alarm),
                  label: const Text('Cho phép báo thức chính xác'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('settings_one_minute_test'),
                  onPressed: _busy ? null : _scheduleOneMinuteDiagnostic,
                  icon: const Icon(Icons.timer),
                  label: const Text('Thử hệ thống nhắc sinh nhật sau 1 phút'),
                ),
              ],
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.ok,
  });

  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color: ok ? Colors.green.shade600 : Colors.red.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
