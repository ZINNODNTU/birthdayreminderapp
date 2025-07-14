import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_contacts_service/flutter_contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../controllers/birthday_controller.dart';
import '../models/birthday.dart';

class ContactImport extends StatefulWidget {
  const ContactImport({super.key});

  @override
  State<ContactImport> createState() => _ContactImportState();
}

class _ContactImportState extends State<ContactImport> {
  List<ContactInfo> _allContacts = [];
  List<ContactInfo> _filteredContacts = [];
  final Set<ContactInfo> _selectedContacts = {};

  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    if (await Permission.contacts.request().isGranted) {
      final controller = Provider.of<BirthdayController>(context, listen: false);
      final existingNames = controller.birthdays.map((b) => b.name).toSet();

      final contacts = await FlutterContactsService.getContacts(photoHighResolution: true);
      final castedContacts = contacts.cast<ContactInfo>();

      // Lọc bỏ các danh bạ đã thêm
      final filtered = castedContacts.where((contact) {
        final name = contact.displayName?.trim();
        return name != null && !existingNames.contains(name);
      }).toList();

      setState(() {
        _allContacts = castedContacts;
        _filteredContacts = filtered;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có quyền truy cập danh bạ')),
      );
    }
  }

  Future<void> _saveSelectedContacts() async {
    final controller = Provider.of<BirthdayController>(context, listen: false);
    final now = DateTime.now();

    for (final contact in _selectedContacts) {
      final birthday = Birthday(
        id: const Uuid().v4(),
        name: contact.displayName ?? 'Không tên',
        avatarBase64: contact.avatar != null ? base64Encode(contact.avatar!) : null,
        gender: null,
        nickname: null,
        relationship: null,
        solarBirthday: now,
        lunarBirthday: LunarDateTime.fromDateTime(now),
        calendarType: CalendarType.solar,
        remindBeforeDays: 0,
        remindTime: const TimeOfDay(hour: 9, minute: 0),
        isRecurringNotificationEnabled: true,
        repeatAnnually: true,
        note: null,
      );

      await controller.addBirthday(birthday);
    }

    Navigator.pop(context);
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedContacts.clear();
      } else {
        _selectedContacts.addAll(_filteredContacts);
      }
      _selectAll = !_selectAll;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedContacts.isEmpty
              ? 'Chọn từ danh bạ'
              : 'Đã chọn: ${_selectedContacts.length}',
        ),
        actions: [
          if (_filteredContacts.isNotEmpty)
            IconButton(
              icon: Icon(_selectAll ? Icons.clear_all : Icons.select_all),
              tooltip: _selectAll ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
              onPressed: _toggleSelectAll,
            ),
          if (_selectedContacts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Lưu',
              onPressed: _saveSelectedContacts,
            ),
        ],
      ),
      body: _filteredContacts.isEmpty
          ? const Center(child: Text('Không còn danh bạ nào để thêm'))
          : ListView.builder(
        itemCount: _filteredContacts.length,
        itemBuilder: (context, index) {
          final contact = _filteredContacts[index];
          final isSelected = _selectedContacts.contains(contact);

          return CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedContacts.add(contact);
                } else {
                  _selectedContacts.remove(contact);
                }
              });
            },
            title: Text(contact.displayName ?? 'Không tên'),
            secondary: contact.avatar != null
                ? CircleAvatar(
              backgroundImage: MemoryImage(contact.avatar!),
            )
                : const CircleAvatar(child: Icon(Icons.person)),
          );
        },
      ),
    );
  }
}
