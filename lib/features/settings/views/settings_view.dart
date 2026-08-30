import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/birthday_controller.dart';
import '../../ai/views/ai_trial_view.dart';
import '../../backup/presentation/backup_restore_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../widgets/ai_settings_card.dart';
import '../widgets/app_info_card.dart';
import '../widgets/notification_settings_card.dart';
import '../widgets/reminder_settings_card.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BirthdayController>();
    final runtimeUid = controller.isAuthenticated ? 'authenticated' : 'local';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        actions: [
          IconButton(
            tooltip: 'Thử AI',
            icon: const Icon(Icons.smart_toy),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiTrialView()),
                ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trạng thái phiên',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.account_circle),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Chế độ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(runtimeUid),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const NotificationSettingsCard(),
          const SizedBox(height: 16),
          const ReminderSettingsCard(),
          const SizedBox(height: 16),
          const BackupSettingsCard(),
          const SizedBox(height: 16),
          const AiSettingsCard(),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'HƯỚNG DẪN & TRỢ GIÚP',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                ListTile(
                  key: const Key('settings-onboarding-help'),
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('Hướng dẫn sử dụng'),
                  subtitle: const Text(
                    'Xem lại cách sử dụng Birthday Reminder',
                  ),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen(manual: true),
                        ),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppInfoCard(),
        ],
      ),
    );
  }
}
