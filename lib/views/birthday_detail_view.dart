import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/birthday.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/birthday_controller.dart';
import '../services/gemini_service.dart';

class BirthdayDetailView extends StatefulWidget {
  final Birthday birthday;

  const BirthdayDetailView({super.key, required this.birthday});

  @override
  State<BirthdayDetailView> createState() => _BirthdayDetailViewState();
}

class _BirthdayDetailViewState extends State<BirthdayDetailView> {
  List<String> _giftSuggestions = [];
  bool _isLoading = false;
  String? _error;

  List<String> _wishSuggestions = [];
  String _wishLanguage = 'Tiếng Việt';
  bool _isWishLoading = false;
  String? _wishError;

  final List<String> _languages = ['Tiếng Việt', 'Tiếng Anh', 'Tiếng Trung'];

  Future<void> _fetchGiftSuggestions() async {
    final gender = widget.birthday.gender;
    final relationship = widget.birthday.relationship;

    if (gender == null || gender.isEmpty) {
      setState(() {
        _error = 'Vui lòng chọn giới tính để hiển thị tính năng gợi ý quà';
        _giftSuggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _giftSuggestions = [];
    });

    try {
      final prompt =
          relationship != null && relationship.isNotEmpty
              ? 'Gợi ý 5 món quà sinh nhật phù hợp cho người ${gender.toLowerCase()} với mối quan hệ là $relationship.'
              : 'Gợi ý 5 món quà sinh nhật phù hợp cho người ${gender.toLowerCase()}.';
      final suggestions = await GeminiService.getGiftSuggestions(prompt);
      setState(() {
        _giftSuggestions = suggestions;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'AI Assistant hiện chưa khả dụng.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchWishSuggestions() async {
    final gender = widget.birthday.gender;
    final relationship = widget.birthday.relationship;

    if (gender == null ||
        gender.isEmpty ||
        relationship == null ||
        relationship.isEmpty) {
      setState(() {
        _wishError =
            'Vui lòng chọn đầy đủ giới tính và mối quan hệ để hiển thị tính năng gợi ý câu chúc';
        _wishSuggestions = [];
      });
      return;
    }

    setState(() {
      _isWishLoading = true;
      _wishError = null;
      _wishSuggestions = [];
    });

    try {
      String languagePrompt;
      switch (_wishLanguage) {
        case 'Tiếng Anh':
          languagePrompt = 'in English';
          break;
        case 'Tiếng Trung':
          languagePrompt = 'in Chinese';
          break;
        default:
          languagePrompt = 'bằng tiếng Việt';
      }

      final prompt =
          'Hãy gợi ý 5 câu chúc sinh nhật trending $languagePrompt dành cho người ${gender.toLowerCase()} là $relationship.';

      final suggestions = await GeminiService.getWishSuggestions(prompt);
      setState(() {
        _wishSuggestions = suggestions;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _wishError = 'AI Assistant hiện chưa khả dụng.';
      });
    } finally {
      setState(() {
        _isWishLoading = false;
      });
    }
  }

  int _calculateAge(DateTime solarBirthday) {
    final now = DateTime.now();
    int age = now.year - solarBirthday.year;
    if (now.month < solarBirthday.month ||
        (now.month == solarBirthday.month && now.day < solarBirthday.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final birthday = widget.birthday;
    final image =
        birthday.avatarBase64 != null
            ? ClipOval(
              child: Image.memory(
                base64Decode(birthday.avatarBase64!),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            )
            : const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueGrey,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            );

    final age = _calculateAge(birthday.solarBirthday);
    final dateFormat = DateFormat('dd/MM/yyyy', 'vi');

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          birthday.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  text:
                      'Sinh nhật của ${birthday.name} vào ngày ${dateFormat.format(birthday.solarBirthday)}',
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(padding: const EdgeInsets.all(16), child: image),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(context, birthday, age, dateFormat),
            const SizedBox(height: 16),

            /// Gợi ý quà tặng
            ElevatedButton.icon(
              icon: const Icon(Icons.card_giftcard),
              label: const Text('Gợi ý quà tặng'),
              onPressed: _fetchGiftSuggestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_giftSuggestions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Gợi ý quà:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ..._giftSuggestions.map(
                    (gift) => ListTile(
                      leading: const Icon(Icons.recommend, color: Colors.teal),
                      title: Text(gift),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            /// Gợi ý câu chúc
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _wishLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Ngôn ngữ chúc',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _languages
                            .map(
                              (lang) => DropdownMenuItem(
                                value: lang,
                                child: Text(lang),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _wishLanguage = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.message),
                  label: const Text('Gợi ý câu chúc'),
                  onPressed: _fetchWishSuggestions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isWishLoading)
              const CircularProgressIndicator()
            else if (_wishError != null)
              Text(_wishError!, style: const TextStyle(color: Colors.red))
            else if (_wishSuggestions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Câu chúc gợi ý:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ..._wishSuggestions.map(
                    (wish) => ListTile(
                      leading: const Icon(
                        Icons.celebration,
                        color: Colors.deepOrange,
                      ),
                      title: Text(wish),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.notifications_active),
              label: const Text('Thông báo thử'),
              onPressed: () async {
                await Provider.of<BirthdayController>(
                  context,
                  listen: false,
                ).testNotification(birthday);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Đã gửi thông báo thử'),
                    backgroundColor: Colors.green.shade600,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    Birthday birthday,
    int age,
    DateFormat dateFormat,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildInfoRow('Tên', birthday.name, context),
            buildInfoRow('Tuổi', '$age', context),
            if (birthday.gender != null)
              buildInfoRow('Giới tính', birthday.gender!, context),
            if (birthday.nickname != null)
              buildInfoRow('Biệt danh', birthday.nickname!, context),
            if (birthday.relationship != null)
              buildInfoRow('Mối quan hệ', birthday.relationship!, context),
            buildInfoRow(
              'Ngày sinh dương',
              dateFormat.format(birthday.solarBirthday),
              context,
            ),
            buildInfoRow(
              'Ngày sinh âm',
              '${birthday.lunarBirthday.day.toString().padLeft(2, '0')}/${birthday.lunarBirthday.month.toString().padLeft(2, '0')}',
              context,
            ),
            buildInfoRow(
              'Loại lịch',
              birthday.calendarType == CalendarType.solar
                  ? 'Dương lịch'
                  : 'Âm lịch',
              context,
            ),
            buildInfoRow(
              'Lặp lại hằng năm',
              birthday.repeatAnnually ? 'Có' : 'Không',
              context,
            ),
            buildInfoRow(
              'Nhắc trước',
              '${birthday.remindBeforeDays} ngày',
              context,
            ),
            buildInfoRow(
              'Thời gian nhắc',
              birthday.remindTime.format(context),
              context,
            ),
            buildInfoRow(
              'Thông báo lặp',
              birthday.isRecurringNotificationEnabled ? 'Bật' : 'Tắt',
              context,
            ),
            if (birthday.note != null && birthday.note!.isNotEmpty)
              buildInfoRow('Ghi chú', birthday.note!, context),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
