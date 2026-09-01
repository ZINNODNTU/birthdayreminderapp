class FirestoreSchema {
  const FirestoreSchema._();

  static const version = 2;
  static const users = 'users';
  static const birthdays = 'birthdays';
  static const legacyData = 'legacyData';

  static final RegExp uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool isUuidV4(String value) => uuidV4.hasMatch(value);
}
