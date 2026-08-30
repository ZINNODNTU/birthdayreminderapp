import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../reminders/data/reminder_schedule_store.dart';
import '../../reminders/services/notification_reconciler.dart';

class ReminderSettingsCard extends StatefulWidget {
  const ReminderSettingsCard({super.key});

  @override
  State<ReminderSettingsCard> createState() => _ReminderSettingsCardState();
}

class _ReminderSettingsCardState extends State<ReminderSettingsCard> {
  bool _busy = false;
  List<ManagedReminderEntry>? _entries;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final store = context.read<ReminderScheduleStore>();
    setState(() => _entries = store.loadAll().values.toList(growable: false));
  }

  Future<void> _resync() async {
    setState(() => _busy = true);
    try {
      final reconciler = context.read<NotificationReconciler>();
      final result = await reconciler.reconcile();
      setState(
        () =>
            _statusMessage =
                'Đã đặt ${result.scheduled} lịch, huỷ ${result.cancelled} lịch cũ.',
      );
    } catch (e) {
      setState(() => _statusMessage = 'Đồng bộ thất bại: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries ?? const <ManagedReminderEntry>[];
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhắc sinh nhật',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Số lịch nhắc đang chờ: ${entries.length}'),
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_statusMessage!),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _busy ? null : _resync,
                  icon: const Icon(Icons.sync),
                  label: const Text('Đồng bộ lại lịch nhắc'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text('Chưa có lịch nhắc nào đang chờ.')
            else
              ...entries.take(10).map((e) {
                final dt = _approximateNextFire(e);
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.event),
                  title: Text(_safeName(e.scheduleKey)),
                  subtitle: Text(
                    dt == null
                        ? 'ID: ${e.notificationId} • chờ'
                        : '${DateFormat('dd/MM/yyyy HH:mm').format(dt)} • '
                            'ID: ${e.notificationId}',
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _safeName(String key) {
    // Avoid logging anything that could carry user data; show only the
    // safe portion of the schedule key.
    final parts = key.split(':');
    if (parts.length >= 2) {
      return 'Sinh nhật ${parts[1].substring(0, parts[1].length.clamp(0, 6))}…';
    }
    return 'Lịch nhắc';
  }

  DateTime? _approximateNextFire(ManagedReminderEntry e) {
    // The store keeps only an opaque key + id; the reconciler
    // re-derives the exact fire time.
    return null;
  }
}
