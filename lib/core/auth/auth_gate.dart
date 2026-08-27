import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_repository.dart';
import '../../features/auth/views/auth_screen.dart';
import '../../views/homepage.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return const Homepage();
        }
        return const AuthScreen();
      },
    );
  }
}
