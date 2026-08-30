import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:birthdayreminderapp/features/settings/widgets/app_info_card.dart';

void main() {
  testWidgets('AppInfoCard renders "Cập nhật ứng dụng" tile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppInfoCard())),
    );
    // Allow PackageInfo.fromPlatform() future to settle.
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Cập nhật ứng dụng'), findsOneWidget);
    expect(find.text('Kiểm tra phiên bản mới'), findsOneWidget);
    expect(find.byIcon(Icons.system_update), findsOneWidget);
  });
}
