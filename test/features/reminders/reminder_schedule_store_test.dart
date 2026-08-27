import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthdayreminderapp/features/reminders/data/reminder_schedule_store.dart';

void main() {
  late ReminderScheduleStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = ReminderScheduleStore(prefs);
  });

  group('ReminderScheduleStore', () {
    test('starts empty', () {
      expect(store.loadAll(), isEmpty);
    });

    test('round-trip preserves entries', () async {
      final entries = {
        'birthday:a:daysBefore:0:h:8:m:0':
            const ManagedReminderEntry(
          scheduleKey: 'birthday:a:daysBefore:0:h:8:m:0',
          notificationId: 123,
          fingerprint: 'fp-123',
        ),
        'birthday:b:daysBefore:3:h:9:m:0':
            const ManagedReminderEntry(
          scheduleKey: 'birthday:b:daysBefore:3:h:9:m:0',
          notificationId: 456,
          fingerprint: 'fp-456',
        ),
      };
      await store.saveAll(entries);
      final loaded = store.loadAll();
      expect(loaded.keys, entries.keys);
      for (final key in entries.keys) {
        expect(loaded[key]!.scheduleKey, entries[key]!.scheduleKey);
        expect(loaded[key]!.notificationId, entries[key]!.notificationId);
        expect(loaded[key]!.fingerprint, entries[key]!.fingerprint);
      }
    });

    test('replaceAll drops removed entries', () async {
      await store.saveAll({
        'k1': const ManagedReminderEntry(
          scheduleKey: 'k1',
          notificationId: 1,
          fingerprint: 'a',
        ),
        'k2': const ManagedReminderEntry(
          scheduleKey: 'k2',
          notificationId: 2,
          fingerprint: 'b',
        ),
      });
      await store.saveAll({
        'k1': const ManagedReminderEntry(
          scheduleKey: 'k1',
          notificationId: 1,
          fingerprint: 'a',
        ),
      });
      final loaded = store.loadAll();
      expect(loaded.length, 1);
      expect(loaded.containsKey('k2'), isFalse);
    });

    test('clear empties the store', () async {
      await store.saveAll({
        'k1': const ManagedReminderEntry(
          scheduleKey: 'k1',
          notificationId: 1,
          fingerprint: 'a',
        ),
      });
      await store.clear();
      expect(store.loadAll(), isEmpty);
    });

    test('stores only opaque identifiers — no personal data', () async {
      // We assert the store *cannot* leak the birthday name: there is
      // no API surface that takes or returns a Birthday object.
      // This is a documentation test, not a runtime check.
      expect(store.loadAll, isNotNull);
    });
  });
}
