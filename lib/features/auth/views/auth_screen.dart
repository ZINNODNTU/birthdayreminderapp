import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/auth_failure.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = context.read<AuthRepository>();
    try {
      if (_isLogin) {
        await auth.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await auth.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      if (!mounted) return;
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapFailureMessage(e))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xảy ra lỗi, vui lòng thử lại')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapFailureMessage(AuthFailure failure) {
    return switch (failure) {
      AuthFailureNetwork() => 'Không có kết nối mạng',
      AuthFailureInvalidEmail() => 'Email không hợp lệ',
      AuthFailureInvalidCredential() => 'Sai email hoặc mật khẩu',
      AuthFailureWrongPassword() => 'Sai mật khẩu',
      AuthFailureUserNotFound() => 'Không tìm thấy người dùng',
      AuthFailureUserDisabled() => 'Tài khoản đã bị vô hiệu hóa',
      AuthFailureEmailAlreadyInUse() => 'Email đã được sử dụng',
      AuthFailureWeakPassword() => 'Mật khẩu quá yếu (tối thiểu 6 ký tự)',
      AuthFailureOperationNotAllowed() => 'Phương thức đăng nhập chưa được bật',
      AuthFailureTooManyRequests() => 'Quá nhiều yêu cầu, vui lòng thử lại sau',
      _ => 'Đã xảy ra lỗi, vui lòng thử lại',
    };
  }

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Vui lòng nhập email';
    if (!_emailRegex.hasMatch(value)) return 'Email không hợp lệ';
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (!_isLogin && value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập email để đặt lại mật khẩu'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final auth = context.read<AuthRepository>();
    try {
      await auth.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email đặt lại mật khẩu đã được gửi')),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapFailureMessage(e))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xảy ra lỗi')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký'),
                ),
              const SizedBox(height: 12),
              if (_isLogin)
                TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Quên mật khẩu?'),
                ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin
                      ? 'Chưa có tài khoản? Đăng ký'
                      : 'Đã có tài khoản? Đăng nhập',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
