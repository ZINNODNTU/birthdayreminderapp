import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/birthday_controller.dart';
import '../core/auth/auth_failure.dart';
import '../core/session/app_session_mode.dart';
import '../core/session/session_controller.dart';
import '../services/firestore_service.dart';
import 'calendar_view.dart';
import 'birthday_list_view.dart';
import 'birthday_add_edit_view.dart';
import 'contact_import.dart';
import 'settings_view.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../theme/mid_autumn_theme.dart';
import '../widgets/sync_progress_dialog.dart';
import '../models/sync_progress.dart';
import '../l10n/l10n_extensions.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

enum _DrawerItem {
  home,
  settings,
  guide,
  login,
  exit,
  backup,
  sync,
  delete,
  signOut,
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;
  _DrawerItem _selectedDrawerItem = _DrawerItem.home;

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
    final birthdays = controller.birthdays;
    final total = birthdays.length;
    final progress = ValueNotifier<SyncProgress>(
      SyncProgress(
        current: 0,
        total: total,
        status: context.l10n.backupInProgress,
      ),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => SyncProgressDialog(
            notifier: progress,
            onComplete: () {
              // dialog will auto-close on completion
            },
          ),
    );
    try {
      await controller.triggerSync(
        onProgress: (current, total) {
          progress.value = progress.value.copyWith(
            current: current,
            total: total,
            status: context.l10n.backupInProgress,
          );
        },
      );
      if (!context.mounted) return;
      progress.value = progress.value.copyWith(
        completed: true,
        status: context.l10n.backupSuccess,
        current: total,
        total: total,
      );
    } catch (e) {
      progress.value = progress.value.copyWith(
        completed: true,
        error: context.l10n.errorWithDetails(e.toString()),
        status: context.l10n.failed,
      );
    }
  }

  Future<void> _syncFromFirestore(BuildContext context) async {
    final session = context.read<SessionController>();
    if (session.mode != AppSessionMode.authenticated) {
      _showCloudUnavailable(context);
      return;
    }
    final controller = Provider.of<BirthdayController>(context, listen: false);
    final total = controller.birthdays.length;
    final progress = ValueNotifier<SyncProgress>(
      SyncProgress(current: 0, total: total, status: context.l10n.syncing),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SyncProgressDialog(notifier: progress, onComplete: () {}),
    );
    try {
      await controller.triggerSync(
        onProgress: (current, total) {
          progress.value = progress.value.copyWith(
            current: current,
            // Keep the transaction total stable. SyncManager already
            // calculates it from the pre-sync local/remote snapshot.
            total: progress.value.total,
            status: context.l10n.syncing,
          );
        },
      );
      if (!context.mounted) return;
      final stableTotal = progress.value.total;
      progress.value = progress.value.copyWith(
        completed: true,
        status: context.l10n.syncSuccess,
        current: stableTotal,
        total: stableTotal,
      );
    } catch (e) {
      progress.value = progress.value.copyWith(
        completed: true,
        error: context.l10n.errorWithDetails(e.toString()),
        status: context.l10n.failed,
      );
    }
  }

  void _showCloudUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.cloudUnavailable),
        duration: const Duration(seconds: 3),
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
            title: Text(context.l10n.confirmDelete),
            content: Text(context.l10n.deleteAllFirestoreConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.delete),
              ),
            ],
          ),
    );
    if (confirm == true) {
      final firestoreService = FirestoreService();
      await firestoreService.deleteAllBirthdays();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.deletedAllFirestore)));
    }
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
      ).showSnackBar(SnackBar(content: Text(context.l10n.loginFailed)));
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
      AuthFailureNetwork() => context.l10n.noInternet,
      AuthFailureConfiguration() => context.l10n.googleConfigError,
      AuthFailureUiUnavailable() => context.l10n.googleUiUnavailable,
      _ => context.l10n.authError,
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
                title: Text(context.l10n.manualAdd),
                onTap: () {
                  Navigator.pop(context);
                  _goToAddManualBirthday();
                },
              ),
              ListTile(
                leading: const Icon(Icons.contacts),
                title: Text(context.l10n.contactAdd),
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

  void _goToSettings() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsView()),
    );
  }

  void _goToGuide() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen(manual: true)),
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
        tooltip: context.l10n.addBirthday,
        child: const Icon(Icons.cake),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: MidAutumnColors.night,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => _onItemTapped(0),
              tooltip: context.l10n.home,
              color:
                  _selectedIndex == 0 ? MidAutumnColors.moon : Colors.white54,
            ),
            const SizedBox(width: 48),
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () => _onItemTapped(1),
              tooltip: context.l10n.calendarList,
              color:
                  _selectedIndex == 1 ? MidAutumnColors.moon : Colors.white54,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [MidAutumnColors.night, const Color(0xFF243B73)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: switch (mode) {
          AppSessionMode.authenticated => _buildAuthedHeader(
            user?.displayName,
            user?.email,
          ),
          AppSessionMode.local => _HeaderText(
            context.l10n.usingOnDevice,
            context.l10n.savedLocally,
          ),
          AppSessionMode.unauthenticated => _HeaderText(
            context.l10n.options,
            context.l10n.chooseUsageMode,
          ),
        },
      ),
    );

    tiles.add(
      _buildDrawerTile(
        key: 'drawer_settings',
        icon: Icons.settings,
        title: context.l10n.settings,
        subtitle: context.l10n.settingsSubtitle,
        item: _DrawerItem.settings,
        onTap: () {
          setState(() => _selectedDrawerItem = _DrawerItem.settings);
          _goToSettings();
        },
      ),
    );
    tiles.add(
      _buildDrawerTile(
        key: 'drawer_guide',
        icon: Icons.menu_book_outlined,
        title: context.l10n.userGuide,
        subtitle: context.l10n.guideSubtitle,
        item: _DrawerItem.guide,
        onTap: () {
          setState(() => _selectedDrawerItem = _DrawerItem.guide);
          _goToGuide();
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
        title: Text(
          context.l10n.localMode,
          style: TextStyle(color: MidAutumnColors.textPrimary),
        ),
        subtitle: Text(
          context.l10n.localModeSubtitle,
          style: TextStyle(color: MidAutumnColors.textSecondary),
        ),
        activeThumbColor: MidAutumnColors.moon,
      ),
    );

    if (mode == AppSessionMode.local) {
      tiles.add(
        _buildDrawerTile(
          key: 'drawer_local_sign_in_google',
          icon: Icons.login,
          title: context.l10n.signInGoogle,
          item: _DrawerItem.login,
          onTap: () async {
            Navigator.pop(context);
            await _signInWithGoogle(context);
          },
        ),
      );
      tiles.add(
        _buildDrawerTile(
          key: 'drawer_exit_local',
          icon: Icons.logout,
          title: context.l10n.exitLocalMode,
          subtitle: context.l10n.backToLogin,
          item: _DrawerItem.exit,
          onTap: () async {
            Navigator.pop(context);
            await _exitLocalMode(context);
          },
        ),
      );
      tiles.add(
        _buildDrawerTile(
          key: 'drawer_backup_local',
          icon: Icons.backup,
          title: context.l10n.backupToFirestore,
          item: _DrawerItem.backup,
          onTap: () async {
            Navigator.pop(context);
            await _backupToFirestore(context);
          },
        ),
      );
      tiles.add(
        _buildDrawerTile(
          key: 'drawer_delete_all_local',
          icon: Icons.delete_forever,
          title: context.l10n.deleteAllFirestore,
          item: _DrawerItem.delete,
          onTap: () async {
            Navigator.pop(context);
            await _confirmAndDeleteAllFirestore(context);
          },
        ),
      );
    } else if (mode == AppSessionMode.authenticated) {
      tiles.add(
        _buildDrawerTile(
          key: 'drawer_backup',
          icon: Icons.backup,
          title: context.l10n.backupToFirestore,
          item: _DrawerItem.backup,
          onTap: () async {
            Navigator.pop(context);
            await _backupToFirestore(context);
          },
        ),
      );
      tiles.add(
        _buildDrawerTile(
          key: 'drawer_sync',
          icon: Icons.sync,
          title: context.l10n.syncFromFirestore,
          item: _DrawerItem.sync,
          onTap: () async {
            Navigator.pop(context);
            await _syncFromFirestore(context);
          },
        ),
      );
      tiles.add(
        _buildDrawerTile(
          key: 'drawer_delete_all',
          icon: Icons.delete_forever,
          title: context.l10n.deleteAllFirestore,
          item: _DrawerItem.delete,
          onTap: () async {
            Navigator.pop(context);
            final confirm = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text(context.l10n.confirmDelete),
                    content: Text(context.l10n.deleteAllFirestoreConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(context.l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(context.l10n.delete),
                      ),
                    ],
                  ),
            );
            if (confirm == true) {
              final firestoreService = FirestoreService();
              await firestoreService.deleteAllBirthdays();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.deletedAllFirestore)),
              );
            }
          },
        ),
      );
    }

    if (mode == AppSessionMode.authenticated) {
      tiles.add(
        _buildDrawerTile(
          key: 'drawer_sign_out',
          icon: Icons.logout,
          title: context.l10n.signOut,
          subtitle: user?.email ?? '',
          item: _DrawerItem.signOut,
          onTap: () async {
            Navigator.pop(context);
            await _signOutGoogle(context);
          },
        ),
      );
    }

    return tiles;
  }

  Widget _buildDrawerTile({
    required String key,
    required IconData icon,
    required String title,
    String? subtitle,
    required _DrawerItem item,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedDrawerItem == item;
    return ListTile(
      key: ValueKey(key),
      selected: isSelected,
      selectedTileColor: MidAutumnColors.moon.withValues(alpha: 0.15),
      leading: Icon(
        icon,
        color:
            isSelected ? MidAutumnColors.moon : MidAutumnColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color:
              isSelected
                  ? MidAutumnColors.textPrimary
                  : MidAutumnColors.textSecondary,
        ),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: TextStyle(
                  color:
                      isSelected
                          ? MidAutumnColors.textSecondary
                          : MidAutumnColors.textSecondary.withValues(
                            alpha: 0.7,
                          ),
                  fontSize: 12,
                ),
              )
              : null,
      onTap: onTap,
    );
  }

  Widget _buildAuthedHeader(String? name, String? email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.l10n.authenticated,
          style: const TextStyle(color: Colors.white, fontSize: 16),
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
