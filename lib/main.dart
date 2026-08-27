import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'controllers/birthday_controller.dart';
import 'core/auth/firebase_auth_repository.dart';
import 'core/auth/auth_gate.dart';
import 'services/local_db_service.dart';
import 'services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  LocalDBService();
  NotificationService();
  await initializeDateFormatting('vi');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BirthdayController()..loadBirthdays(),
        ),
        Provider<FirebaseAuthRepository>(
          create: (_) => FirebaseAuthRepository(),
        ),
      ],
      child: MaterialApp(
        title: 'Birthday Reminder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
