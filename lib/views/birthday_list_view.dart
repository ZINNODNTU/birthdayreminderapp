import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/birthday_controller.dart';
import '../models/birthday.dart';
import 'birthday_detail_view.dart';
import 'birthday_add_edit_view.dart';
import 'contact_import.dart';
import 'birthday_item.dart';

class BirthdayListView extends StatefulWidget {
  const BirthdayListView({super.key});

  @override
  State<BirthdayListView> createState() => _BirthdayListViewState();
}

class _BirthdayListViewState extends State<BirthdayListView> {
  final Set<Birthday> _selectedBirthdays = {};
  bool _isSelectionMode = false;
  String _searchQuery = '';
  bool _sortAscending = true; // true: sinh nhật gần đến, false: ngược lại

  @override
  Widget build(BuildContext context) {
    final birthdays = context.watch<BirthdayController>().birthdays;

    // Lọc danh sách sinh nhật theo tên tìm kiếm
    final filteredBirthdays = birthdays.where((birthday) {
      return birthday.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Hàm để lấy ngày tháng trong năm hiện tại với sinh nhật (day, month)
    DateTime _getNextBirthdayDate(Birthday birthday) {
      final now = DateTime.now();
      final currentYear = now.year;
      final birthdayDate = DateTime(currentYear, birthday.solarBirthday.month, birthday.solarBirthday.day);
      // Nếu sinh nhật trong năm nay đã qua thì lấy năm sau
      if (birthdayDate.isBefore(now) && !birthdayDate.isAtSameMomentAs(now)) {
        return DateTime(currentYear + 1, birthday.solarBirthday.month, birthday.solarBirthday.day);
      }
      return birthdayDate;
    }

    // Sắp xếp danh sách theo _sortAscending
    filteredBirthdays.sort((a, b) {
      final dateA = _getNextBirthdayDate(a);
      final dateB = _getNextBirthdayDate(b);
      return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('Đã chọn: ${_selectedBirthdays.length}')
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () => _selectAll(filteredBirthdays),
              tooltip: 'Chọn tất cả',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
              tooltip: 'Xóa đã chọn',
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
              tooltip: 'Hủy chọn',
            ),
          ] else ...[
            // Nút mở menu sắp xếp lọc
            PopupMenuButton<bool>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sắp xếp',
              onSelected: (value) {
                setState(() {
                  _sortAscending = value;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: true,
                  child: Row(
                    children: [
                      if (_sortAscending)
                        const Icon(Icons.check, color: Colors.blue)
                      else
                        const SizedBox(width: 24),
                      const SizedBox(width: 8),
                      const Text('Sinh nhật gần đến'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: false,
                  child: Row(
                    children: [
                      if (!_sortAscending)
                        const Icon(Icons.check, color: Colors.blue)
                      else
                        const SizedBox(width: 24),
                      const SizedBox(width: 8),
                      const Text('Sinh nhật xa'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Danh sách sinh nhật
          filteredBirthdays.isEmpty
              ? const Expanded(
            child: Center(child: Text('Chưa có sinh nhật nào')),
          )
              : Expanded(
            child: ListView.builder(
              itemCount: filteredBirthdays.length,
              itemBuilder: (context, index) {
                final birthday = filteredBirthdays[index];
                final isSelected = _selectedBirthdays.contains(birthday);

                return GestureDetector(
                  onLongPress: () => _toggleSelectionMode(birthday),
                  onTap: () => _isSelectionMode
                      ? _toggleSelection(birthday)
                      : _openBirthdayDetail(context, birthday),
                  child: Container(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.transparent,
                    child: BirthdayItem(birthday: birthday),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton(
        onPressed: _deleteSelected,
        tooltip: 'Xóa đã chọn',
        child: const Icon(Icons.delete),
      )
          : null,
    );
  }

  void _toggleSelectionMode(Birthday birthday) {
    setState(() {
      _isSelectionMode = true;
      _selectedBirthdays.add(birthday);
    });
  }

  void _toggleSelection(Birthday birthday) {
    setState(() {
      if (_selectedBirthdays.contains(birthday)) {
        _selectedBirthdays.remove(birthday);
        if (_selectedBirthdays.isEmpty) _isSelectionMode = false;
      } else {
        _selectedBirthdays.add(birthday);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedBirthdays.clear();
      _isSelectionMode = false;
    });
  }

  void _selectAll(List<Birthday> allBirthdays) {
    setState(() {
      _selectedBirthdays.clear();
      _selectedBirthdays.addAll(allBirthdays);
    });
  }

  void _deleteSelected() {
    final controller = context.read<BirthdayController>();
    for (final birthday in _selectedBirthdays) {
      controller.deleteBirthday(birthday.id);
    }
    _clearSelection();
  }

  void _openBirthdayDetail(BuildContext context, Birthday birthday) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BirthdayDetailView(birthday: birthday),
      ),
    );
  }

  void _navigateToAddManual(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BirthdayAddEditView()),
    );
  }

  void _navigateToImportContacts(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactImport()),
    );
  }

  void _showAddOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm sinh nhật'),
          content: const Text('Chọn cách thêm sinh nhật:'),
          actions: [
            TextButton(
              onPressed: () => _navigateToAddManual(context),
              child: const Text('Thêm thủ công'),
            ),
            TextButton(
              onPressed: () => _navigateToImportContacts(context),
              child: const Text('Nhập từ danh bạ'),
            ),
          ],
        );
      },
    );
  }
}
