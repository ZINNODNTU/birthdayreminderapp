import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_failure.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/session/session_controller.dart';

/// Google-only authentication + Local Mode entry screen.
///
/// The screen intentionally does NOT collect any credentials itself:
/// authentication is delegated to the platform's Google account chooser,
/// and the "Continue on device" path is provided by [SessionController].
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _googleInFlight = false;
  bool _localInFlight = false;

  Future<void> _signInWithGoogle() async {
    if (_googleInFlight || _localInFlight) return;
    setState(() => _googleInFlight = true);
    try {
      await context.read<AuthRepository>().signInWithGoogle();
      // AuthGate listens to authStateChanges and routes to Homepage.
    } on AuthFailure catch (e) {
      if (!mounted) return;
      // Cancellation is not an error — keep the user where they are.
      if (e is AuthFailureCancelled) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapFailureMessage(e))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xảy ra lỗi, vui lòng thử lại')),
      );
    } finally {
      if (mounted) setState(() => _googleInFlight = false);
    }
  }

  Future<void> _continueOnDevice() async {
    if (_googleInFlight || _localInFlight) return;
    setState(() => _localInFlight = true);
    try {
      await context.read<SessionController>().enableLocalMode();
    } finally {
      if (mounted) setState(() => _localInFlight = false);
    }
  }

  String _mapFailureMessage(AuthFailure failure) {
    return switch (failure) {
      AuthFailureNetwork() => 'Không có kết nối mạng',
      AuthFailureUserDisabled() => 'Tài khoản đã bị vô hiệu hóa',
      AuthFailureOperationNotAllowed() =>
        'Đăng nhập bằng Google chưa được bật. Vui lòng liên hệ quản trị viên.',
      AuthFailureTooManyRequests() => 'Quá nhiều yêu cầu, vui lòng thử lại sau',
      _ => 'Đã xảy ra lỗi, vui lòng thử lại',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inFlight = _googleInFlight || _localInFlight;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.cake_outlined,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Birthday Reminder',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Đừng để một sinh nhật nào trôi qua mà không được nhớ đến.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  key: const ValueKey('continue_with_google_button'),
                  onPressed: inFlight ? null : _signInWithGoogle,
                  icon:
                      _googleInFlight
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text(
                            'G',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                  label: const Text('Tiếp tục với Google'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('hoặc', style: theme.textTheme.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const ValueKey('continue_on_device_button'),
                  onPressed: inFlight ? null : _continueOnDevice,
                  icon:
                      _localInFlight
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.devices),
                  label: const Text('Tiếp tục trên thiết bị'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bạn vẫn có thể sử dụng sinh nhật, lịch và nhắc nhở trên '
                  'thiết bị. Các tính năng đồng bộ đám mây yêu cầu đăng nhập.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
