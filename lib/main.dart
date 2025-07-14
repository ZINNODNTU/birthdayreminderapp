import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // 🔥 Import Firebase
import 'controllers/birthday_controller.dart';
import 'views/homepage.dart';
import 'services/local_db_service.dart';
import 'services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart'; // 👈 THÊM


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Khởi tạo Firebase
  await Firebase.initializeApp();

  // Khởi tạo local DB và notification
  await LocalDBService();
  await NotificationService();
  await initializeDateFormatting('vi'); // 👈 THÊM để hỗ trợ định dạng tiếng Việt

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BirthdayController()..loadBirthdays(),
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
        home: const Homepage(),
      ),
    );
  }
}
