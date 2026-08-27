import 'package:flutter/material.dart';
import '../models/birthday.dart';
import 'dart:convert';
import 'birthday_add_edit_view.dart';

class BirthdayItem extends StatelessWidget {
  final Birthday birthday;
  final VoidCallback? onTap;

  const BirthdayItem({super.key, required this.birthday, this.onTap});

  int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  int daysUntilNextBirthday(DateTime birthDate) {
    final now = DateTime.now();
    DateTime nextBirthday = DateTime(now.year, birthDate.month, birthDate.day);
    if (nextBirthday.isBefore(now) || nextBirthday.isAtSameMomentAs(now)) {
      nextBirthday = DateTime(now.year + 1, birthDate.month, birthDate.day);
    }
    return nextBirthday.difference(now).inDays;
  }

  void _navigateToEditPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BirthdayAddEditView(birthday: birthday),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image =
        birthday.avatarBase64 != null
            ? Image.memory(
              base64Decode(birthday.avatarBase64!),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            )
            : const Icon(Icons.person, size: 48);

    final int age = calculateAge(birthday.solarBirthday);
    final int days = daysUntilNextBirthday(birthday.solarBirthday);

    return ListTile(
      leading: CircleAvatar(child: image),
      title: Text(birthday.name),
      subtitle: Text('Tuổi: $age • Còn $days ngày'),
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 20),
        onPressed: () => _navigateToEditPage(context),
      ),
      onTap: onTap,
    );
  }
}
