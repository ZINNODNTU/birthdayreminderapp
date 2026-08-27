import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/auth_gate.dart';
import '../core/logging/app_logger.dart';
import '../core/theme/app_theme.dart';
import '../features/reminders/services/notification_reconciler.dart';
import 'dependencies.dart';

/// Root widget. Owns the [MaterialApp] and the provider tree.
/// Routing stays inside [AuthGate] for now (login/home bifurcation);
/// named routes will be introduced in Phase 6 once the router shell
/// is needed.
///
/// Phase 4: kicks off [NotificationReconciler.reconcile] after the
/// first frame. Failures are logged but never thrown.
class BirthdayReminderApp extends StatefulWidget {
  const BirthdayReminderApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<BirthdayReminderApp> createState() => _BirthdayReminderAppState();
}

class _BirthdayReminderAppState extends State<BirthdayReminderApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final reconciler = context.read<NotificationReconciler>();
        final result = await reconciler.reconcile();
        AppLogger.info(
          'reconcile',
          'ok scheduled=${result.scheduled} cancelled=${result.cancelled}',
        );
      } catch (e) {
        AppLogger.warn('reconcile', 'failed: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppDependencies.providers(widget.prefs),
      child: MaterialApp(
        title: 'Birthday Reminder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}
