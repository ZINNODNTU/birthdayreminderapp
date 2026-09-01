// Mocktail needs to implement a sealed class for the mapper tests.
// This is the canonical workaround used by the firebase test suite.
// ignore_for_file: subtype_of_sealed_class

import 'package:birthdayreminderapp/features/birthdays/data/birthday_firestore_mapper.dart';
import 'package:birthdayreminderapp/models/birthday.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDocSnap extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

DocumentSnapshot<Map<String, dynamic>> _doc(
  String id,
  Map<String, dynamic>? data,
) {
  final m = _MockDocSnap();
  when(() => m.id).thenReturn(id);
  when(() => m.data()).thenReturn(data);
  when(() => m.exists).thenReturn(data != null);
  return m;
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
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('BirthdayFirestoreMapper', () {
    const mapper = BirthdayFirestoreMapper();

    test('toFirestore without photo omits photo fields', () {
      final map = mapper.toFirestore(_sampleBirthday());
      expect(map.containsKey('photoBase64'), false);
      expect(map.containsKey('photoMimeType'), false);
      expect(map.containsKey('photoSize'), false);
      expect(map.containsKey('photoHash'), false);
      expect(map.containsKey('photoUpdatedAt'), false);
    });

    test('toFirestore with photo includes photo fields', () {
      final photo = BirthdayCloudPhoto(
        photoBase64: 'BASE64PAYLOAD',
        mimeType: 'image/jpeg',
        size: 12345,
        hash: 'abc',
        updatedAt: DateTime(2024, 5, 6),
      );
      final map = mapper.toFirestore(_sampleBirthday(), photo: photo);
      expect(map['photoBase64'], 'BASE64PAYLOAD');
      expect(map['photoMimeType'], 'image/jpeg');
      expect(map['photoSize'], 12345);
      expect(map['photoHash'], 'abc');
      expect(map['photoUpdatedAt'], isA<Timestamp>());
    });

    test('toFirestore with deletePhoto marks fields for deletion', () {
      final map = mapper.toFirestore(_sampleBirthday(), deletePhoto: true);
      expect(map['photoBase64'], isA<FieldValue>());
      expect(map['photoMimeType'], isA<FieldValue>());
      expect(map['photoSize'], isA<FieldValue>());
      expect(map['photoHash'], isA<FieldValue>());
      expect(map['photoUpdatedAt'], isA<FieldValue>());
    });

    test('fromFirestore with no photo returns record without photo', () {
      final snap = _doc('b1', {
        'id': 'b1',
        'name': 'Lan',
        'calendarType': 'solar',
        'solarBirthday': Timestamp.fromDate(DateTime(2000, 5, 15)),
        'lunar': {'day': 12, 'month': 4, 'year': 2000, 'isLeapMonth': false},
        'reminder': {
          'enabled': true,
          'daysBefore': 0,
          'hour': 9,
          'minute': 0,
          'repeatAnnually': true,
        },
        'schemaVersion': 1,
      });
      final record = mapper.fromFirestore(snap)!;
      expect(record.birthday.name, 'Lan');
      expect(record.photo, isNull);
    });

    test('fromFirestore with photo populates the DTO fields', () {
      final snap = _doc('b1', {
        'id': 'b1',
        'name': 'Lan',
        'calendarType': 'solar',
        'solarBirthday': Timestamp.fromDate(DateTime(2000, 5, 15)),
        'lunar': {'day': 12, 'month': 4, 'year': 2000, 'isLeapMonth': false},
        'reminder': {
          'enabled': true,
          'daysBefore': 0,
          'hour': 9,
          'minute': 0,
          'repeatAnnually': true,
        },
        'schemaVersion': 1,
        'photoBase64': 'ABCD',
        'photoMimeType': 'image/jpeg',
        'photoSize': 4242,
        'photoHash': 'deadbeef',
        'photoUpdatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });
      final record = mapper.fromFirestore(snap)!;
      expect(record.photo, isNotNull);
      expect(record.photo!.base64, 'ABCD');
      expect(record.photo!.size, 4242);
      expect(record.photo!.hash, 'deadbeef');
      expect(record.photo!.updatedAt, DateTime(2024, 1, 1));
    });

    test('legacy cloud record without photo fields does not crash', () {
      final snap = _doc('b2', {
        'id': 'b2',
        'name': 'Hung',
        'calendarType': 'solar',
        'solarBirthday': Timestamp.fromDate(DateTime(1990, 1, 1)),
        'lunar': null,
        'reminder': {
          'enabled': false,
          'daysBefore': 0,
          'hour': 0,
          'minute': 0,
          'repeatAnnually': false,
        },
        'schemaVersion': 1,
      });
      final record = mapper.fromFirestore(snap)!;
      expect(record.birthday.name, 'Hung');
      expect(record.photo, isNull);
    });

    test('record without name returns null', () {
      expect(mapper.fromFirestore(_doc('b3', {'id': 'b3'})), isNull);
      expect(mapper.fromFirestore(_doc('x', null)), isNull);
    });
  });
}
