import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_logger.dart';
import '../../../services/notification_service.dart';
import '../../../l10n/l10n_extensions.dart';

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
        body: context.l10n.testNotificationSuccess,
      );
      await _refresh();
      if (!mounted) return;
      if (result.ok) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.testNotificationSent),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _lastImmediateError = 'not_ok');
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.notificationPermissionOff),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: context.l10n.openSettings,
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
        body: context.l10n.testAfterOneMinute,
      );
      if (!mounted) return;
      if (result.ok) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.scheduledMinuteTestAt(
                '${result.scheduledAt?.hour.toString().padLeft(2, "0")}:${result.scheduledAt?.minute.toString().padLeft(2, "0")}',
              ),
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.scheduleMinuteFailed(
                (result.failureReason ??
                        result.error ??
                        context.l10n.unknownError)
                    .toString(),
              ),
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
        body: context.l10n.testAfterTenSeconds,
      );
      await _refresh();
      if (!mounted) return;
      if (result.ok) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.scheduledTestAt(
                '${result.scheduledAt?.hour.toString().padLeft(2, "0")}:${result.scheduledAt?.minute.toString().padLeft(2, "0")}',
              ),
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
      } else if (result.failureReason == 'exact_alarm_unavailable') {
        setState(() => _lastScheduledError = 'exact_alarm');
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.exactAlarmPermissionMissing),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: context.l10n.allow,
              onPressed: _openExactAlarm,
            ),
          ),
        );
      } else if (result.failureReason == 'permission_denied' ||
          result.failureReason == 'notifications_disabled') {
        setState(() => _lastScheduledError = 'permission');
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.notificationsDisabledSchedule),
            backgroundColor: Colors.orange.shade700,
            action: SnackBarAction(
              label: context.l10n.openSettings,
              onPressed: _openAppSettings,
            ),
          ),
        );
      } else if (result.failureReason == 'no_pending_request') {
        setState(() => _lastScheduledError = 'no_pending');
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.scheduleNotRetained),
            backgroundColor: Colors.red.shade600,
          ),
        );
      } else {
        setState(() => _lastScheduledError = 'unknown');
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.scheduleTestFailed(
                (result.error ??
                        result.failureReason ??
                        context.l10n.unknownError)
                    .toString(),
              ),
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
            Text(
              context.l10n.notificationSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _StatusRow(
              label: context.l10n.notificationPermission,
              value:
                  snap == null
                      ? context.l10n.checking
                      : snap.permissionGranted
                      ? context.l10n.granted
                      : context.l10n.notGranted,
              ok: snap?.permissionGranted ?? false,
            ),
            _StatusRow(
              label: context.l10n.appNotifications,
              value:
                  snap == null
                      ? context.l10n.checking
                      : snap.notificationsEnabled
                      ? context.l10n.on
                      : context.l10n.off,
              ok: snap?.notificationsEnabled ?? false,
            ),
            _StatusRow(
              label: context.l10n.exactAlarm,
              value:
                  snap == null
                      ? context.l10n.checking
                      : snap.exactAvailable
                      ? context.l10n.granted
                      : context.l10n.notGranted,
              ok: snap?.exactAvailable ?? false,
            ),
            _StatusRow(
              label: context.l10n.deviceTimezone,
              value: snap?.tzLocalName ?? '—',
              ok: true,
            ),
            _StatusRow(
              label: context.l10n.notificationChannel,
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
                  label: Text(context.l10n.sendTestNotification),
                ),
                ElevatedButton.icon(
                  key: const ValueKey('settings_scheduled_test'),
                  onPressed: _busy ? null : _scheduleTenSeconds,
                  icon: const Icon(Icons.schedule),
                  label: Text(context.l10n.testAfterTenSeconds),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('settings_open_os'),
                  onPressed: _busy ? null : _openAppSettings,
                  icon: const Icon(Icons.settings),
                  label: Text(context.l10n.openNotificationSettings),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('settings_open_exact'),
                  onPressed: _busy ? null : _openExactAlarm,
                  icon: const Icon(Icons.alarm),
                  label: Text(context.l10n.allowExactAlarm),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('settings_one_minute_test'),
                  onPressed: _busy ? null : _scheduleOneMinuteDiagnostic,
                  icon: const Icon(Icons.timer),
                  label: Text(context.l10n.testAfterOneMinute),
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
