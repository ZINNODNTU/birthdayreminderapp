import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:birthdayreminderapp/core/db/sync_status.dart';
import 'package:birthdayreminderapp/features/birthdays/data/local_birthday_repository.dart';
import 'package:birthdayreminderapp/models/birthday.dart';

import '../../helpers/in_memory_local_db.dart';

void main() {
  setUpAll(() => initSqfliteFfi());

  late InMemoryLocalDb host;
  late LocalBirthdayRepository repo;

  setUp(() async {
    host = await InMemoryLocalDb.create();
    repo = LocalBirthdayRepository(host.service);
  });

  tearDown(() async {
    await host.close();
  });

  Birthday sample({String id = 'b1'}) {
    return Birthday(
      id: id,
      name: 'User $id',
      solarBirthday: DateTime(2000, 1, 1),
      lunarBirthday: const LunarDateTime(day: 1, month: 1, year: 2000),
      calendarType: CalendarType.solar,
      remindBeforeDays: 0,
      remindTime: const TimeOfDay(hour: 9, minute: 0),
    );
  }

  test('createBirthday stamps timestamps and syncStatus', () async {
    await repo.createBirthday(sample());
    final fetched = (await repo.getBirthdays()).single;
    expect(fetched.createdAt, isNotNull);
    expect(fetched.updatedAt, isNotNull);
    expect(fetched.syncStatus, SyncStatus.localOnly);
  });

  test('createBirthday with ownerUid sets pendingUpload', () async {
    final owned = sample().copyWith(ownerUid: 'firebase-uid');
    await repo.createBirthday(owned);
    final fetched = (await repo.getBirthdays()).single;
    expect(fetched.syncStatus, SyncStatus.pendingUpload);
    expect(fetched.ownerUid, 'firebase-uid');
  });

  test('updateBirthday bumps updatedAt but keeps createdAt', () async {
    await repo.createBirthday(sample());
    final first = (await repo.getBirthdays()).single;
    final createdAt = first.createdAt;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.updateBirthday(first.copyWith(name: 'Renamed'));
    final second = (await repo.getBirthdays()).single;
    expect(second.name, 'Renamed');
    expect(second.createdAt, createdAt);
    expect(second.updatedAt!.isAfter(createdAt!), isTrue);
  });

  test('deleteBirthday removes the row', () async {
    await repo.createBirthday(sample(id: 'a'));
    await repo.createBirthday(sample(id: 'b'));
    await repo.deleteBirthday('a');
    final remaining = await repo.getBirthdays();
    expect(remaining.length, 1);
    expect(remaining.first.id, 'b');
  });

  test('getBirthday returns null for unknown id', () async {
    expect(await repo.getBirthday('missing'), isNull);
  });
}
