import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/auth_gate.dart';
import '../core/logging/app_logger.dart';
import '../core/theme/app_theme.dart';
import '../features/reminders/services/legacy_schedule_migrator.dart';
import '../features/reminders/services/legacy_v3_migrator.dart';
import '../features/reminders/services/notification_reconciler.dart';
import '../features/reminders/services/notification_timezone_bootstrap.dart';
import '../features/update/services/app_update_service.dart';
import '../services/notification_service.dart';
import 'dependencies.dart';

class BirthdayReminderApp extends StatefulWidget {
  const BirthdayReminderApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<BirthdayReminderApp> createState() => _BirthdayReminderAppState();
}

class _BirthdayReminderAppState extends State<BirthdayReminderApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_initializePostFrameRuntime());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Background maintenance tick. Fires every time the app moves
  /// between foreground ↔ background or comes back from a screen-off
  /// state. This is how the "single-next reminder" gets replenished
  /// after the OS fires it: the user backgrounds / opens the app, the
  /// reconciler detects no future pending entry, and schedules next
  /// year's single reminder.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.resumed) {
      _runMaintenance();
    }
  }

  Future<void> _runMaintenance() async {
    try {
      final reconciler = context.read<NotificationReconciler>();
      final result = await reconciler.reconcile();
      AppLogger.info(
        'maintenance',
        'lifecycle state ok scheduled=${result.scheduled} cancelled=${result.cancelled}',
      );
    } catch (e) {
      AppLogger.warn('maintenance', 'failed: $e');
    }
  }

  Future<void> _initializePostFrameRuntime() async {
    if (!mounted) return;
    final stopwatch = Stopwatch()..start();

    try {
      // timezone
      const tzBootstrap = NotificationTimezoneBootstrap();
      await tzBootstrap.initialize();
      AppLogger.info(
        'startup',
        'timezone init ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      AppLogger.warn('startup', 'timezone init failed: $e');
      return;
    }
    stopwatch.reset();

    try {
      if (!mounted) return;
      final notification = context.read<NotificationService>();
      await notification.initialize();
      AppLogger.info(
        'startup',
        'notification init ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      AppLogger.warn('startup', 'notification init failed: $e');
      return;
    }
    stopwatch.reset();

    try {
      if (!mounted) return;
      final v1 = context.read<LegacyScheduleMigrator>();
      final c1 = await v1.runIfNeeded();
      AppLogger.info(
        'migrator',
        'v1->v2 cancelled=$c1 ${stopwatch.elapsedMilliseconds}ms',
      );
      stopwatch.reset();

      if (!mounted) return;
      final v3 = context.read<LegacyToV3Migrator>();
      final c3 = await v3.runIfNeeded();
      AppLogger.info(
        'migrator',
        'v2->v3 cancelled=$c3 ${stopwatch.elapsedMilliseconds}ms',
      );
      stopwatch.reset();

      if (!mounted) return;
      final reconciler = context.read<NotificationReconciler>();
      final result = await reconciler.reconcile();
      AppLogger.info(
        'reconcile',
        'ok scheduled=${result.scheduled} cancelled=${result.cancelled} ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      AppLogger.warn('startup/runtime', 'migration/reconcile failed: $e');
    } finally {
      stopwatch.stop();
    }

    // Non-critical update check (don't block startup)
    try {
      if (!mounted) return;
      final updateService = context.read<AppUpdateService>();
      // Schedule check with delay to not interfere with first frame
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          updateService.checkForUpdates(manual: false);
        }
      });
    } catch (e) {
      AppLogger.warn('startup', 'update check init failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppDependencies.providers(widget.prefs),
      child: MaterialApp(
        title: 'Nhắc Sinh Nhật',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN'), Locale('vi')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AuthGate(),
      ),
    );
  }
}
