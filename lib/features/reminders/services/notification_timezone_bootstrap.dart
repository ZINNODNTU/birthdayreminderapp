import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Initialise the timezone database and set the local location to
/// whatever the device reports. Falls back to UTC on failure.
class NotificationTimezoneBootstrap {
  const NotificationTimezoneBootstrap();

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }
}
