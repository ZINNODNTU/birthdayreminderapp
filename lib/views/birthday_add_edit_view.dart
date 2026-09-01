import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

import '../controllers/birthday_controller.dart';
import '../features/birthdays/services/birthday_photo_service.dart';
import '../models/birthday.dart';
import '../services/avatar_cache.dart';
import '../services/photo_permission_service.dart';
import '../l10n/l10n_extensions.dart';

class BirthdayAddEditView extends StatefulWidget {
  final Birthday? birthday;

  const BirthdayAddEditView({super.key, this.birthday});

  @override
  State<BirthdayAddEditView> createState() => _BirthdayAddEditViewState();
}

class _BirthdayAddEditViewState extends State<BirthdayAddEditView> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  String? _avatarBase64;
  String? _gender;
  String? _nickname;
  String? _relationship;
  String? _note;

  late DateTime _solarBirthday;
  late LunarDateTime _lunarBirthday;
  late CalendarType _calendarType;
  late int _remindBeforeDays;
  late TimeOfDay _remindTime;
  bool _isRecurringNotificationEnabled = true;
  bool _repeatAnnually = true;
  bool _processingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.birthday != null) {
      final b = widget.birthday!;
      _name = b.name;
      _avatarBase64 = b.avatarBase64;
      _gender = b.gender;
      _nickname = b.nickname;
      _relationship = b.relationship;
      _note = b.note;
      _solarBirthday = b.solarBirthday;
      _lunarBirthday = b.lunarBirthday;
      _calendarType = b.calendarType;
      _remindBeforeDays = b.remindBeforeDays;
      _remindTime = b.remindTime;
      _isRecurringNotificationEnabled = b.isRecurringNotificationEnabled;
      _repeatAnnually = b.repeatAnnually;
    } else {
      _name = '';
      _avatarBase64 = null;
      _gender = null;
      _nickname = null;
      _relationship = null;
      _note = null;
      _solarBirthday = DateTime.now();
      _lunarBirthday = LunarDateTime.fromDateTime(DateTime.now());
      _calendarType = CalendarType.solar;
      _remindBeforeDays = 0;
      _remindTime = TimeOfDay.now();
    }
  }

  bool isValidAge(DateTime birthday, {int minAge = 0, int maxAge = 120}) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age >= minAge && age <= maxAge;
  }

  Future<void> _pickImage() async {
    if (_processingImage) return;
    final photoService = context.read<BirthdayPhotoService>();
    final permService = PhotoPermissionService();
    Directory? tempDir;
    setState(() => _processingImage = true);

    try {
      final status = await permService.checkAndRequest();
      switch (status) {
        case PhotoPermissionStatus.granted:
          break;
        case PhotoPermissionStatus.denied:
          if (mounted) await _showPermissionDeniedDialog();
          return;
        case PhotoPermissionStatus.permanentlyDenied:
          if (mounted) await _showPermanentlyDeniedDialog();
          return;
        case PhotoPermissionStatus.restricted:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.permissionRestrictedMessage)),
            );
          }
          return;
      }

      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (picked == null) return;

      final sourceFile = File(picked.path);
      if (!await sourceFile.exists()) {
        throw const FileSystemException('Selected image no longer exists');
      }

      final bytes = await sourceFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw const FormatException('Invalid image');

      final longestSide = decoded.width >= decoded.height
          ? decoded.width
          : decoded.height;
      final resized = longestSide > 1024
          ? (decoded.width >= decoded.height
                ? img.copyResize(decoded, width: 1024)
                : img.copyResize(decoded, height: 1024))
          : decoded;
      final compressedBytes = img.encodeJpg(resized, quality: 80);
      tempDir = await Directory.systemTemp.createTemp('avatar_');
      final tempFile = File('${tempDir.path}${Platform.pathSeparator}temp.jpg');
      await tempFile.writeAsBytes(compressedBytes, flush: true);
      if (!mounted) return;

      CroppedFile? cropped;
      try {
        cropped = await ImageCropper().cropImage(
          sourcePath: tempFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 95,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: context.l10n.cropTitle,
              lockAspectRatio: true,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: context.l10n.cropTitle,
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );
      } catch (_) {
        if (mounted) _showImageError();
        return;
      }
      if (cropped == null) return;

      final croppedFile = File(cropped.path);
      if (!await croppedFile.exists()) {
        throw const FileSystemException('Cropped image no longer exists');
      }
      final raw = Uint8List.fromList(await croppedFile.readAsBytes());
      final result = photoService.encodeBytes(raw);
      if (!mounted) return;
      if (!result.ok) {
        _showImageError();
        return;
      }
      setState(() => _avatarBase64 = result.photo!.base64);
    } catch (_) {
      if (mounted) _showImageError();
    } finally {
      if (tempDir != null) {
        try {
          if (await tempDir.exists()) await tempDir.delete(recursive: true);
        } catch (_) {
          // Temporary cleanup failure must not break the image flow.
        }
      }
      if (mounted) setState(() => _processingImage = false);
    }
  }

  void _showImageError() {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.imageProcessError)));
  }

  Future<void> _showPermissionDeniedDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(context.l10n.photoPermissionTitle),
        content: Text(context.l10n.permissionDeniedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final permService = PhotoPermissionService();
              final status = await permService.checkAndRequest();
              if (status == PhotoPermissionStatus.granted) {
                // retry picking
                _pickImage();
              }
            },
            child: Text(context.l10n.allow),
          ),
        ],
      ),
    );
  }

  Future<void> _showPermanentlyDeniedDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(context.l10n.photoPermissionTitle),
        content: Text(context.l10n.photoPermissionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final permService = PhotoPermissionService();
              await permService.openSettings();
            },
            child: Text(context.l10n.openSettings),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (!isValidAge(_solarBirthday)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.ageInvalid)));
        return;
      }

      _formKey.currentState!.save();
      final birthday = Birthday(
        id: widget.birthday?.id ?? const Uuid().v4(),
        name: _name,
        avatarBase64: _avatarBase64,
        gender: _gender,
        nickname: _nickname,
        relationship: _relationship,
        solarBirthday: _solarBirthday,
        lunarBirthday: _lunarBirthday,
        calendarType: _calendarType,
        remindBeforeDays: _remindBeforeDays,
        remindTime: _remindTime,
        isRecurringNotificationEnabled: _isRecurringNotificationEnabled,
        repeatAnnually: _repeatAnnually,
        note: _note,
      );

      final controller = Provider.of<BirthdayController>(
        context,
        listen: false,
      );
      widget.birthday == null
          ? controller.addBirthday(birthday)
          : controller.updateBirthday(birthday);

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.birthday == null
              ? context.l10n.addBirthday
              : context.l10n.editBirthday,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: _avatarBase64 != null
                      ? (AvatarCache.decodeAndCache(_avatarBase64!) != null
                            ? MemoryImage(
                                AvatarCache.decodeAndCache(_avatarBase64!)!,
                              )
                            : null)
                      : null,
                  child: _avatarBase64 == null
                      ? const Icon(Icons.add_a_photo)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(
                  labelText: '${context.l10n.name} *',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? context.l10n.nameRequired
                    : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _nickname,
                decoration: InputDecoration(labelText: context.l10n.nickname),
                onSaved: (value) => _nickname = value,
              ),
              DropdownButtonFormField<String>(
                initialValue: _gender?.isNotEmpty == true ? _gender : '',
                decoration: InputDecoration(labelText: context.l10n.gender),
                isExpanded: true,
                onChanged: (value) {
                  setState(() => _gender = value != '' ? value : null);
                },
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(context.l10n.selectOption),
                  ),
                  DropdownMenuItem(
                    value: 'Nam',
                    child: Text(context.l10n.male),
                  ),
                  DropdownMenuItem(
                    value: 'Nữ',
                    child: Text(context.l10n.female),
                  ),
                  DropdownMenuItem(
                    value: 'Khác',
                    child: Text(context.l10n.other),
                  ),
                ],
                onSaved: (value) => _gender = value != '' ? value : null,
              ),

              TextFormField(
                initialValue: _relationship,
                decoration: InputDecoration(
                  labelText: context.l10n.relationship,
                ),
                onSaved: (value) => _relationship = value,
              ),
              TextFormField(
                initialValue: _note,
                decoration: InputDecoration(labelText: context.l10n.note),
                onSaved: (value) => _note = value,
              ),
              const SizedBox(height: 16),
              RadioGroup<CalendarType>(
                groupValue: _calendarType,
                onChanged: (value) {
                  if (value != null) setState(() => _calendarType = value);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${context.l10n.calendarType}:'),
                    RadioListTile<CalendarType>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.l10n.solar),
                      value: CalendarType.solar,
                    ),
                    RadioListTile<CalendarType>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.l10n.lunar),
                      value: CalendarType.lunar,
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text(
                  context.l10n.solarDate(
                    '${_solarBirthday.day}/${_solarBirthday.month}/${_solarBirthday.year}',
                  ),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _solarBirthday,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: Localizations.localeOf(context),
                  );
                  if (!context.mounted) return;
                  if (picked != null) {
                    if (!isValidAge(picked)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.ageInvalid)),
                      );
                      return;
                    }
                    setState(() {
                      _solarBirthday = picked;
                      _lunarBirthday = LunarDateTime.fromDateTime(picked);
                    });
                  }
                },
              ),
              ListTile(
                title: Text(
                  context.l10n.lunarDate(
                    '${_lunarBirthday.day}/${_lunarBirthday.month}',
                  ),
                ),
              ),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: context.l10n.remindBefore,
                ),
                initialValue: _remindBeforeDays,
                onChanged: (value) =>
                    setState(() => _remindBeforeDays = value ?? 0),
                items: List.generate(31, (index) {
                  return DropdownMenuItem(value: index, child: Text('$index'));
                }),
              ),
              ListTile(
                title: Text(
                  '${context.l10n.remindTime}: ${_remindTime.format(context)}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _remindTime,
                    builder: (ctx, child) {
                      return MediaQuery(
                        data: MediaQuery.of(ctx)
                            .copyWith(alwaysUse24HourFormat: true),
                        child: Localizations.override(
                          context: ctx,
                          locale: Localizations.localeOf(context),
                          child: child!,
                        ),
                      );
                    },
                  );
                  if (!context.mounted) return;
                  if (picked != null) {
                    setState(() => _remindTime = picked);
                  }
                },
              ),
              CheckboxListTile(
                title: Text(context.l10n.repeatAnnually),
                value: _repeatAnnually,
                onChanged: (val) =>
                    setState(() => _repeatAnnually = val ?? true),
              ),
              CheckboxListTile(
                title: Text(context.l10n.enableNotification),
                value: _isRecurringNotificationEnabled,
                onChanged: (val) => setState(
                  () => _isRecurringNotificationEnabled = val ?? true,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(context.l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
