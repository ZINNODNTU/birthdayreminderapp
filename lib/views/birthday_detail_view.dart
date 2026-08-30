import 'dart:async';

import '../services/avatar_cache.dart';
import 'birthday_detail/models/reminder_status.dart';
import 'birthday_detail/widgets/reminder_status_card.dart';
import 'birthday_detail/widgets/birthday_info_card.dart';
import 'birthday_detail/widgets/birthday_ai_section.dart';
import 'birthday_detail/widgets/birthday_action_buttons.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/birthday_controller.dart';
import '../core/logging/app_logger.dart';
import '../features/ai/domain/ai_provider.dart';
import '../features/ai/domain/ai_result_source.dart';
import '../features/ai/domain/birthday_ai_person_context.dart';
import '../features/ai/services/ai_response_parsers.dart';
import '../features/ai/services/birthday_ai_service.dart';
import '../features/reminders/data/reminder_schedule_store.dart';
import '../features/reminders/domain/reminder_failure.dart';
import '../features/reminders/services/reminder_scheduler.dart';
import '../models/birthday.dart';
import '../services/notification_service.dart';

class BirthdayDetailView extends StatefulWidget {
  final Birthday birthday;

  const BirthdayDetailView({super.key, required this.birthday});

  @override
  State<BirthdayDetailView> createState() => _BirthdayDetailViewState();
}

class _BirthdayDetailViewState extends State<BirthdayDetailView>
    with TickerProviderStateMixin {
  GiftSuggestionResult? _giftSuggestions;
  bool _isGiftLoading = false;
  String? _giftError;
  AiResultSource? _giftSource;

  BirthdayWishResult? _wishSuggestions;
  bool _isWishLoading = false;
  String? _wishError;
  AiResultSource? _wishSource;
  String _wishLanguage = 'vi';

  ReminderStatus _reminderStatus = ReminderStatus.unknown;
  String? _reminderMessage;
  DateTime? _nextFireAt;
  bool _rescheduling = false;

  late final AnimationController _entry;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;
  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _entryFade = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOut));
    _entry.forward();
    _refreshReminderStatus();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshReminderStatus();
  }

  Future<void> _refreshReminderStatus() async {
    final notif = context.read<NotificationService>();
    final store = context.read<ReminderScheduleStore>();
    final entries = store.loadAll();
    final mine =
        entries.values
            .where((e) => e.birthdayId == widget.birthday.id)
            .toList();
    final futureEntries = mine
        .where((e) => e.scheduledAt != null)
        .where((e) => e.scheduledAt!.isAfter(DateTime.now()))
        .toList(growable: false);
    futureEntries.sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    if (!widget.birthday.isRecurringNotificationEnabled) {
      if (!mounted) return;
      setState(() {
        _reminderStatus = ReminderStatus.disabled;
        _reminderMessage = 'Thông báo đã tắt cho người này.';
        _nextFireAt = null;
      });
      return;
    }
    if (futureEntries.isEmpty) {
      if (!mounted) return;
      setState(() {
        _reminderStatus = ReminderStatus.notScheduled;
        _reminderMessage = 'Chưa có lịch nhắc nào.';
        _nextFireAt = null;
      });
      return;
    }
    final next = futureEntries.first;
    final pending = await notif.isNotificationPending(next.notificationId);
    if (!mounted) return;
    setState(() {
      _nextFireAt = next.scheduledAt;
      if (!pending) {
        _reminderStatus = ReminderStatus.phantom;
        _reminderMessage =
            'Đã đặt lịch nhắc nhưng hệ thống chưa xác nhận '
            '(id ${next.notificationId}).';
        return;
      }
      _reminderStatus = ReminderStatus.scheduled;
      _reminderMessage =
          'Đã lên lịch lúc ${DateFormat('dd/MM/yyyy HH:mm').format(next.scheduledAt!)}.';
    });
  }

  Future<void> _rescheduleReminder() async {
    setState(() => _rescheduling = true);
    try {
      final scheduler = context.read<ReminderScheduler>();
      final result = await scheduler.scheduleNextAnnualReminder(
        widget.birthday,
      );
      await _refreshReminderStatus();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (result.isOk && result.scheduledCount > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Đã đặt lại lịch${result.scheduledAt != null ? ' lúc ${DateFormat('dd/MM/yyyy HH:mm').format(result.scheduledAt!)}' : ''}.',
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(_describeFailure(result.kind)),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e, st) {
      AppLogger.error('BirthdayDetail', e, st);
    } finally {
      if (mounted) setState(() => _rescheduling = false);
    }
  }

  String _describeFailure(NotificationFailureKind k) =>
      describeNotificationFailure(k);

  Future<void> _fetchGift({bool preservePrevious = true}) async {
    if (!preservePrevious) {
      setState(() {
        _isGiftLoading = true;
        _giftError = null;
        _giftSuggestions = null;
        _giftSource = null;
      });
    } else {
      setState(() {
        _isGiftLoading = true;
        _giftError = null;
      });
    }
    try {
      final service = context.read<BirthdayAiService>();
      final outcome = await service.suggestGift(
        widget.birthday,
        bypassCache: !preservePrevious,
      );
      if (!mounted) return;
      if (outcome.suggestions != null &&
          outcome.suggestions!.items.isNotEmpty) {
        setState(() {
          _giftSuggestions = outcome.suggestions;
          _giftSource = outcome.source;
        });
      } else {
        setState(() => _giftError = _localizeError(outcome.connection));
      }
    } catch (e, st) {
      AppLogger.error('BirthdayAiGift', e, st);
      if (!mounted) return;
      setState(() => _giftError = 'AI không khả dụng.');
    } finally {
      if (mounted) setState(() => _isGiftLoading = false);
    }
  }

  Future<void> _fetchWish({bool preservePrevious = true}) async {
    if (!preservePrevious) {
      setState(() {
        _isWishLoading = true;
        _wishError = null;
        _wishSuggestions = null;
        _wishSource = null;
      });
    } else {
      setState(() {
        _isWishLoading = true;
        _wishError = null;
      });
    }
    try {
      final service = context.read<BirthdayAiService>();
      final outcome = await service.suggestGreeting(
        widget.birthday,
        _wishLanguage,
        bypassCache: !preservePrevious,
      );
      if (!mounted) return;
      if (outcome.wishes != null && outcome.wishes!.wishes.isNotEmpty) {
        setState(() {
          _wishSuggestions = outcome.wishes;
          _wishSource = outcome.source;
        });
      } else {
        setState(() => _wishError = _localizeError(outcome.connection));
      }
    } catch (e, st) {
      AppLogger.error('BirthdayAiWish', e, st);
      if (!mounted) return;
      setState(() => _wishError = 'AI không khả dụng.');
    } finally {
      if (mounted) setState(() => _isWishLoading = false);
    }
  }

  String _localizeError(AiConnectionResult r) {
    switch (r.errorCode) {
      case 'missing_api_key':
        return 'Chưa cấu hình API key.';
      case 'unauthorized':
      case 'http_401':
      case 'http_403':
        return 'API key không hợp lệ hoặc không có quyền.';
      case 'model_not_found':
      case 'http_404':
        return 'Không tìm thấy model.';
      case 'http_429':
        return 'Đã hết quota hoặc vượt giới hạn yêu cầu.';
      case 'timeout':
        return 'AI phản hồi quá lâu. Hãy thử lại.';
      case 'network':
        return 'Không thể kết nối máy chủ.';
      default:
        return r.errorMessage ?? 'AI không khả dụng.';
    }
  }

  void _onGiftTap() {
    _fetchGift(preservePrevious: true).then((_) {
      if (mounted) _showGiftSheet();
    });
  }

  void _onWishTap() {
    _fetchWish(preservePrevious: true).then((_) {
      if (mounted) _showWishSheet();
    });
  }

  void _onWishLanguageChanged(String newLang) {
    setState(() => _wishLanguage = newLang);
  }

  Future<void> _showGiftSheet() async {
    final displayName =
        widget.birthday.nickname?.trim().isNotEmpty == true
            ? widget.birthday.nickname!.trim()
            : widget.birthday.name;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => _GiftSheet(
            title: 'Gợi ý riêng cho $displayName',
            targetCount: kGiftTargetCount,
            items: _giftSuggestions,
            error: _giftError,
            isLoading: _isGiftLoading,
            source: _giftSource,
            onRetry:
                _isGiftLoading
                    ? null
                    : () => _fetchGift(preservePrevious: false),
            snap: context.read<BirthdayAiService>().contextFor(widget.birthday),
          ),
    );
  }

  Future<void> _showWishSheet() async {
    final displayName =
        widget.birthday.nickname?.trim().isNotEmpty == true
            ? widget.birthday.nickname!.trim()
            : widget.birthday.name;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => _WishSheet(
            title: '10 câu chúc cho $displayName',
            targetCount: kWishTargetCount,
            wishes: _wishSuggestions,
            error: _wishError,
            isLoading: _isWishLoading,
            source: _wishSource,
            onRetry:
                _isWishLoading
                    ? null
                    : () => _fetchWish(preservePrevious: false),
            snap: context.read<BirthdayAiService>().contextFor(widget.birthday),
          ),
    );
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
    final image = () {
      if (birthday.avatarBase64 == null || birthday.avatarBase64!.isEmpty) {
        return Hero(
          tag: 'birthday-avatar-${birthday.id}',
          child: const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blueGrey,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
        );
      }
      final bytes = AvatarCache.decodeAndCache(birthday.avatarBase64!);
      if (bytes == null) {
        return Hero(
          tag: 'birthday-avatar-${birthday.id}',
          child: const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blueGrey,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
        );
      }
      return Hero(
        tag: 'birthday-avatar-${birthday.id}',
        child: ClipOval(
          child: Image.memory(
            bytes,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
      );
    }();
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
      body: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: image),
                const SizedBox(height: 24),
                BirthdayInfoCard(
                  birthday: birthday,
                  age: age,
                  dateFormat: dateFormat,
                ),
                const SizedBox(height: 16),
                ReminderStatusCard(
                  status: _reminderStatus,
                  message: _reminderMessage,
                  nextFireAt: _nextFireAt,
                  rescheduling: _rescheduling,
                  repeatAnnually: widget.birthday.repeatAnnually,
                  onReschedule: _rescheduleReminder,
                ),
                const SizedBox(height: 16),
                BirthdayAiSection(birthdayName: birthday.name),
                const SizedBox(height: 16),
                BirthdayActionButtons(
                  onGiftTap: _onGiftTap,
                  onWishTap: _onWishTap,
                  isGiftLoading: _isGiftLoading,
                  isWishLoading: _isWishLoading,
                  wishLanguage: _wishLanguage,
                  onWishLanguageChanged: _onWishLanguageChanged,
                ),
                const SizedBox(height: 16),
                _buildTestNotification(context, birthday),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestNotification(BuildContext context, Birthday birthday) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.notifications_active),
      label: const Text('Thông báo thử'),
      onPressed: () async {
        NotificationTestResult result;
        try {
          result = await Provider.of<BirthdayController>(
            context,
            listen: false,
          ).testNotification(birthday);
        } catch (e, st) {
          AppLogger.error('NotificationTest', e, st);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể hiển thị thông báo: $e'),
              backgroundColor: Colors.red.shade600,
            ),
          );
          return;
        }
        if (!context.mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        if (result.ok) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Đã gửi thông báo thử'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (!result.permissionGranted || !result.notificationsEnabled) {
          messenger.showSnackBar(
            SnackBar(
              content: const Text(
                'Thông báo đang bị tắt. Hãy bật quyền thông báo cho ứng dụng.',
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 6),
            ),
          );
        } else if (result.error != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Không thể hiển thị thông báo: ${result.error}'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Không thể gửi thông báo. '
                'init=${result.initialized} '
                'perm=${result.permissionGranted} '
                'enabled=${result.notificationsEnabled} '
                'channel=${result.channelCreated}',
              ),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.targetCount,
    required this.unitLabel,
    required this.child,
    required this.actions,
    required this.loading,
    required this.source,
    this.headerBadge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final int count;
  final int targetCount;
  final String unitLabel;
  final Widget child;
  final List<Widget> actions;
  final bool loading;
  final AiResultSource? source;

  /// Optional small "Cá nhân hóa theo hồ sơ" pill rendered under the
  /// subtitle when the feature is built from a personalised context.
  final String? headerBadge;

  static String sourceLabel(AiResultSource? s) {
    switch (s) {
      case AiResultSource.ai:
        return 'Đề xuất bởi AI';
      case AiResultSource.mixed:
        return 'AI + gợi ý nhanh';
      case AiResultSource.localFallback:
        return 'Đang dùng gợi ý nhanh';
      case null:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(blurRadius: 18, color: Color(0x33000000))],
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: iconColor.withValues(alpha: 0.15),
                      child: Icon(icon, color: iconColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          if (headerBadge != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      size: 12,
                                      color: Colors.indigo,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      headerBadge!,
                                      style: const TextStyle(
                                        color: Colors.indigo,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        itemLabel(count, targetCount, unit: unitLabel),
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (loading) const LinearProgressIndicator(minHeight: 2),
              if (loading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Đang cá nhân hoá lại...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              if (source != null && !loading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      sourceLabel(source),
                      style: TextStyle(
                        color: Colors.blueGrey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (!loading && count > 0 && count < targetCount)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mô hình trả về $count/$targetCount kết quả hợp lệ.',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: child,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String itemLabel(int count, int target, {String unit = 'món'}) {
  if (count <= 0) return '0 $unit';
  if (count >= target) return '$target $unit';
  return '$count $unit';
}

String _giftText(GiftSuggestion g) {
  final lines = <String>[g.name];
  if (g.reason != null && g.reason!.isNotEmpty) {
    lines.add('Lý do: ${g.reason}');
  }
  if (g.budget != null && g.budget!.isNotEmpty) {
    lines.add('Ngân sách: ${g.budget}');
  }
  return lines.join('\n');
}

Future<void> _copyText(BuildContext context, String text, String label) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Đã sao chép $label.')));
}

class _GiftSheet extends StatelessWidget {
  const _GiftSheet({
    required this.title,
    required this.targetCount,
    required this.items,
    required this.error,
    required this.onRetry,
    required this.isLoading,
    required this.snap,
    required this.source,
  });

  final String title;
  final int targetCount;
  final GiftSuggestionResult? items;
  final String? error;
  final VoidCallback? onRetry;
  final bool isLoading;
  final BirthdayAiPersonContext snap;
  final AiResultSource? source;

  @override
  Widget build(BuildContext context) {
    final list = items?.items ?? const <GiftSuggestion>[];
    final subtitleParts = <String>[
      if (snap.relationship.isNotEmpty) snap.relationship,
      '${snap.age} tuổi',
    ];
    return _SheetScaffold(
      title: title,
      subtitle: subtitleParts.join(' • '),
      headerBadge: 'Cá nhân hoá theo hồ sơ',
      icon: Icons.card_giftcard,
      iconColor: Colors.purple,
      count: list.length,
      targetCount: targetCount,
      unitLabel: 'món',
      loading: isLoading,
      source: source,
      actions: [
        if (list.isNotEmpty)
          TextButton.icon(
            icon: const Icon(Icons.copy_all),
            label: const Text('Sao chép tất cả'),
            onPressed:
                () => _copyText(
                  context,
                  list.map(_giftText).join('\n\n'),
                  'tất cả',
                ),
          ),
        if (onRetry != null)
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Tạo lại'),
            onPressed: onRetry,
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
      child:
          error != null
              ? _ErrorBlock(error: error!)
              : list.isEmpty && isLoading
              ? ListView.separated(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                itemCount: targetCount,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, __) => const _GiftCardSkeleton(),
              )
              : list.isEmpty
              ? const Center(child: Text('Chưa có gợi ý nào.'))
              : ListView.separated(
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder:
                    (ctx, i) => _GiftCard(
                      index: i + 1,
                      gift: list[i],
                      onCopy:
                          () => _copyText(
                            context,
                            _giftText(list[i]),
                            'gợi ý ${i + 1}',
                          ),
                    ),
              ),
    );
  }
}

class _GiftCardSkeleton extends StatelessWidget {
  const _GiftCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(180),
                  const SizedBox(height: 6),
                  _bar(220),
                  const SizedBox(height: 6),
                  _bar(140),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(double width) => Container(
    width: width,
    height: 10,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({
    required this.index,
    required this.gift,
    required this.onCopy,
  });

  final int index;
  final GiftSuggestion gift;
  final VoidCallback onCopy;

  IconData _categoryIcon(String? cat) {
    if (cat == null) return Icons.card_giftcard;
    final c = cat.toLowerCase();
    if (c.contains('thời trang')) return Icons.checkroom;
    if (c.contains('công nghệ')) return Icons.devices;
    if (c.contains('trải nghiệm')) return Icons.flight_takeoff;
    if (c.contains('chăm sóc')) return Icons.spa;
    if (c.contains('sở thích')) return Icons.palette;
    if (c.contains('đồ dùng')) return Icons.kitchen;
    if (c.contains('kỷ niệm')) return Icons.photo_album;
    if (c.contains('giải trí')) return Icons.theater_comedy;
    if (c.contains('sức khỏe')) return Icons.favorite;
    if (c.contains('sáng tạo')) return Icons.brush;
    return Icons.card_giftcard;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.purple.withValues(alpha: 0.12),
                  child: Text(
                    '#${index.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _categoryIcon(gift.category),
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    gift.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sao chép',
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: onCopy,
                ),
              ],
            ),
            if (gift.reason != null && gift.reason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  gift.reason!,
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (gift.budget != null && gift.budget!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Ngân sách: ${gift.budget}',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (gift.category != null && gift.category!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      gift.category!,
                      style: TextStyle(
                        color: Colors.teal.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WishSheet extends StatelessWidget {
  const _WishSheet({
    required this.title,
    required this.targetCount,
    required this.wishes,
    required this.error,
    required this.onRetry,
    required this.isLoading,
    required this.snap,
    required this.source,
  });

  final String title;
  final int targetCount;
  final BirthdayWishResult? wishes;
  final String? error;
  final VoidCallback? onRetry;
  final bool isLoading;
  final BirthdayAiPersonContext snap;
  final AiResultSource? source;

  @override
  Widget build(BuildContext context) {
    final list = wishes?.wishes ?? const <BirthdayWish>[];
    final subtitleParts = <String>[
      if (snap.relationship.isNotEmpty) snap.relationship,
      '${snap.age} tuổi',
    ];
    return _SheetScaffold(
      title: title,
      subtitle: subtitleParts.join(' • '),
      headerBadge: 'Cá nhân hoá theo hồ sơ',
      icon: Icons.message,
      iconColor: Colors.orange,
      count: list.length,
      targetCount: targetCount,
      unitLabel: 'câu',
      loading: isLoading,
      source: source,
      actions: [
        if (list.isNotEmpty)
          TextButton.icon(
            icon: const Icon(Icons.copy_all),
            label: const Text('Sao chép tất cả'),
            onPressed:
                () => _copyText(
                  context,
                  list.map((w) => w.text).join('\n\n'),
                  'tất cả',
                ),
          ),
        if (onRetry != null)
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Tạo lại'),
            onPressed: onRetry,
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
      child:
          error != null
              ? _ErrorBlock(error: error!)
              : list.isEmpty && isLoading
              ? ListView.separated(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                itemCount: targetCount,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, __) => const _WishCardSkeleton(),
              )
              : list.isEmpty
              ? const Center(child: Text('Chưa có câu chúc nào.'))
              : ListView.separated(
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => _WishCard(index: i + 1, wish: list[i]),
              ),
    );
  }
}

class _WishCardSkeleton extends StatelessWidget {
  const _WishCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 240,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 180,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishCard extends StatefulWidget {
  const _WishCard({required this.index, required this.wish});
  final int index;
  final BirthdayWish wish;

  @override
  State<_WishCard> createState() => _WishCardState();
}

class _WishCardState extends State<_WishCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confirm;
  bool _showCheck = false;

  @override
  void initState() {
    super.initState();
    _confirm = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.wish.text));
    if (!mounted) return;
    setState(() => _showCheck = true);
    _confirm.forward(from: 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã sao chép câu chúc ${widget.index}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.deepOrange.withValues(alpha: 0.12),
                  child: Text(
                    '#${widget.index.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.wish.style,
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder:
                      (c, a) => ScaleTransition(scale: a, child: c),
                  child:
                      _showCheck
                          ? const Icon(
                            Icons.check_circle,
                            key: ValueKey('check'),
                            color: Colors.green,
                            size: 20,
                          )
                          : IconButton(
                            tooltip: 'Sao chép',
                            key: const ValueKey('copy'),
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: _copy,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              widget.wish.text,
              style: const TextStyle(fontSize: 14, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
