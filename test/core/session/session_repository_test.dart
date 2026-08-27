import 'package:birthdayreminderapp/core/session/app_session_mode.dart';
import 'package:birthdayreminderapp/core/session/session_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('local mode disabled by default', () async {
    final repo = SessionRepository();
    expect(await repo.isLocalModeEnabled(), isFalse);
  });

  test('enabling local mode persists across new instance', () async {
    final repo = SessionRepository();
    await repo.setLocalModeEnabled(true);
    expect(await repo.isLocalModeEnabled(), isTrue);

    final repo2 = SessionRepository();
    expect(await repo2.isLocalModeEnabled(), isTrue);
  });

  test(
    'resolveMode returns unauthenticated when not auth and local off',
    () async {
      final repo = SessionRepository();
      expect(
        await repo.resolveMode(isAuthenticated: false),
        AppSessionMode.unauthenticated,
      );
    },
  );

  test('resolveMode returns authenticated when authenticated', () async {
    final repo = SessionRepository();
    expect(
      await repo.resolveMode(isAuthenticated: true),
      AppSessionMode.authenticated,
    );
  });

  test(
    'resolveMode returns local when local enabled and not authenticated',
    () async {
      final repo = SessionRepository();
      await repo.setLocalModeEnabled(true);
      expect(
        await repo.resolveMode(isAuthenticated: false),
        AppSessionMode.local,
      );
    },
  );

  test('authenticated always wins over local', () async {
    final repo = SessionRepository();
    await repo.setLocalModeEnabled(true);
    expect(
      await repo.resolveMode(isAuthenticated: true),
      AppSessionMode.authenticated,
    );
  });

  test('clearLocalMode flips flag back', () async {
    final repo = SessionRepository();
    await repo.setLocalModeEnabled(true);
    await repo.clearLocalMode();
    expect(await repo.isLocalModeEnabled(), isFalse);
  });
}
