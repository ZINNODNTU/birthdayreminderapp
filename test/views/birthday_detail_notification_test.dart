import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthdayreminderapp/controllers/birthday_controller.dart';
import 'package:birthdayreminderapp/core/db/sync_status.dart';
import 'package:birthdayreminderapp/features/birthdays/data/birthday_repository.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/birthday_engine.dart';
import 'package:birthdayreminderapp/features/birthdays/domain/birthday_occurrence.dart';
import 'package:birthdayreminderapp/features/ai/data/ai_config_repository.dart';
import 'package:birthdayreminderapp/features/ai/domain/ai_provider.dart';
import 'package:birthdayreminderapp/features/ai/services/ai_client.dart';
import 'package:birthdayreminderapp/features/ai/services/birthday_ai_service.dart';
import 'package:birthdayreminderapp/features/reminders/data/reminder_schedule_store.dart';
import 'package:birthdayreminderapp/features/reminders/domain/reminder_failure.dart';
import 'package:birthdayreminderapp/features/reminders/services/notification_id_factory.dart';
import 'package:birthdayreminderapp/features/reminders/services/notification_permission_service.dart';
import 'package:birthdayreminderapp/features/reminders/services/reminder_scheduler.dart';
import 'package:birthdayreminderapp/models/birthday.dart';
import 'package:birthdayreminderapp/services/notification_service.dart';
import 'package:birthdayreminderapp/views/birthday_detail_view.dart';

import '../helpers/fake_notification_service.dart';

import 'package:birthdayreminderapp/l10n/app_localizations.dart';
import 'package:birthdayreminderapp/services/locale_service.dart';

class _FakeRepo implements BirthdayRepository {
  @override
  Future<List<Birthday>> getBirthdays() async => const <Birthday>[];

  @override
  Future<List<Birthday>> getAllForSync() async => const <Birthday>[];
  @override
  Future<Birthday?> getBirthday(String id) async => null;
  @override
  Future<void> createBirthday(Birthday birthday) async {}
  @override
  Future<void> updateBirthday(Birthday birthday) async {}
  @override
  Future<void> upsertBirthday(Birthday birthday) async {}
  @override
  Future<void> deleteBirthday(String id) async {}
  @override
  Stream<List<Birthday>> watchBirthdays() async* {
    yield const <Birthday>[];
  }
}

class _NoopEngine implements BirthdayEngine {
  @override
  DateTime occurrenceInYear(Birthday b, int year) =>
      DateTime(year, b.solarBirthday.month, b.solarBirthday.day);
  @override
  DateTime nextOccurrence(Birthday b, {DateTime? from}) => DateTime.now();
  @override
  int daysUntilNextBirthday(Birthday b, {DateTime? from}) => 0;
  @override
  int ageAtOccurrence(Birthday b, {DateTime? occurrence}) => 0;
  @override
  BirthdayOccurrence snapshot(Birthday birthday, {DateTime? from}) =>
      BirthdayOccurrence(date: DateTime.now(), age: 0, daysUntil: 0);
}

class _NoopStore implements ReminderScheduleStore {
  @override
  Map<String, ManagedReminderEntry> loadAll() => {};
  @override
  Future<void> saveAll(Map<String, ManagedReminderEntry> entries) async {}
  @override
  Future<void> clear() async {}
  @override
  int get schemaVersion => ReminderScheduleStore.currentSchemaVersion;
  @override
  Future<void> setSchemaVersion(int v) async {}
}

class _NoopScheduler extends ReminderScheduler {
  _NoopScheduler({required FakeNotificationService notif})
    : super(
        engine: _NoopEngine(),
        idFactory: NotificationIdFactory(),
        notificationService: notif,
        permissionService: NotificationPermissionService(),
        store: _NoopStore(),
      );

  @override
  Future<ReminderScheduleResult> scheduleNext(Birthday birthday) async {
    return ReminderScheduleResult.ok(scheduledCount: 0);
  }

  @override
  Future<void> cancelAllFor(String birthdayId) async {}
}

Birthday _sampleBirthday() {
  return Birthday(
    id: 'b1',
    name: 'Lan',
    solarBirthday: DateTime(2000, 5, 15),
    lunarBirthday: const LunarDateTime(day: 12, month: 4, year: 2000),
    calendarType: CalendarType.solar,
    remindBeforeDays: 0,
    remindTime: const TimeOfDay(hour: 9, minute: 0),
    syncStatus: SyncStatus.synced,
  );
}

Widget _wrap(BirthdayController controller, FakeNotificationService notif) {
  final store = _NoopStore();
  return MultiProvider(
    providers: [
      Provider<NotificationService>.value(value: notif),
      Provider<ReminderScheduleStore>.value(value: store),
      Provider<BirthdayAiService>(
        create:
            (_) => BirthdayAiService(
              configRepository: _StubAiConfigRepository(),
              client: _StubAiClient(),
            ),
      ),
      ChangeNotifierProvider<BirthdayController>.value(value: controller),
      ChangeNotifierProvider<LocaleService>(
        create: (_) => LocaleService(sharedPrefs),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('vi')],
      home: BirthdayDetailView(birthday: _sampleBirthday()),
    ),
  );
}

BirthdayController _makeController(FakeNotificationService notif) {
  return BirthdayController(
    repository: _FakeRepo(),
    reminderScheduler: _NoopScheduler(notif: notif),
    notificationService: notif,
    engine: _NoopEngine(),
  );
}

class _StubAiConfigRepository implements AiConfigRepository {
  @override
  Future<String?> readApiKey(AiProviderType provider) async => null;
  @override
  Future<SecureKeyResult> writeApiKey(
    AiProviderType provider,
    String key,
  ) async => SecureKeyResult.failure('test_stub');
  @override
  Future<SecureKeyResult> clearApiKey(AiProviderType provider) async =>
      SecureKeyResult.failure('test_stub');
  @override
  Future<bool> hasApiKey(AiProviderType provider) async => false;
  @override
  AiProviderConfig loadConfig() => const AiProviderConfig();
  @override
  Future<void> saveConfig(AiProviderConfig config) async {}
}

class _StubAiClient implements AiClient {
  @override
  Future<AiConnectionResult> chat({
    required AiProviderConfig config,
    required String apiKey,
    required String prompt,
    AiRequestOptions? options,
  }) async => AiConnectionResult.failure(code: 'test_stub');
  @override
  Future<List<String>> listModels({
    required AiProviderConfig config,
    required String apiKey,
  }) async => const [];
  @override
  Future<AiConnectionResult> testConnection({
    required AiProviderConfig config,
    required String apiKey,
  }) async => AiConnectionResult.failure(code: 'test_stub');
}

late SharedPreferences sharedPrefs;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();
    await initializeDateFormatting('vi_VN');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'tap "Thông báo thử" calls showTestNotification and shows success feedback',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notif = FakeNotificationService();
      final controller = _makeController(notif);
      await tester.pumpWidget(_wrap(controller, notif));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Thông báo thử'));
      await tester.tap(find.text('Thông báo thử'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(notif.testShown, hasLength(1));
      expect(notif.testShown.first.title, contains('Lan'));
      expect(find.text('Đã gửi thông báo thử'), findsOneWidget);
    },
  );

  testWidgets(
    'show permission-denied feedback when notificationsEnabled=false',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notif = FakeNotificationService(
        testResultOverride: const NotificationTestResult(
          initialized: true,
          permissionGranted: false,
          notificationsEnabled: false,
          channelCreated: true,
          showCalled: false,
        ),
      );
      final controller = _makeController(notif);
      await tester.pumpWidget(_wrap(controller, notif));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Thông báo thử'));
      await tester.tap(find.text('Thông báo thử'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Đã gửi thông báo thử'), findsNothing);
      expect(find.textContaining('Thông báo đang bị tắt'), findsOneWidget);
    },
  );

  testWidgets('show error feedback when service reports error', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notif = FakeNotificationService(
      testResultOverride: const NotificationTestResult(
        initialized: true,
        permissionGranted: true,
        notificationsEnabled: true,
        channelCreated: true,
        showCalled: true,
        error: 'boom',
      ),
    );
    final controller = _makeController(notif);
    await tester.pumpWidget(_wrap(controller, notif));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Thông báo thử'));
    await tester.tap(find.text('Thông báo thử'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('boom'), findsOneWidget);
  });
}
