// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/services.dart';

import '../../../controllers/birthday_controller.dart';
import '../../../core/logging/app_logger.dart';
import '../../../services/avatar_cache.dart';
import '../../birthdays/data/birthday_repository.dart';
import '../../reminders/services/notification_reconciler.dart';
import '../domain/backup_models.dart';
import '../services/backup_file_service.dart';
import '../services/backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});
  @override
  State<BackupRestoreScreen> createState() => _State();
}

class _State extends State<BackupRestoreScreen> {
  bool busy = false;
  BackupService backup(BuildContext c) => BackupService(
    repository: c.read<BirthdayRepository>(),
    preferences: c.read<SharedPreferences>(),
  );
  RestoreService restore(BuildContext c) => RestoreService(
    repository: c.read<BirthdayRepository>(),
    preferences: c.read<SharedPreferences>(),
  );
  Future<void> makeBackup() async {
    if (busy) return;
    setState(() => busy = true);
    BackupSaveResult? saved;
    BackupException? failure;
    try {
      final r = await backup(context).createBackup();
      if (!mounted) return;
      try {
        saved = await BackupFileService().save(r.bytes, r.fileName);
      } on BackupException catch (e, st) {
        AppLogger.error('BackupSave', e, st);
        failure = e;
      } on PlatformException catch (e, st) {
        AppLogger.error('BackupSave', e, st);
        failure = BackupException(BackupStage.share, e.message ?? e.code, e);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final sizeText = _humanSize(r.bytes.length);
      switch (saved?.outcome) {
        case BackupOutcome.savedToUserPath:
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Đã tạo bản sao lưu: ${r.birthdayCount} sinh nhật, '
                '${r.photoCount} ảnh, $sizeText.',
              ),
            ),
          );
        case BackupOutcome.shared:
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Đã tạo bản sao lưu: ${r.birthdayCount} sinh nhật, '
                '${r.photoCount} ảnh, $sizeText. Đang mở cửa sổ chia sẻ.',
              ),
            ),
          );
        case BackupOutcome.shareCancelled:
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Đã tạo bản sao lưu ($sizeText) trong thư mục ứng dụng. '
                'Bạn có thể mở lại từ đó.',
              ),
            ),
          );
        case BackupOutcome.shareFailed:
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Đã tạo bản sao lưu ($sizeText) nhưng không mở được '
                'cửa sổ chia sẻ. File vẫn còn trong thư mục ứng dụng.',
              ),
            ),
          );
        case null:
          final stageLabel = failure == null
              ? ''
              : ' (lỗi ${failure.stage.name})';
          messenger.showSnackBar(
            SnackBar(
              backgroundColor: Colors.red.shade700,
              content: Text(
                'Không thể tạo bản sao lưu$stageLabel: '
                '${failure?.cause ?? 'không rõ nguyên nhân'}',
              ),
            ),
          );
      }
    } catch (e, st) {
      AppLogger.error('Backup', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Không thể tạo bản sao lưu: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _humanSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Future<void> beginRestore() async {
    if (busy) return;
    setState(() => busy = true);
    final controller = context.read<BirthdayController>();
    final reconciler = context.read<NotificationReconciler>();

    try {
      final bytes = await BackupFileService().pick();
      if (bytes == null || !mounted) return;
      final plan = await RestoreService.validateBytes(bytes);
      if (!mounted) return;

      final ok = await _showConfirmDialog(plan);
      if (ok != true || !mounted) return;

      final result = await restore(context).apply(plan);
      AvatarCache.clear();
      await controller.loadBirthdays();
      await reconciler.reconcile();
      if (!mounted) return;

      await _showSuccessDialog(result);
    } on BackupException catch (e, st) {
      AppLogger.error('Restore', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File sao lưu không hợp lệ hoặc đã bị hỏng.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File sao lưu không hợp lệ hoặc đã bị hỏng.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool?> _showConfirmDialog(RestorePlan plan) {
    return showAdaptiveDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Khôi phục dữ liệu?'),
        content: Text(
          'Bản sao lưu: ${plan.createdAt.toLocal()}\n'
          'Phiên bản: ${plan.appVersion}\n\n'
          'Bao gồm:\n• ${plan.birthdayCount} sinh nhật\n'
          '• ${plan.photoCount} ảnh\n'
          '• Ghi chú và cài đặt liên quan\n\n'
          'Dữ liệu sẽ được gộp an toàn với dữ liệu hiện tại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog(RestoreResult result) {
    return showAdaptiveDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Khôi phục thành công'),
        content: Text(
          '${result.restored} sinh nhật\n'
          '${result.photosRestored} ảnh\n'
          'Bỏ qua: ${result.skipped}\n'
          'Xung đột: ${result.conflicts}\n'
          'Ảnh lỗi: ${result.photosFailed}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sao lưu & khôi phục')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Bao gồm: sinh nhật, ghi chú, cấu hình nhắc, ảnh, dữ liệu Local Mode và một số cài đặt ứng dụng.\n\nKhông bao gồm: mật khẩu, Google token, API key hoặc dữ liệu đăng nhập.',
            ),
          ),
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Ứng dụng sắp chuyển sang chữ ký phát hành bảo mật mới. Trước khi cài phiên bản mới, hãy sao lưu toàn bộ dữ liệu.',
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Sao lưu toàn bộ dữ liệu'),
          onTap: busy ? null : makeBackup,
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Khôi phục dữ liệu'),
          onTap: busy ? null : beginRestore,
        ),
        if (busy) const Center(child: CircularProgressIndicator()),
      ],
    ),
  );
}

class BackupSettingsCard extends StatelessWidget {
  const BackupSettingsCard({super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'SAO LƯU & KHÔI PHỤC',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: const Text('Sao lưu toàn bộ dữ liệu'),
          subtitle: const Text(
            'Tạo file ZIP để giữ an toàn sau khi gỡ ứng dụng',
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Khôi phục dữ liệu'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
          ),
        ),
      ],
    ),
  );
}
