import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/birthday_controller.dart';
import '../../ai/views/ai_trial_view.dart';
import '../../backup/presentation/backup_restore_screen.dart';
import '../../../l10n/l10n_extensions.dart';
import '../widgets/ai_settings_card.dart';
import '../widgets/app_info_card.dart';
import '../widgets/notification_settings_card.dart';
import '../widgets/reminder_settings_card.dart';
import '../widgets/language_settings_card.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BirthdayController>();
    final runtimeUid = controller.isAuthenticated ? 'authenticated' : 'local';
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: context.l10n.aiTrial,
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
                    context.l10n.sessionStatus,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.account_circle),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.mode,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        runtimeUid == 'authenticated'
                            ? context.l10n.authenticated
                            : context.l10n.localMode,
                      ),
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
          LanguageSettingsCard(),
          const SizedBox(height: 16),
          const BackupSettingsCard(),
          const SizedBox(height: 16),
          const AiSettingsCard(),
          const SizedBox(height: 16),
          const AppInfoCard(),
        ],
      ),
    );
  }
}
