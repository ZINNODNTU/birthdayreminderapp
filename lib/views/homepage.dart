import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/birthday_controller.dart';
import '../core/auth/auth_failure.dart';
import '../core/session/app_session_mode.dart';
import '../core/session/session_controller.dart';
import '../services/csv_export_service.dart';
import '../services/firestore_service.dart';
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

  final List<Widget> _pages = const [CalendarView(), BirthdayListView()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _backupToFirestore(BuildContext context) async {
    final session = context.read<SessionController>();
    if (session.mode != AppSessionMode.authenticated) {
      _showCloudUnavailable(context);
      return;
    }
    final controller = Provider.of<BirthdayController>(context, listen: false);
    await controller.triggerSync();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã sao lưu lên Firestore')));
  }

  Future<void> _syncFromFirestore(BuildContext context) async {
    final session = context.read<SessionController>();
    if (session.mode != AppSessionMode.authenticated) {
      _showCloudUnavailable(context);
      return;
    }
    final controller = Provider.of<BirthdayController>(context, listen: false);
    await controller.triggerSync();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã đồng bộ từ Firestore')));
  }

  void _showCloudUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đăng nhập để sử dụng tính năng đồng bộ đám mây.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _confirmAndDeleteAllFirestore(BuildContext context) async {
    final session = context.read<SessionController>();
    if (session.mode != AppSessionMode.authenticated) {
      _showCloudUnavailable(context);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text(
              'Bạn có chắc muốn xóa tất cả sinh nhật trên Firestore không?',
            ),
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa toàn bộ dữ liệu trên Firestore')),
      );
    }
  }

  Future<void> _exportToCsv(BuildContext context) async {
    final controller = Provider.of<BirthdayController>(context, listen: false);
    final path = await CsvExportService.exportBirthdaysToCsv(
      controller.birthdays,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path != null ? 'Đã xuất file CSV: $path' : 'Xuất CSV thất bại',
        ),
      ),
    );
  }

  Future<void> _exitLocalMode(BuildContext context) async {
    await context.read<SessionController>().exitLocalMode();
    // AuthGate listens to mode changes — no Navigator required.
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    final session = context.read<SessionController>();
    try {
      await session.signInWithGoogle();
    } on AuthFailure catch (e) {
      if (!context.mounted) return;
      if (e is AuthFailureCancelled) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapFailureMessage(e))));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đăng nhập thất bại')));
    }
  }

  Future<void> _signOutGoogle(BuildContext context) async {
    final session = context.read<SessionController>();
    try {
      await session.signOut();
    } catch (_) {}
  }

  String _mapFailureMessage(AuthFailure failure) {
    return switch (failure) {
      AuthFailureNetwork() => 'Không có kết nối mạng',
      AuthFailureConfiguration() =>
        'Đăng nhập Google chưa được cấu hình đúng trên thiết bị này.',
      AuthFailureUiUnavailable() =>
        'Trình chọn tài khoản Google không khả dụng trên thiết bị này.',
      _ => 'Đã xảy ra lỗi, vui lòng thử lại',
    };
  }

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

  /// Rebuild the drawer each frame so it reflects the latest
  /// [AppSessionMode] / [AuthRepository.currentUser].
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Birthday Reminder')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: _buildDrawer(context),
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
            const SizedBox(width: 48),
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

  /// Build the drawer items based on the live session state. Local
  /// mode and authenticated mode show different navigation entries so
  /// the user can always navigate back to a sign-out / exit-local
  /// path from the Homepage.
  List<Widget> _buildDrawer(BuildContext context) {
    final session = context.watch<SessionController>();
    final mode = session.mode;
    final user = session.user;

    final tiles = <Widget>[];
    tiles.add(
      DrawerHeader(
        decoration: const BoxDecoration(color: Colors.blue),
        child: switch (mode) {
          AppSessionMode.authenticated => _buildAuthedHeader(
            user?.displayName,
            user?.email,
          ),
          AppSessionMode.local => const _HeaderText(
            'Đang dùng trên thiết bị',
            'Chỉ lưu cục bộ trên thiết bị này',
          ),
          AppSessionMode.unauthenticated => const _HeaderText(
            'Tùy chọn',
            'Chọn chế độ sử dụng',
          ),
        },
      ),
    );

    tiles.add(
      SwitchListTile(
        key: const ValueKey('drawer_session_mode'),
        value: mode == AppSessionMode.local,
        onChanged:
            mode == AppSessionMode.authenticated
                ? null
                : (value) async {
                  Navigator.pop(context);
                  if (value) {
                    await session.enterLocalMode();
                  } else {
                    await session.exitLocalMode();
                  }
                },
        title: const Text('Chế độ trên thiết bị'),
        subtitle: const Text('Tắt khi bạn muốn dùng tài khoản Google'),
      ),
    );

    if (mode == AppSessionMode.local) {
      tiles.add(
        ListTile(
          key: const ValueKey('drawer_local_sign_in_google'),
          leading: const Icon(Icons.login),
          title: const Text('Đăng nhập bằng Google'),
          onTap: () async {
            Navigator.pop(context);
            await _signInWithGoogle(context);
          },
        ),
      );
      tiles.add(
        ListTile(
          key: const ValueKey('drawer_exit_local'),
          leading: const Icon(Icons.logout),
          title: const Text('Thoát chế độ thiết bị'),
          subtitle: const Text('Quay lại màn hình đăng nhập'),
          onTap: () async {
            Navigator.pop(context);
            await _exitLocalMode(context);
          },
        ),
      );
      tiles.add(
        ListTile(
          key: const ValueKey('drawer_backup_local'),
          leading: const Icon(Icons.backup),
          title: const Text('Sao lưu lên Firestore'),
          onTap: () async {
            Navigator.pop(context);
            await _backupToFirestore(context);
          },
        ),
      );
      tiles.add(
        ListTile(
          key: const ValueKey('drawer_delete_all_local'),
          leading: const Icon(Icons.delete_forever),
          title: const Text('Xóa toàn bộ trên Firestore'),
          onTap: () async {
            Navigator.pop(context);
            await _confirmAndDeleteAllFirestore(context);
          },
        ),
      );
    } else if (mode == AppSessionMode.authenticated) {
      tiles.add(
        ListTile(
          key: const ValueKey('drawer_backup'),
          leading: const Icon(Icons.backup),
          title: const Text('Sao lưu lên Firestore'),
          onTap: () async {
            Navigator.pop(context);
            await _backupToFirestore(context);
          },
        ),
      );
      tiles.add(
        ListTile(
          key: const ValueKey('drawer_sync'),
          leading: const Icon(Icons.sync),
          title: const Text('Đồng bộ từ Firestore'),
          onTap: () async {
            Navigator.pop(context);
            await _syncFromFirestore(context);
          },
        ),
      );
      tiles.add(
        ListTile(
          key: const ValueKey('drawer_delete_all'),
          leading: const Icon(Icons.delete_forever),
          title: const Text('Xóa toàn bộ trên Firestore'),
          onTap: () async {
            Navigator.pop(context);
            final confirm = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Xác nhận xóa'),
                    content: const Text(
                      'Bạn có chắc muốn xóa tất cả sinh nhật trên Firestore không?',
                    ),
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
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa toàn bộ dữ liệu trên Firestore'),
                ),
              );
            }
          },
        ),
      );
    }
    tiles.add(const Divider());
    tiles.add(
      ListTile(
        key: const ValueKey('drawer_export_csv'),
        leading: const Icon(Icons.file_download),
        title: const Text('Xuất ra CSV'),
        onTap: () async {
          Navigator.pop(context);
          await _exportToCsv(context);
        },
      ),
    );
    tiles.add(const Divider());

    if (mode == AppSessionMode.authenticated) {
      tiles.add(
        ListTile(
          key: const ValueKey('drawer_sign_out'),
          leading: const Icon(Icons.logout),
          title: const Text('Đăng xuất'),
          subtitle: Text(user?.email ?? ''),
          onTap: () async {
            Navigator.pop(context);
            await _signOutGoogle(context);
          },
        ),
      );
    }

    return tiles;
  }

  Widget _buildAuthedHeader(String? name, String? email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Đã đăng nhập',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          name ?? email ?? '',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        if (email != null && name != null)
          Text(
            email,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20)),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}
