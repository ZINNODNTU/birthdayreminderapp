// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../birthdays/data/birthday_repository.dart';
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
    setState(() => busy = true);
    try {
      final r = await backup(context).createBackup();
      await BackupFileService().save(r.bytes, r.fileName);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã tạo bản sao lưu: ${r.birthdayCount} sinh nhật, ${r.photoCount} ảnh, ${r.bytes.length} bytes',
            ),
          ),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tạo bản sao lưu.')),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> beginRestore() async {
    final bytes = await BackupFileService().pick();
    if (bytes == null || !mounted) return;
    try {
      final plan = await RestoreService.validateBytes(bytes);
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder:
            (c) => AlertDialog(
              title: const Text('Xem trước khôi phục'),
              content: Text(
                'Ngày sao lưu: ${plan.createdAt}\nPhiên bản: ${plan.appVersion}\nSinh nhật: ${plan.birthdayCount}\nẢnh: ${plan.photoCount}\nCảnh báo: ${plan.warnings.length}\nChế độ: Gộp dữ liệu',
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
      if (ok != true || !mounted) return;
      final result = await restore(context).apply(plan);
      if (mounted)
        showDialog<void>(
          context: context,
          builder:
              (c) => AlertDialog(
                title: const Text('Kết quả khôi phục'),
                content: Text(
                  'Đã khôi phục: ${result.restored}\nBỏ qua: ${result.skipped}\nXung đột: ${result.conflicts}\nẢnh: ${result.photosRestored}\nẢnh lỗi: ${result.photosFailed}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bản sao lưu không hợp lệ hoặc không được hỗ trợ.'),
          ),
        );
    }
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
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
              ),
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Khôi phục dữ liệu'),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
              ),
        ),
      ],
    ),
  );
}
