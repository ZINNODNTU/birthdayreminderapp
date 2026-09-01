import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_gate.dart';
import '../../l10n/l10n_extensions.dart';
import 'models/app_release.dart';
import 'models/update_status.dart';
import 'services/app_update_service.dart';
import 'views/update_screen.dart';

class UpdatePromptGate extends StatefulWidget {
  const UpdatePromptGate({super.key});

  @override
  State<UpdatePromptGate> createState() => _UpdatePromptGateState();
}

class _UpdatePromptGateState extends State<UpdatePromptGate> {
  bool _promptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
  }

  Future<void> _check() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final service = context.read<AppUpdateService>();
    await service.checkForUpdates();
    final release = service.latestRelease;
    if (!mounted || _promptShown || release == null) return;
    if (service.status != UpdateStatus.updateAvailable &&
        service.status != UpdateStatus.reinstallRequired) {
      return;
    }
    _promptShown = true;
    final updateNow = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: !release.isMandatory,
      barrierLabel: context.l10n.updateTitle,
      barrierColor: const Color(0xCC050B24),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
      pageBuilder: (_, __, ___) => _MidAutumnUpdateDialog(release: release),
    );
    if (updateNow == true && mounted) {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const UpdateScreen()));
    }
  }

  @override
  Widget build(BuildContext context) => const AuthGate();
}

class _MidAutumnUpdateDialog extends StatelessWidget {
  const _MidAutumnUpdateDialog({required this.release});

  final AppRelease release;

  @override
  Widget build(BuildContext context) {
    final changes = release.changes.isEmpty
        ? [
            context.l10n.fallbackChangeExperience,
            context.l10n.fallbackChangeNotifications,
            context.l10n.fallbackChangeFixes,
            context.l10n.fallbackChangeStability,
          ]
        : release.changes;
    return PopScope(
      canPop: !release.isMandatory,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF152A5B), Color(0xFF07142F)],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0x66FFD36A)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x669A5B00),
                      blurRadius: 40,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Lantern(),
                          Text('🌕', style: TextStyle(fontSize: 64)),
                          _Lantern(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.newVersionAvailable,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFFFE39A),
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Birthday Reminder',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.versionAvailable(release.version),
                        key: const Key('update_version_text'),
                        style: const TextStyle(
                          color: Color(0xFFFFB34D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0x331D3974),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.whatsNew,
                              style: TextStyle(
                                color: Color(0xFFFFD36A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            for (final change in changes)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: Text(
                                  '• $change',
                                  style: const TextStyle(
                                    color: Color(0xFFEAF0FF),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const Key('update_now_button'),
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E2F),
                            foregroundColor: const Color(0xFF271200),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(context.l10n.updateNow),
                        ),
                      ),
                      if (!release.isMandatory) ...[
                        const SizedBox(height: 6),
                        TextButton(
                          key: const Key('update_later_button'),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            context.l10n.later,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Lantern extends StatelessWidget {
  const _Lantern();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(width: 2, height: 16, color: const Color(0xFFFFD36A)),
      Container(
        width: 34,
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFC04D), Color(0xFFE65D22)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x99FF9D2E), blurRadius: 14),
          ],
        ),
      ),
      Container(width: 2, height: 10, color: const Color(0xFFFFD36A)),
    ],
  );
}
