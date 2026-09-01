import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/views/auth_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/services/onboarding_service.dart';
import '../../views/homepage.dart';
import '../session/app_session_mode.dart';
import '../session/session_controller.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AppSessionMode? _evaluatedMode;
  bool _checking = false;

  void _scheduleOnboarding(AppSessionMode mode) {
    if (mode == AppSessionMode.unauthenticated ||
        _evaluatedMode == mode ||
        _checking) {
      return;
    }
    _evaluatedMode = mode;
    _checking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted || !await context.read<OnboardingService>().shouldShow()) {
          return;
        }
        if (!mounted) return;
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      } catch (_) {
        // Non-critical guidance must never block application startup.
      } finally {
        _checking = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    if (!session.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mode = session.mode;
    _scheduleOnboarding(mode);
    return switch (mode) {
      AppSessionMode.authenticated || AppSessionMode.local => const Homepage(),
      AppSessionMode.unauthenticated => const AuthScreen(),
    };
  }
}
