import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:birthdayreminderapp/features/settings/widgets/app_info_card.dart';
import 'package:birthdayreminderapp/l10n/app_localizations.dart';
import 'package:birthdayreminderapp/services/locale_service.dart';

void main() {
  testWidgets('AppInfoCard renders "Cập nhật ứng dụng" tile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LocaleService>(
            create: (_) => LocaleService(
              SharedPreferences.getInstance() as SharedPreferences,
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [Locale('vi')],
          home: const Scaffold(body: AppInfoCard()),
        ),
      ),
    );
    // Allow PackageInfo.fromPlatform() future to settle.
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Cập nhật ứng dụng'), findsOneWidget);
    expect(find.text('Kiểm tra phiên bản mới'), findsOneWidget);
    expect(find.byIcon(Icons.system_update), findsOneWidget);
  });
}
