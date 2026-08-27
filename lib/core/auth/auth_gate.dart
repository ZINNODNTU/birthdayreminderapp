import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/views/auth_screen.dart';
import '../../views/homepage.dart';
import '../session/app_session_mode.dart';
import '../session/session_controller.dart';

/// Decides between AuthScreen and Homepage based on
/// [SessionController.mode].
///
/// Behaviour preserved from Phase 0/1:
/// * unauthenticated → AuthScreen
/// * authenticated   → Homepage
///
/// New in Phase 2:
/// * local          → Homepage (with cloud features disabled)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    switch (session.mode) {
      case AppSessionMode.authenticated:
      case AppSessionMode.local:
        return const Homepage();
      case AppSessionMode.unauthenticated:
        return const AuthScreen();
    }
  }
}
