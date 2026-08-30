import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../controllers/birthday_controller.dart';
import '../features/birthdays/services/birthday_photo_service.dart';
import '../models/birthday.dart';
import '../services/avatar_cache.dart';

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
    setState(() => _processingImage = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cắt ảnh sinh nhật',
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Cắt ảnh sinh nhật',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
      if (cropped == null) return;
      final raw = Uint8List.fromList(await cropped.readAsBytes());
      final result = context.read<BirthdayPhotoService>().encodeBytes(raw);
      if (!mounted) return;
      if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xử lý ảnh đã chọn.')),
        );
        return;
      }
      setState(() => _avatarBase64 = result.photo!.base64);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể chọn hoặc cắt ảnh.')),
        );
      }
    } finally {
      if (mounted) setState(() => _processingImage = false);
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (!isValidAge(_solarBirthday)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tuổi phải nằm trong khoảng từ 0 đến 120.'),
          ),
        );
        return;
      }

      _formKey.currentState!.save();
      final birthday = Birthday(
        id: widget.birthday?.id ?? DateTime.now().toString(),
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
          widget.birthday == null ? 'Thêm sinh nhật' : 'Sửa sinh nhật',
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
                  backgroundImage:
                      _avatarBase64 != null
                          ? (AvatarCache.decodeAndCache(_avatarBase64!) != null
                              ? MemoryImage(
                                AvatarCache.decodeAndCache(_avatarBase64!)!,
                              )
                              : null)
                          : null,
                  child:
                      _avatarBase64 == null
                          ? const Icon(Icons.add_a_photo)
                          : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Tên *'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Vui lòng nhập tên'
                            : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _nickname,
                decoration: const InputDecoration(labelText: 'Biệt danh'),
                onSaved: (value) => _nickname = value,
              ),
              DropdownButtonFormField<String>(
                initialValue: _gender?.isNotEmpty == true ? _gender : '',
                decoration: const InputDecoration(labelText: 'Giới tính'),
                isExpanded: true,
                onChanged: (value) {
                  setState(() => _gender = value != '' ? value : null);
                },
                items: const [
                  DropdownMenuItem(value: '', child: Text('- Chọn -')),
                  DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                  DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                  DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                ],
                onSaved: (value) => _gender = value != '' ? value : null,
              ),

              TextFormField(
                initialValue: _relationship,
                decoration: const InputDecoration(labelText: 'Mối quan hệ'),
                onSaved: (value) => _relationship = value,
              ),
              TextFormField(
                initialValue: _note,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
                onSaved: (value) => _note = value,
              ),
              const SizedBox(height: 16),
              RadioGroup<CalendarType>(
                groupValue: _calendarType,
                onChanged: (value) {
                  if (value != null) setState(() => _calendarType = value);
                },
                child: Row(
                  children: const [
                    Text('Loại lịch:'),
                    SizedBox(width: 10),
                    Expanded(
                      child: RadioListTile<CalendarType>(
                        title: Text('Dương lịch'),
                        value: CalendarType.solar,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<CalendarType>(
                        title: Text('Âm lịch'),
                        value: CalendarType.lunar,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text(
                  'Ngày sinh dương: ${_solarBirthday.day}/${_solarBirthday.month}/${_solarBirthday.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _solarBirthday,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: const Locale('vi', 'VN'),
                  );
                  if (!context.mounted) return;
                  if (picked != null) {
                    if (!isValidAge(picked)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tuổi không hợp lệ. Tuổi phải từ 0 đến 120.',
                          ),
                        ),
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
                  'Ngày sinh âm: ${_lunarBirthday.day}/${_lunarBirthday.month}',
                ),
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Nhắc trước (ngày)',
                ),
                initialValue: _remindBeforeDays,
                onChanged:
                    (value) => setState(() => _remindBeforeDays = value ?? 0),
                items: List.generate(31, (index) {
                  return DropdownMenuItem(value: index, child: Text('$index'));
                }),
              ),
              ListTile(
                title: Text('Giờ nhắc: ${_remindTime.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _remindTime,
                    builder: (ctx, child) {
                      return MediaQuery(
                        data: MediaQuery.of(
                          ctx,
                        ).copyWith(alwaysUse24HourFormat: true),
                        child: Localizations.override(
                          context: ctx,
                          locale: const Locale('vi', 'VN'),
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
                title: const Text('Lặp lại hàng năm'),
                value: _repeatAnnually,
                onChanged:
                    (val) => setState(() => _repeatAnnually = val ?? true),
              ),
              CheckboxListTile(
                title: const Text('Bật thông báo'),
                value: _isRecurringNotificationEnabled,
                onChanged:
                    (val) => setState(
                      () => _isRecurringNotificationEnabled = val ?? true,
                    ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submitForm, child: const Text('Lưu')),
            ],
          ),
        ),
      ),
    );
  }
}
