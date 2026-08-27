import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_gate.dart';
import '../core/theme/app_theme.dart';
import 'dependencies.dart';

/// Root widget. Owns the [MaterialApp] and the provider tree. Routing stays
/// inside [AuthGate] for now (login/home bifurcation); named routes will be
/// introduced in Phase 6 once the router shell is needed.
class BirthdayReminderApp extends StatelessWidget {
  const BirthdayReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppDependencies.providers(),
      child: MaterialApp(
        title: 'Birthday Reminder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}
