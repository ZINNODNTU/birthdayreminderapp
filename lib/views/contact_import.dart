import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../controllers/birthday_controller.dart';
import '../models/birthday.dart';
import '../l10n/l10n_extensions.dart';

class ContactImport extends StatefulWidget {
  const ContactImport({super.key});

  @override
  State<ContactImport> createState() => _ContactImportState();
}

class _ContactImportState extends State<ContactImport> {
  final Set<String> _selectedIds = {};
  List<Contact> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final permission = await FlutterContacts.permissions.request(
      PermissionType.read,
    );
    final allowed =
        permission == PermissionStatus.granted ||
        permission == PermissionStatus.limited;
    if (!mounted) return;
    if (!allowed) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.contactPermissionDenied)),
      );
      return;
    }

    final existingNames =
        context
            .read<BirthdayController>()
            .birthdays
            .map((birthday) => birthday.name.trim().toLowerCase())
            .toSet();
    final contacts = await FlutterContacts.getAll(
      properties: const {ContactProperty.name, ContactProperty.photoThumbnail},
    );
    if (!mounted) return;
    setState(() {
      _contacts =
          contacts
              .where((contact) => (contact.displayName ?? '').trim().isNotEmpty)
              .where(
                (contact) =>
                    !existingNames.contains(
                      (contact.displayName ?? '').trim().toLowerCase(),
                    ),
              )
              .where((contact) => contact.id != null)
              .toList();
      _loading = false;
    });
  }

  Future<void> _saveSelectedContacts() async {
    final controller = context.read<BirthdayController>();
    final now = DateTime.now();
    for (final contact in _contacts.where(
      (contact) => _selectedIds.contains(contact.id!),
    )) {
      await controller.addBirthday(
        Birthday(
          id: const Uuid().v4(),
          name: contact.displayName ?? context.l10n.unnamed,
          avatarBase64:
              contact.photo?.thumbnail == null
                  ? null
                  : base64Encode(contact.photo!.thumbnail!),
          solarBirthday: now,
          lunarBirthday: LunarDateTime.fromDateTime(now),
          calendarType: CalendarType.solar,
          remindBeforeDays: 0,
          remindTime: const TimeOfDay(hour: 9, minute: 0),
          isRecurringNotificationEnabled: true,
          repeatAnnually: true,
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  void _toggleAll() {
    setState(() {
      if (_selectedIds.length == _contacts.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_contacts.map((contact) => contact.id!));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIds.isEmpty
              ? context.l10n.selectFromContacts
              : context.l10n.selectedCount(_selectedIds.length),
        ),
        actions: [
          if (_contacts.isNotEmpty)
            IconButton(
              icon: Icon(
                _selectedIds.length == _contacts.length
                    ? Icons.clear_all
                    : Icons.select_all,
              ),
              tooltip: context.l10n.toggleSelectAll,
              onPressed: _toggleAll,
            ),
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: context.l10n.save,
              onPressed: _saveSelectedContacts,
            ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _contacts.isEmpty
              ? Center(child: Text(context.l10n.noContactsToAdd))
              : ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  return CheckboxListTile(
                    value: _selectedIds.contains(contact.id!),
                    onChanged: (selected) {
                      setState(() {
                        if (selected ?? false) {
                          _selectedIds.add(contact.id!);
                        } else {
                          _selectedIds.remove(contact.id!);
                        }
                      });
                    },
                    title: Text(contact.displayName ?? context.l10n.unnamed),
                    secondary:
                        contact.photo?.thumbnail == null
                            ? const CircleAvatar(child: Icon(Icons.person))
                            : CircleAvatar(
                              backgroundImage: MemoryImage(
                                contact.photo!.thumbnail!,
                              ),
                            ),
                  );
                },
              ),
    );
  }
}
