import 'package:flutter/material.dart';
import '../models/sync_progress.dart';
import '../l10n/l10n_extensions.dart';

class SyncProgressDialog extends StatefulWidget {
  final ValueNotifier<SyncProgress> notifier;
  final VoidCallback? onComplete;

  const SyncProgressDialog({
    super.key,
    required this.notifier,
    this.onComplete,
  });

  @override
  State<SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<SyncProgressDialog> {
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (mounted) setState(() {});
      final progress = widget.notifier.value;
      if (progress.completed && widget.onComplete != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onComplete!();
        });
      }
    };
    widget.notifier.addListener(_listener);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.notifier.value;
    final isComplete = progress.completed;
    final hasError = progress.error != null && progress.error!.isNotEmpty;
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isComplete
                      ? (hasError ? Icons.error_outline : Icons.check_circle)
                      : Icons.cloud_sync,
                  color:
                      isComplete
                          ? (hasError ? Colors.red : Colors.green)
                          : Colors.amber,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isComplete
                        ? (hasError ? l10n.syncError : l10n.syncComplete)
                        : progress.status.isNotEmpty
                        ? progress.status
                        : l10n.syncing,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isComplete && progress.total > 0) ...[
              Text(
                l10n.birthdaySyncProgress(progress.current, progress.total),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value:
                    progress.total > 0 ? progress.current / progress.total : 0,
                backgroundColor: Colors.grey[200],
                color: Colors.amber,
              ),
            ],
            if (isComplete && !hasError && progress.total > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.birthdaySyncProgress(progress.total, progress.total),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            if (hasError && progress.error != null) ...[
              const SizedBox(height: 12),
              Text(
                progress.error!,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (isComplete)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
      ],
    );
  }
}
