import 'dart:async';
import 'dart:developer' as devtools;

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/logging/app_logger.dart';
import '../features/reminders/domain/reminder_schedule.dart';

/// Structured diagnostic returned by [NotificationService.showTestNotification].
class NotificationTestResult {
  const NotificationTestResult({
    required this.initialized,
    required this.permissionGranted,
    required this.notificationsEnabled,
    required this.channelCreated,
    required this.showCalled,
    this.error,
  });

  final bool initialized;
  final bool permissionGranted;
  final bool notificationsEnabled;
  final bool channelCreated;
  final bool showCalled;
  final Object? error;

  bool get ok =>
      initialized &&
      permissionGranted &&
      notificationsEnabled &&
      channelCreated &&
      showCalled &&
      error == null;
}

/// Result of the scheduled diagnostic notification.
class ScheduledTestResult {
  const ScheduledTestResult({
    required this.scheduled,
    required this.scheduledAt,
    required this.permissionGranted,
    required this.notificationsEnabled,
    required this.exactAvailable,
    required this.pendingConfirmed,
    this.error,
    this.failureReason,
  });

  final bool scheduled;
  final DateTime? scheduledAt;
  final bool permissionGranted;
  final bool notificationsEnabled;
  final bool exactAvailable;
  final bool pendingConfirmed;
  final Object? error;
  final String? failureReason;

  bool get ok =>
      scheduled && pendingConfirmed && error == null && failureReason == null;
}

/// Aggregate notification status snapshot used by the Settings UI.
class NotificationRuntimeSnapshot {
  const NotificationRuntimeSnapshot({
    required this.permissionGranted,
    required this.notificationsEnabled,
    required this.exactAvailable,
    required this.exactCanRequest,
    required this.tzLocalName,
    required this.deviceNow,
    required this.deviceUtc,
    required this.utcOffsetMinutes,
  });

  final bool permissionGranted;
  final bool notificationsEnabled;
  final bool exactAvailable;
  final bool exactCanRequest;
  final String tzLocalName;
  final DateTime deviceNow;
  final DateTime deviceUtc;
  final int utcOffsetMinutes;
}

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String androidChannelId = 'birthday_reminders';
  static const String androidChannelName = 'Birthday Reminders';
  static const String androidChannelDescription =
      'Nhắc nhở sinh nhật cho bạn bè và người thân.';

  static const String testChannelId = 'birthday_test_v1';
  static const String testChannelName = 'Thông báo thử';
  static const String testChannelDescription =
      'Kênh dùng để kiểm tra thông báo của Birthday Reminder.';

  static const int testNotificationId = 0x6E5F00D;
  static const int scheduledTestNotificationId = 0x6E5F00E;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        devtools.log('clicked: ${response.payload}');
      },
    );

    await _createTestChannel();

    _isInitialized = true;
    AppLogger.info('NotificationRuntime', 'initialized');
  }

  Future<void> _createTestChannel() async {
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (android == null) return;
    const channel = AndroidNotificationChannel(
      testChannelId,
      testChannelName,
      description: testChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await android.createNotificationChannel(channel);
    AppLogger.debug(
      'NotificationService',
      'test channel ensured: $testChannelId ($testChannelName)',
    );
  }

  Future<bool> requestNotificationPermission() async {
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<bool?> areNotificationsEnabled() async {
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (android == null) return true;
    final enabled = await android.areNotificationsEnabled();
    return enabled;
  }

  Future<bool?> canScheduleExactNotifications() async {
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (android == null) return null;
    return await android.canScheduleExactNotifications();
  }

  Future<void> requestExactAlarmsPermission() async {
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (android == null) return;
    try {
      await android.requestExactAlarmsPermission();
    } catch (e, st) {
      AppLogger.warn('NotificationRuntime', 'requestExactAlarms: $e\n$st');
    }
  }

  Future<NotificationRuntimeSnapshot> runtimeSnapshot() async {
    await initialize();
    final granted = await requestNotificationPermission();
    final enabled = await areNotificationsEnabled();
    final exact = await canScheduleExactNotifications();
    final now = DateTime.now();
    final utc = now.toUtc();
    final offset = now.timeZoneOffset.inMinutes;
    AppLogger.info(
      'NotificationRuntime',
      'tz=${tz.local.name} nowLocal=$now nowUtc=$utc utcOffset=${offset}m '
          'postGranted=$granted enabled=$enabled exact=$exact',
    );
    return NotificationRuntimeSnapshot(
      permissionGranted: granted,
      notificationsEnabled: enabled ?? false,
      exactAvailable: exact ?? false,
      exactCanRequest: exact == false,
      tzLocalName: tz.local.name,
      deviceNow: now,
      deviceUtc: utc,
      utcOffsetMinutes: offset,
    );
  }

  Future<bool> scheduleReminder(
    ReminderSchedule schedule, {
    required bool exact,
    Uint8List? avatarBytes,
  }) async {
    await initialize();
    try {
      final tzTime = tz.TZDateTime.from(schedule.scheduledAt, tz.local);
      await _plugin.zonedSchedule(
        schedule.notificationId,
        schedule.title,
        schedule.body,
        tzTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannelId,
            androidChannelName,
            channelDescription: androidChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            largeIcon:
                avatarBytes == null
                    ? null
                    : ByteArrayAndroidBitmap(avatarBytes),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode:
            exact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: schedule.payload,
      );
      AppLogger.info(
        'ReminderScheduler',
        'birthdayId=${schedule.birthdayId} '
            'occurrence=${schedule.occurrenceDate} '
            'scheduledAt=${tzTime.toLocal()} '
            'timezone=${tz.local.name} exact=$exact',
      );
      return true;
    } catch (e, st) {
      AppLogger.error('ReminderScheduler', e, st);
      return false;
    }
  }

  /// True when the plugin currently has [id] registered as a pending
  /// notification request. Use this to detect phantom schedule entries
  /// — the store believes an id is scheduled but the OS no longer has
  /// the alarm.
  Future<bool> isNotificationPending(int id) async {
    await initialize();
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.any((p) => p.id == id);
    } catch (e, st) {
      AppLogger.warn('NotificationService', 'isNotificationPending: $e\n$st');
      return false;
    }
  }

  /// Diagnostic 1-minute scheduled test. Uses the same path as the
  /// production birthday pipeline so a successful delivery here proves
  /// the entire Android alarm → receiver → notification chain is
  /// healthy.
  Future<ScheduledTestResult> scheduleOneMinuteDiagnostic({
    required String title,
    required String body,
  }) async {
    await initialize();
    final granted = await requestNotificationPermission();
    final enabled = await areNotificationsEnabled();
    final exact = await canScheduleExactNotifications();
    if (!granted) {
      return ScheduledTestResult(
        scheduled: false,
        scheduledAt: null,
        permissionGranted: false,
        notificationsEnabled: enabled ?? false,
        exactAvailable: exact ?? false,
        pendingConfirmed: false,
        failureReason: 'permission_denied',
        error: 'POST_NOTIFICATIONS not granted',
      );
    }
    if (enabled == false) {
      return ScheduledTestResult(
        scheduled: false,
        scheduledAt: null,
        permissionGranted: true,
        notificationsEnabled: false,
        exactAvailable: exact ?? false,
        pendingConfirmed: false,
        failureReason: 'notifications_disabled',
        error: 'OS-level notifications disabled',
      );
    }
    if (exact != true) {
      return ScheduledTestResult(
        scheduled: false,
        scheduledAt: null,
        permissionGranted: true,
        notificationsEnabled: true,
        exactAvailable: false,
        pendingConfirmed: false,
        failureReason: 'exact_alarm_unavailable',
        error: 'SCHEDULE_EXACT_ALARM not granted',
      );
    }
    try {
      final now = tz.TZDateTime.now(tz.local);
      final fireAt = now.add(const Duration(minutes: 1));
      AppLogger.info(
        'ScheduledDiag',
        'now=$now target=$fireAt timezone=${tz.local.name} exact=true '
            'id=$scheduledTestNotificationId',
      );
      await _plugin.zonedSchedule(
        scheduledTestNotificationId,
        title,
        body,
        fireAt,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            testChannelId,
            testChannelName,
            channelDescription: testChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      final pending = await _plugin.pendingNotificationRequests();
      final ok = pending.any((p) => p.id == scheduledTestNotificationId);
      AppLogger.info(
        'ScheduledDiag',
        'pending=$ok fireAt=$fireAt timezone=${tz.local.name}',
      );
      return ScheduledTestResult(
        scheduled: true,
        scheduledAt: fireAt,
        permissionGranted: true,
        notificationsEnabled: true,
        exactAvailable: true,
        pendingConfirmed: ok,
      );
    } catch (e, st) {
      AppLogger.error('ScheduledDiag', e, st);
      return ScheduledTestResult(
        scheduled: false,
        scheduledAt: null,
        permissionGranted: true,
        notificationsEnabled: true,
        exactAvailable: true,
        pendingConfirmed: false,
        failureReason: 'schedule_failed',
        error: e.toString(),
      );
    }
  }

  Future<ScheduledTestResult> scheduleTestNotification({
    required String title,
    required String body,
    Duration delay = const Duration(seconds: 10),
  }) async {
    AppLogger.debug(
      'NotificationTest',
      'scheduled start delay=${delay.inSeconds}s tz=${tz.local.name}',
    );
    await initialize();
    final permissionGranted = await requestNotificationPermission();
    final enabled = await areNotificationsEnabled();
    final notificationsEnabled = enabled ?? false;
    final exact = await canScheduleExactNotifications();
    final exactAvailable = exact ?? false;
    if (!permissionGranted) {
      AppLogger.warn('NotificationTest', 'permission denied');
      return _failed(
        permissionGranted: false,
        notificationsEnabled: notificationsEnabled,
        exactAvailable: exactAvailable,
        reason: 'permission_denied',
      );
    }
    if (!notificationsEnabled) {
      AppLogger.warn('NotificationTest', 'notifications disabled');
      return _failed(
        permissionGranted: true,
        notificationsEnabled: false,
        exactAvailable: exactAvailable,
        reason: 'notifications_disabled',
      );
    }
    if (!exactAvailable) {
      AppLogger.warn(
        'NotificationTest',
        'exact alarm unavailable -- refusing 10s test',
      );
      return _failed(
        permissionGranted: true,
        notificationsEnabled: true,
        exactAvailable: false,
        reason: 'exact_alarm_unavailable',
      );
    }
    final fireAt = tz.TZDateTime.now(tz.local).add(delay);
    final now = tz.TZDateTime.now(tz.local);
    if (!fireAt.isAfter(now)) {
      AppLogger.warn(
        'NotificationTest',
        'target not in future: fireAt=$fireAt now=$now',
      );
      return _failed(
        permissionGranted: true,
        notificationsEnabled: true,
        exactAvailable: true,
        reason: 'target_past',
      );
    }
    try {
      await _plugin.zonedSchedule(
        scheduledTestNotificationId,
        title,
        body,
        fireAt,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            testChannelId,
            testChannelName,
            channelDescription: testChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      AppLogger.info(
        'NotificationTest',
        'scheduled id=$scheduledTestNotificationId at=$fireAt exact=true',
      );
    } catch (e, st) {
      AppLogger.error('NotificationTest', e, st);
      return ScheduledTestResult(
        scheduled: false,
        scheduledAt: null,
        permissionGranted: true,
        notificationsEnabled: true,
        exactAvailable: true,
        pendingConfirmed: false,
        error: e,
        failureReason: 'schedule_failed',
      );
    }

    final pendingConfirmed = await _confirmPending(scheduledTestNotificationId);
    if (!pendingConfirmed) {
      AppLogger.warn(
        'NotificationTest',
        'pendingNotificationRequests did NOT contain diagnostic id',
      );
      return ScheduledTestResult(
        scheduled: false,
        scheduledAt: fireAt.toLocal(),
        permissionGranted: true,
        notificationsEnabled: true,
        exactAvailable: true,
        pendingConfirmed: false,
        failureReason: 'no_pending_request',
      );
    }

    return ScheduledTestResult(
      scheduled: true,
      scheduledAt: fireAt.toLocal(),
      permissionGranted: true,
      notificationsEnabled: true,
      exactAvailable: true,
      pendingConfirmed: true,
    );
  }

  ScheduledTestResult _failed({
    required bool permissionGranted,
    required bool notificationsEnabled,
    required bool exactAvailable,
    required String reason,
  }) {
    return ScheduledTestResult(
      scheduled: false,
      scheduledAt: null,
      permissionGranted: permissionGranted,
      notificationsEnabled: notificationsEnabled,
      exactAvailable: exactAvailable,
      pendingConfirmed: false,
      failureReason: reason,
    );
  }

  Future<bool> _confirmPending(int id) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      final found = pending.any((p) => p.id == id);
      AppLogger.debug(
        'NotificationTest',
        'pending probe id=$id found=$found count=${pending.length}',
      );
      return found;
    } catch (e, st) {
      AppLogger.warn('NotificationTest', 'pending probe failed: $e\n$st');
      return false;
    }
  }

  Future<bool> openAppNotificationSettings() async {
    const platform = MethodChannel('birthday_reminder/settings');
    try {
      final ok = await platform.invokeMethod<bool>(
        'openAppNotificationSettings',
      );
      AppLogger.debug('NotificationTest', 'openAppNotificationSettings ok=$ok');
      return ok ?? false;
    } catch (e, st) {
      AppLogger.error('NotificationTest', e, st);
      return false;
    }
  }

  Future<bool> openExactAlarmSettings() async {
    const platform = MethodChannel('birthday_reminder/settings');
    try {
      final ok = await platform.invokeMethod<bool>('openExactAlarmSettings');
      return ok ?? false;
    } catch (e, st) {
      AppLogger.warn('NotificationTest', 'openExactAlarm: $e\n$st');
      return false;
    }
  }

  Future<bool> cancel(int notificationId) async {
    await initialize();
    try {
      await _plugin.cancel(notificationId);
      return true;
    } catch (e) {
      devtools.log('cancel failed: $e');
      return false;
    }
  }

  Future<NotificationTestResult> showTestNotification({
    required String title,
    required String body,
  }) async {
    AppLogger.debug('NotificationTest', 'start title="$title"');
    await initialize();
    final initialized = _isInitialized;
    final permissionGranted = await requestNotificationPermission();
    final enabled = await areNotificationsEnabled();
    final notificationsEnabled = enabled ?? false;
    var channelCreated = false;
    try {
      await _createTestChannel();
      channelCreated = true;
    } catch (e) {
      AppLogger.warn('NotificationTest', 'createTestChannel failed: $e');
    }

    if (!initialized ||
        !permissionGranted ||
        !notificationsEnabled ||
        !channelCreated) {
      return NotificationTestResult(
        initialized: initialized,
        permissionGranted: permissionGranted,
        notificationsEnabled: notificationsEnabled,
        channelCreated: channelCreated,
        showCalled: false,
      );
    }

    try {
      await _plugin.show(
        testNotificationId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            testChannelId,
            testChannelName,
            channelDescription: testChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      return NotificationTestResult(
        initialized: true,
        permissionGranted: true,
        notificationsEnabled: true,
        channelCreated: true,
        showCalled: true,
      );
    } catch (e, st) {
      AppLogger.error('NotificationTest', e, st);
      return NotificationTestResult(
        initialized: true,
        permissionGranted: true,
        notificationsEnabled: true,
        channelCreated: true,
        showCalled: true,
        error: e,
      );
    }
  }
}
