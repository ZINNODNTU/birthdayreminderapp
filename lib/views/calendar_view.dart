import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lunar/lunar.dart';

import '../controllers/birthday_controller.dart';
import '../features/birthdays/domain/birthday_engine.dart';
import '../models/birthday.dart';
import 'birthday_detail_view.dart';

import 'package:google_fonts/google_fonts.dart';

import '../services/avatar_cache.dart';
import '../services/locale_service.dart';
import '../l10n/l10n_extensions.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool isSameDayAndMonth(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.day == date2.day && date1.month == date2.month;
  }

  /// Resolve a [Birthday] to its solar occurrence in [year] using the
  /// shared [BirthdayEngine]. Lunar birthdays are re-converted per year
  /// (the recurring-lunar fix).
  DateTime _occurrence(Birthday b, int year, BirthdayEngine engine) {
    return engine.occurrenceInYear(b, year);
  }

  DateTime _dayKey(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    final birthdays = Provider.of<BirthdayController>(context).birthdays;
    final engine = context.read<BirthdayEngine>();
    final locale = context.watch<LocaleService>().locale;
    final tableCalendarLocale = switch (locale.languageCode) {
      'zh' => 'zh_CN',
      'en' => 'en_US',
      _ => 'vi_VN',
    };
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final focusedYear = _focusedDay.year;
    // Precompute event counts and lists for the focused year to avoid per-cell iteration.
    final eventsByDay = <DateTime, List<Birthday>>{};
    final eventCounts = <DateTime, int>{};
    for (final b in birthdays) {
      final date = b.calendarType == CalendarType.solar
          ? DateTime(focusedYear, b.solarBirthday.month, b.solarBirthday.day)
          : _occurrence(b, focusedYear, engine);
      final key = _dayKey(date);
      eventsByDay.putIfAbsent(key, () => []).add(b);
      eventCounts[key] = (eventCounts[key] ?? 0) + 1;
    }
    final monthEntries =
        eventsByDay.entries
            .where(
              (e) =>
                  e.key.year == _focusedDay.year &&
                  e.key.month == _focusedDay.month,
            )
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    final selectedBirthdays = _selectedDay == null
        ? const <Birthday>[]
        : eventsByDay[_dayKey(_selectedDay!)] ?? const <Birthday>[];
    final monthBirthdayCount = monthEntries.fold<int>(
      0,
      (total, entry) => total + entry.value.length,
    );

    Widget buildDayCell(DateTime day, bool isSelected, bool isToday) {
      final lunar = Lunar.fromDate(day);
      final eventCount = eventCounts[_dayKey(day)] ?? 0;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? Colors.blueGrey[700] : Colors.blue[50])
              : isToday
              ? (isDarkMode ? Colors.grey[800] : Colors.grey[100])
              : null,
          border: isSelected
              ? Border.all(color: Colors.blueAccent, width: 2)
              : isToday
              ? Border.all(color: Colors.grey, width: 1.5)
              : eventCount > 0
              ? Border.all(color: Colors.amber, width: 1.5)
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected || isToday
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '${lunar.getDay()}-${lunar.getMonth()}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (eventCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.redAccent, Colors.pinkAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    eventCount > 99 ? '99+' : '$eventCount',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Reserve space so the final birthday card always clears the
    // persistent BottomAppBar + centered FAB + system bottom inset.
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final bottomNavHeight = kBottomNavigationBarHeight + bottomSafeArea;
    final fabOverlapAllowance = 56.0 + 8.0 + 16.0;
    final bottomInset = bottomNavHeight + fabOverlapAllowance;

    return Column(
      children: [
        Expanded(
          child: ListView(
            key: const ValueKey('calendar-scroll'),
            padding: EdgeInsets.only(bottom: bottomInset),
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TableCalendar(
                  locale: tableCalendarLocale,
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      _selectedDay != null &&
                      isSameDayAndMonth(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay =
                          isSameDayAndMonth(_selectedDay, selectedDay)
                          ? null
                          : selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                      _selectedDay = null;
                    });
                  },
                  eventLoader: (day) =>
                      eventsByDay[_dayKey(day)] ?? const <Birthday>[],
                  calendarStyle: CalendarStyle(
                    markersMaxCount: 0,
                    outsideDaysVisible: false,
                    weekendTextStyle: GoogleFonts.poppins(
                      color: Colors.redAccent,
                    ),
                    defaultTextStyle: GoogleFonts.poppins(),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) =>
                        buildDayCell(day, false, false),
                    selectedBuilder: (context, day, focusedDay) =>
                        buildDayCell(day, true, false),
                    todayBuilder: (context, day, focusedDay) =>
                        buildDayCell(day, false, true),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDay == null
                            ? context.l10n.monthBirthdays(
                                _focusedDay.month,
                                monthBirthdayCount,
                              )
                            : context.l10n.dayBirthdays(
                                '${_selectedDay!.day.toString().padLeft(2, '0')}/${_selectedDay!.month.toString().padLeft(2, '0')}',
                              ),
                        key: const ValueKey('calendar-list-title'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (_selectedDay != null)
                      ActionChip(
                        key: const ValueKey('calendar-show-month'),
                        avatar: const Icon(Icons.calendar_month, size: 18),
                        label: Text(context.l10n.showMonth),
                        onPressed: () => setState(() => _selectedDay = null),
                      ),
                  ],
                ),
              ),
              if (_selectedDay == null && monthEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(context.l10n.noMonthBirthdays)),
                )
              else if (_selectedDay != null && selectedBirthdays.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(context.l10n.noDayBirthdays)),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    key: ValueKey(
                      _selectedDay == null
                          ? 'calendar-month-list'
                          : 'calendar-day-list',
                    ),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final entry in monthEntries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                          child: Text(
                            '${entry.key.day.toString().padLeft(2, '0')}/${entry.key.month.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        for (final birthday in entry.value)
                          _BirthdayCalendarTile(
                            birthday: birthday,
                            isDarkMode: isDarkMode,
                          ),
                      ],
                      if (_selectedDay != null)
                        for (final birthday in selectedBirthdays)
                          _BirthdayCalendarTile(
                            birthday: birthday,
                            isDarkMode: isDarkMode,
                          ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BirthdayCalendarTile extends StatelessWidget {
  const _BirthdayCalendarTile({
    required this.birthday,
    required this.isDarkMode,
  });

  final Birthday birthday;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final avatar = birthday.avatarBase64 == null
        ? null
        : AvatarCache.decodeAndCache(birthday.avatarBase64!);
    return Card(
      key: ValueKey('calendar-birthday-${birthday.id}'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.pink[100],
          backgroundImage: avatar == null ? null : MemoryImage(avatar),
          child: avatar == null
              ? const Icon(Icons.cake, color: Colors.pink)
              : null,
        ),
        title: Text(
          birthday.name,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          birthday.calendarType == CalendarType.solar
              ? context.l10n.solar
              : context.l10n.lunar,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BirthdayDetailView(birthday: birthday),
          ),
        ),
      ),
    );
  }
}
