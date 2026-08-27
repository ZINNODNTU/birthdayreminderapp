/// Centralised build-time constants. Keep small; per-feature config goes in
/// the feature folder.
class AppConfig {
  const AppConfig._();

  /// Vietnamese is the only locale the app currently ships with.
  static const String primaryLocale = 'vi';

  /// Bump when the local SQLite schema changes. Used by `LocalDBService`.
  static const int localSchemaVersion = 1;

  /// Bump when the persisted `Birthday` shape changes.
  static const int birthdaySchemaVersion = 1;
}
