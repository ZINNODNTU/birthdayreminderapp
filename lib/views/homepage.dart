import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/birthday_controller.dart';
import '../services/firestore_service.dart';
import '../services/csv_export_service.dart';
// import '../services/csv_import_service.dart'; // Uncomment nếu có dịch vụ import
import 'calendar_view.dart';
import 'birthday_list_view.dart';
import 'birthday_add_edit_view.dart';
import 'contact_import.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    CalendarView(),
    BirthdayListView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _backupToFirestore(BuildContext context) async {
    final controller = Provider.of<BirthdayController>(context, listen: false);
    final firestoreService = FirestoreService();

    for (final birthday in controller.birthdays) {
      await firestoreService.backupBirthday(birthday);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao lưu lên Firestore')),
    );
  }

  Future<void> _syncFromFirestore(BuildContext context) async {
    final controller = Provider.of<BirthdayController>(context, listen: false);
    final firestoreService = FirestoreService();

    final firestoreBirthdays = await firestoreService.getBackedUpBirthdays();
    for (final birthday in firestoreBirthdays) {
      await controller.addOrUpdateBirthday(birthday);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đồng bộ từ Firestore')),
    );
  }

  Future<void> _exportToCsv(BuildContext context) async {
    final controller = Provider.of<BirthdayController>(context, listen: false);
    final path = await CsvExportService.exportBirthdaysToCsv(controller.birthdays);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path != null ? 'Đã xuất file CSV: $path' : 'Xuất CSV thất bại',
        ),
      ),
    );
  }

  // Uncomment nếu bạn có dịch vụ import CSV
  /*
  Future<void> _importFromCsv(BuildContext context) async {
    final controller = Provider.of<BirthdayController>(context, listen: false);
    final birthdays = await CsvImportService.importFromCsv();
    for (final b in birthdays) {
      await controller.addOrUpdateBirthday(b);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã nhập từ CSV')),
    );
  }
  */

  void _showAddBirthdayOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Thêm thủ công'),
                onTap: () {
                  Navigator.pop(context);
                  _goToAddManualBirthday();
                },
              ),
              ListTile(
                leading: const Icon(Icons.contacts),
                title: const Text('Thêm từ danh bạ'),
                onTap: () {
                  Navigator.pop(context);
                  _goToImportFromContacts();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToAddManualBirthday() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BirthdayAddEditView()),
    );
  }

  void _goToImportFromContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContactImport()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Birthday Reminder'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Tùy chọn', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Sao lưu lên Firestore'),
              onTap: () async {
                Navigator.pop(context);
                await _backupToFirestore(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Đồng bộ từ Firestore'),
              onTap: () async {
                Navigator.pop(context);
                await _syncFromFirestore(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Xóa toàn bộ trên Firestore'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xác nhận xóa'),
                    content: const Text('Bạn có chắc muốn xóa tất cả sinh nhật trên Firestore không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final firestoreService = FirestoreService();
                  await firestoreService.deleteAllBirthdays();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa toàn bộ dữ liệu trên Firestore')),
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Xuất ra CSV'),
              onTap: () async {
                Navigator.pop(context);
                await _exportToCsv(context);
              },
            ),
            /*
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Nhập từ CSV'),
              onTap: () async {
                Navigator.pop(context);
                await _importFromCsv(context);
              },
            ),
            */
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBirthdayOptions,
        tooltip: 'Thêm sinh nhật',
        child: const Icon(Icons.cake),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => _onItemTapped(0),
              tooltip: 'Trang chủ',
              color: _selectedIndex == 0 ? Colors.teal : Colors.grey,
            ),
            const SizedBox(width: 48), // Khoảng trống cho FAB
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () => _onItemTapped(1),
              tooltip: 'Danh sách',
              color: _selectedIndex == 1 ? Colors.teal : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
