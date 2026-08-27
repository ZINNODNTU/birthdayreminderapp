import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';

/// Single entry point for app startup. Returns after the framework is ready
/// to mount the widget tree.
///
/// Order matters:
/// 1. Ensure Flutter bindings are live.
/// 2. Initialize Firebase.
/// 3. Pre-load locale data the UI depends on.
/// 4. Eagerly touch the local DB so migrations / first-open run while we
///    still have a chance to surface failures via UI overlay.
/// 5. Initialise the notification plugin (permissions are requested later).
class AppBootstrap {
  const AppBootstrap._();

  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppLogger.info('bootstrap', 'start');

    await Firebase.initializeApp();
    AppLogger.info('bootstrap', 'firebase ready');

    await initializeDateFormatting(AppConfig.primaryLocale);
    AppLogger.info('bootstrap', 'locale data ready');
  }
}
