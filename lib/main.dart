import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

void main() async {
  final prefs = await AppBootstrap.run();
  runApp(BirthdayReminderApp(prefs: prefs));
}
