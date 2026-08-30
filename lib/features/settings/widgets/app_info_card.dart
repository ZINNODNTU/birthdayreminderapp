import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../services/notification_service.dart';
import '../../update/views/update_screen.dart';

class AppInfoCard extends StatefulWidget {
  const AppInfoCard({super.key});

  @override
  State<AppInfoCard> createState() => _AppInfoCardState();
}

class _AppInfoCardState extends State<AppInfoCard> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _info = info);
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin ứng dụng',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              info == null
                  ? 'Đang tải…'
                  : '${info.appName} — phiên bản ${info.version} (build ${info.buildNumber})',
            ),
            Text('Kênh test: ${NotificationService.testChannelId}'),
            Text('Kênh chính: ${NotificationService.androidChannelId}'),
            Text('ID thông báo thử: ${NotificationService.testNotificationId}'),
            Text(
              'ID thông báo thử đặt lịch: ${NotificationService.scheduledTestNotificationId}',
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.system_update),
              title: const Text('Cập nhật ứng dụng'),
              subtitle: const Text('Kiểm tra phiên bản mới'),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpdateScreen()),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
