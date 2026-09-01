import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../services/notification_service.dart';
import '../../update/views/update_screen.dart';
import '../../../l10n/l10n_extensions.dart';

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
              context.l10n.appInformation,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              info == null
                  ? context.l10n.loading
                  : context.l10n.appVersionInfo(
                      info.appName,
                      info.version,
                      info.buildNumber,
                    ),
            ),
            Text(context.l10n.testChannel(NotificationService.testChannelId)),
            Text(
              context.l10n.mainChannel(NotificationService.androidChannelId),
            ),
            Text(
              context.l10n.testNotificationId(
                NotificationService.testNotificationId.toString(),
              ),
            ),
            Text(
              context.l10n.scheduledTestNotificationId(
                NotificationService.scheduledTestNotificationId.toString(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.system_update),
              title: Text(context.l10n.updateApp),
              subtitle: Text(context.l10n.checkNewVersion),
              onTap: () => Navigator.push(
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
