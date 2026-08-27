import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:birthdayreminderapp/core/auth/auth_failure.dart';
import 'package:birthdayreminderapp/core/auth/auth_repository.dart';
import 'package:birthdayreminderapp/features/auth/views/auth_screen.dart';
import '../../helpers/fake_auth_repository.dart';

class _DelayedAuthRepository extends FakeAuthRepository {
  @override
  Future<void> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    await super.signInWithEmail(email, password);
  }
}

Widget _wrap(AuthRepository repo, Widget child) {
  return Provider<AuthRepository>.value(
    value: repo,
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('AuthScreen shows email and password fields', (tester) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(_wrap(repo, const AuthScreen()));

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Đăng nhập'), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.text('Chưa có tài khoản? Đăng ký'), findsOneWidget);
  });

  testWidgets('AuthScreen switches to register form when toggle tapped', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(_wrap(repo, const AuthScreen()));

    expect(find.text('Chưa có tài khoản? Đăng ký'), findsOneWidget);

    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Đăng ký'), findsOneWidget);
    expect(find.text('Đã có tài khoản? Đăng nhập'), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsNothing);
  });

  testWidgets('AuthScreen calls signIn on valid login submit', (tester) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(_wrap(repo, const AuthScreen()));

    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pump();

    expect(repo.signInCalls, 1);
    expect(repo.lastSignInEmail, 'test@example.com');
    expect(repo.lastSignInPassword, 'password123');
    expect(repo.currentUser, isNotNull);
    expect(repo.currentUser?.email, 'test@example.com');
  });

  testWidgets('AuthScreen shows friendly message on failed signIn', (
    tester,
  ) async {
    final repo =
        FakeAuthRepository()..signInFailure = AuthFailureInvalidCredential();
    await tester.pumpWidget(_wrap(repo, const AuthScreen()));

    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pump();

    expect(find.text('Sai email hoặc mật khẩu'), findsOneWidget);
  });

  testWidgets('AuthScreen shows loading indicator and blocks duplicate submit', (
    tester,
  ) async {
    final repo = _DelayedAuthRepository();
    await tester.pumpWidget(_wrap(repo, const AuthScreen()));

    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pump();

    // Button is replaced by a progress indicator -> double-submit is impossible.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Đăng nhập'), findsNothing);

    // Let the 500ms delay finish and confirm signIn actually ran.
    await tester.pumpAndSettle();
    expect(repo.signInCalls, 1);
  });

  testWidgets('AuthScreen validates empty email', (tester) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(_wrap(repo, const AuthScreen()));

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pump();

    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(repo.signInCalls, 0);
  });

  testWidgets('AuthScreen rejects invalid email format', (tester) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(_wrap(repo, const AuthScreen()));

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pump();

    expect(find.text('Email không hợp lệ'), findsOneWidget);
    expect(repo.signInCalls, 0);
  });

  testWidgets('AuthScreen validates empty password', (tester) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(_wrap(repo, const AuthScreen()));

    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, '');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pump();

    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    expect(repo.signInCalls, 0);
  });

  testWidgets('AuthScreen calls register on valid register submit', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(_wrap(repo, const AuthScreen()));

    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'new@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng ký'));
    await tester.pump();

    expect(repo.registerCalls, 1);
    expect(repo.lastRegisterEmail, 'new@example.com');
    expect(repo.lastRegisterPassword, 'password123');
  });

  testWidgets('AuthScreen shows friendly message when email already in use', (
    tester,
  ) async {
    final repo =
        FakeAuthRepository()..registerFailure = AuthFailureEmailAlreadyInUse();
    await tester.pumpWidget(_wrap(repo, const AuthScreen()));

    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'dup@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng ký'));
    await tester.pump();

    expect(find.text('Email đã được sử dụng'), findsOneWidget);
  });

  testWidgets('AuthScreen rejects weak password during register', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(_wrap(repo, const AuthScreen()));

    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'weak@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng ký'));
    await tester.pump();

    expect(find.text('Mật khẩu phải có ít nhất 6 ký tự'), findsOneWidget);
    expect(repo.registerCalls, 0);
  });

  testWidgets('AuthScreen shows friendly weak-password message from repo', (
    tester,
  ) async {
    final repo =
        FakeAuthRepository()..registerFailure = AuthFailureWeakPassword();
    await tester.pumpWidget(_wrap(repo, const AuthScreen()));

    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'weak@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng ký'));
    await tester.pump();

    expect(find.text('Mật khẩu quá yếu (tối thiểu 6 ký tự)'), findsOneWidget);
  });

  testWidgets('AuthScreen forgot password calls sendPasswordResetEmail', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(_wrap(repo, const AuthScreen()));

    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pump();

    expect(repo.resetCalls, 1);
    expect(repo.lastResetEmail, 'test@example.com');
    expect(find.text('Email đặt lại mật khẩu đã được gửi'), findsOneWidget);
  });

  testWidgets('AuthScreen forgot password validates empty email', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(_wrap(repo, const AuthScreen()));

    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pump();

    expect(
      find.text('Vui lòng nhập email để đặt lại mật khẩu'),
      findsOneWidget,
    );
    expect(repo.resetCalls, 0);
  });
}
