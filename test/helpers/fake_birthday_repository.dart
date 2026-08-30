import 'dart:async';

import 'package:birthdayreminderapp/features/birthdays/data/birthday_repository.dart';
import 'package:birthdayreminderapp/models/birthday.dart';

/// A fake in-memory implementation of [BirthdayRepository] for testing.
class FakeBirthdayRepository implements BirthdayRepository {
  final Map<String, Birthday> _store = {};
  final _controller = StreamController<List<Birthday>>.broadcast();

  @override
  Future<void> createBirthday(Birthday birthday) async {
    _store[birthday.id] = birthday;
    _emit();
  }

  @override
  Future<void> updateBirthday(Birthday birthday) async {
    _store[birthday.id] = birthday;
    _emit();
  }

  @override
  Future<void> upsertBirthday(Birthday birthday) async {
    _store[birthday.id] = birthday;
    _emit();
  }

  @override
  Future<Birthday?> getBirthday(String id) async {
    return _store[id];
  }

  @override
  Future<List<Birthday>> getBirthdays() async {
    return _store.values.toList();
  }

  @override
  Future<List<Birthday>> getAllForSync() async {
    return _store.values.toList();
  }

  @override
  Future<void> deleteBirthday(String id) async {
    _store.remove(id);
    _emit();
  }

  @override
  Stream<List<Birthday>> watchBirthdays() {
    return _controller.stream;
  }

  void _emit() {
    _controller.add(_store.values.toList());
  }
}
