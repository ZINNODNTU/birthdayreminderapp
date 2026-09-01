import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../reminders/data/reminder_schedule_store.dart';
import '../../../l10n/l10n_extensions.dart';
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
  int _processed = 0;
  int _total = 0;
  String? _currentName;

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
    setState(() {
      _busy = true;
      _processed = 0;
      _total = 0;
      _currentName = null;
      _statusMessage = 'Đang đồng bộ lịch nhắc...';
    });
    try {
      final reconciler = context.read<NotificationReconciler>();
      final result = await reconciler.reconcile(
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _processed = progress.processed;
            _total = progress.total;
            _currentName = progress.displayName;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _statusMessage = result.isOk
            ? 'Đồng bộ hoàn tất\nĐã tạo ${result.scheduled} lịch nhắc\nKhông có lỗi'
            : 'Đồng bộ thất bại\n${result.message ?? '${result.failed} lịch bị lỗi'}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Đồng bộ thất bại\n$e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries ?? const <ManagedReminderEntry>[];
    final visibleEntries = _expanded
        ? entries
        : entries.take(_collapsedCount).toList();
    final hiddenCount = entries.length - _collapsedCount;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.birthdayReminder,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.reminderPendingCount(entries.length)),
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_statusMessage!),
              ),
            if (_busy) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _total == 0 ? null : _processed / _total,
              ),
              const SizedBox(height: 8),
              Text('Đã xử lý $_processed/$_total lịch'),
              if (_currentName != null) Text('Đang xử lý: $_currentName'),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _busy ? null : _resync,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(context.l10n.resyncReminders),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Text(context.l10n.noPendingReminders)
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
                        title: Text(
                          e.displayName.trim().isEmpty
                              ? 'Không có tên'
                              : e.displayName.trim(),
                        ),
                        subtitle: Text(
                          e.scheduledAt == null
                              ? context.l10n.waiting
                              : DateFormat('dd/MM/yyyy - HH:mm')
                                    .format(e.scheduledAt!),
                        ),
                      ),
                    if (entries.length > _collapsedCount)
                      Align(
                        alignment: Alignment.center,
                        child: TextButton.icon(
                          key: const ValueKey('reminder-expand-toggle'),
                          onPressed: () =>
                              setState(() => _expanded = !_expanded),
                          icon: Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                          ),
                          label: Text(
                            _expanded
                                ? context.l10n.collapse
                                : context.l10n.showMoreReminders(hiddenCount),
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
}
