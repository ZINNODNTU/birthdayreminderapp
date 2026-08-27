import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';
import '../services/notification_service.dart';
import '../features/reminders/services/notification_timezone_bootstrap.dart';

/// Resolved SharedPreferences instance. The provider tree in
/// `dependencies.dart` reads from this static field rather than
/// calling `SharedPreferences.getInstance()` again.
class BootstrappedPreferences {
  static SharedPreferences? instance;
}

/// Single entry point for app startup. Returns the resolved
/// `SharedPreferences` instance so the caller can build the provider
/// tree with it.
///
/// Order matters:
/// 1. Ensure Flutter bindings are live.
/// 2. Initialise timezone (the plugin needs it before scheduling).
/// 3. Initialise SharedPreferences.
/// 4. Initialize Firebase.
/// 5. Pre-load locale data the UI depends on.
/// 6. Initialise the notification plugin (does not request
///    permissions yet).
class AppBootstrap {
  const AppBootstrap._();

  static Future<SharedPreferences> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppLogger.info('bootstrap', 'start');

    await const NotificationTimezoneBootstrap().initialize();
    AppLogger.info('bootstrap', 'tz ready');

    final prefs = await SharedPreferences.getInstance();
    BootstrappedPreferences.instance = prefs;
    AppLogger.info('bootstrap', 'prefs ready');

    await Firebase.initializeApp();
    AppLogger.info('bootstrap', 'firebase ready');

    await initializeDateFormatting(AppConfig.primaryLocale);
    AppLogger.info('bootstrap', 'locale data ready');

    await NotificationService().initialize();
    AppLogger.info('bootstrap', 'notifications ready');

    return prefs;
  }
}
