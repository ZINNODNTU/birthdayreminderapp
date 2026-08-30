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
  static const _collapsedCount = 3;

  bool _busy = false;
  bool _expanded = false;
  List<ManagedReminderEntry>? _entries;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final store = context.read<ReminderScheduleStore>();
    final entries = store.loadAll().values.toList(growable: false)
      ..sort((a, b) {
        final aTime = a.scheduledAt;
        final bTime = b.scheduledAt;
        if (aTime == null) return bTime == null ? 0 : 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });
    setState(() {
      _entries = entries;
      if (entries.length <= _collapsedCount) _expanded = false;
    });
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
    final visibleEntries =
        _expanded ? entries : entries.take(_collapsedCount).toList();
    final hiddenCount = entries.length - _collapsedCount;
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
            ElevatedButton.icon(
              onPressed: _busy ? null : _resync,
              icon: const Icon(Icons.sync),
              label: const Text('Đồng bộ lại lịch nhắc'),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text('Chưa có lịch nhắc nào đang chờ.')
            else
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    for (final e in visibleEntries)
                      ListTile(
                        key: ValueKey('reminder-entry-${e.scheduleKey}'),
                        dense: true,
                        leading: const Icon(Icons.event),
                        title: Text(_safeName(e.scheduleKey)),
                        subtitle: Text(
                          e.scheduledAt == null
                              ? 'ID: ${e.notificationId} • chờ'
                              : '${DateFormat('dd/MM/yyyy HH:mm').format(e.scheduledAt!)} • '
                                  'ID: ${e.notificationId}',
                        ),
                      ),
                    if (entries.length > _collapsedCount)
                      Align(
                        alignment: Alignment.center,
                        child: TextButton.icon(
                          key: const ValueKey('reminder-expand-toggle'),
                          onPressed:
                              () => setState(() => _expanded = !_expanded),
                          icon: Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                          ),
                          label: Text(
                            _expanded
                                ? 'Thu gọn'
                                : 'Xem thêm $hiddenCount lịch',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
}
