import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lunar/lunar.dart';
import '../controllers/birthday_controller.dart';
import '../models/birthday.dart';
import 'birthday_detail_view.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    final birthdays = Provider.of<BirthdayController>(context).birthdays;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget buildDayCell(DateTime day, bool isSelected, bool isToday) {
      final lunar = Lunar.fromDate(day);
      final eventCount =
          birthdays.where((b) {
            final date =
                b.calendarType == CalendarType.solar
                    ? b.solarBirthday
                    : b.lunarBirthday.toSolarDateTime();
            return isSameDayAndMonth(date, day);
          }).length;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (isDarkMode ? Colors.blueGrey[700] : Colors.blue[50])
                  : isToday
                  ? (isDarkMode ? Colors.grey[800] : Colors.grey[100])
                  : null,
          border:
              isSelected
                  ? Border.all(color: Colors.blueAccent, width: 2)
                  : isToday
                  ? Border.all(color: Colors.grey, width: 1.5)
                  : eventCount > 0
                  ? Border.all(color: Colors.amber, width: 1.5)
                  : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected || isToday
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
                    '$eventCount',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Calendar
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar(
              locale: 'vi_VN',
              firstDay: DateTime.utc(2000, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate:
                  (day) => isSameDayAndMonth(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: (day) {
                return birthdays.where((b) {
                  final date =
                      b.calendarType == CalendarType.solar
                          ? b.solarBirthday
                          : b.lunarBirthday.toSolarDateTime();
                  return isSameDayAndMonth(date, day);
                }).toList();
              },
              calendarStyle: CalendarStyle(
                markersMaxCount: 0,
                outsideDaysVisible: false,
                weekendTextStyle: GoogleFonts.poppins(color: Colors.redAccent),
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
                defaultBuilder:
                    (context, day, focusedDay) =>
                        buildDayCell(day, false, false),
                selectedBuilder:
                    (context, day, focusedDay) =>
                        buildDayCell(day, true, false),
                todayBuilder:
                    (context, day, focusedDay) =>
                        buildDayCell(day, false, true),
              ),
            ),
          ),
          // Birthday List
          SizedBox(
            height: 320,
            child:
                birthdays.where((b) {
                      final date =
                          b.calendarType == CalendarType.solar
                              ? b.solarBirthday
                              : b.lunarBirthday.toSolarDateTime();
                      return isSameDayAndMonth(date, _selectedDay);
                    }).isEmpty
                    ? Center(
                      child: Text(
                        'Không có sinh nhật nào trong ngày này.',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount:
                          birthdays.where((b) {
                            final date =
                                b.calendarType == CalendarType.solar
                                    ? b.solarBirthday
                                    : b.lunarBirthday.toSolarDateTime();
                            return isSameDayAndMonth(date, _selectedDay);
                          }).length,
                      itemBuilder: (context, index) {
                        final b =
                            birthdays.where((b) {
                              final date =
                                  b.calendarType == CalendarType.solar
                                      ? b.solarBirthday
                                      : b.lunarBirthday.toSolarDateTime();
                              return isSameDayAndMonth(date, _selectedDay);
                            }).toList()[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading:
                                b.avatarBase64 != null
                                    ? CircleAvatar(
                                      radius: 24,
                                      backgroundImage: MemoryImage(
                                        base64Decode(b.avatarBase64!),
                                      ),
                                    )
                                    : CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.pink[100],
                                      child: const Icon(
                                        Icons.cake,
                                        color: Colors.pink,
                                      ),
                                    ),
                            title: Text(
                              b.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              b.calendarType == CalendarType.solar
                                  ? 'Dương lịch'
                                  : 'Âm lịch',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color:
                                  isDarkMode
                                      ? Colors.white70
                                      : Colors.grey[600],
                            ),
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => BirthdayDetailView(birthday: b),
                                  ),
                                ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
