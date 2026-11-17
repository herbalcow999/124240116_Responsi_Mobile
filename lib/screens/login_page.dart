import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _loading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final result = _isRegisterMode
          ? await AuthService.register(
              _emailController.text,
              _passwordController.text,
              _confirmPasswordController.text,
            )
          : await AuthService.login(
              _emailController.text,
              _passwordController.text,
            );

      if (!mounted) return;
      if (!result.success) {
        setState(() {
          _loading = false;
          _errorMessage =
              result.errorMessage ?? 'Autentikasi gagal. Silakan coba lagi.';
        });
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Terjadi kesalahan saat memproses autentikasi: $error';
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _errorMessage = null;
      _confirmPasswordController.clear();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.sports_esports,
                      size: 74,
                      color: Color(0xFF6D91FF),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'HYDRA GAMES',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegisterMode
                          ? 'Buat akun lokal baru untuk mulai menjelajah game'
                          : 'Masuk untuk menjelajah dan menyimpan game favoritmu',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 28),
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      key: const Key('login_email_field'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        labelText: 'Email',
                        hintText: 'contoh@email.com',
                      ),
                      validator: AuthService.validateEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('login_password_field'),
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      textInputAction: _isRegisterMode
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted:
                          _isRegisterMode ? null : (_) => _submit(),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        labelText: 'Password',
                        hintText: 'Minimal 6 karakter',
                        suffixIcon: IconButton(
                          key: const Key('toggle_password_visibility'),
                          tooltip: _hidePassword
                              ? 'Tampilkan password'
                              : 'Sembunyikan password',
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: AuthService.validatePassword,
                    ),
                    if (_isRegisterMode) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('register_confirm_password_field'),
                        controller: _confirmPasswordController,
                        obscureText: _hideConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          labelText: 'Konfirmasi Password',
                          suffixIcon: IconButton(
                            tooltip: _hideConfirmPassword
                                ? 'Tampilkan password'
                                : 'Sembunyikan password',
                            icon: Icon(
                              _hideConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _hideConfirmPassword = !_hideConfirmPassword,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi password wajib diisi';
                          }
                          if (value != _passwordController.text) {
                            return 'Konfirmasi password tidak cocok';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      key: const Key('login_submit_button'),
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isRegisterMode ? 'DAFTAR & MASUK' : 'LOGIN',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      key: const Key('toggle_auth_mode_button'),
                      onPressed: _loading ? null : _toggleMode,
                      child: Text(
                        _isRegisterMode
                            ? 'Sudah punya akun? Masuk di sini'
                            : 'Belum punya akun? Daftar akun lokal',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2030),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Akun demo:\nGmail: ${AuthService.demoEmail}\npassword:${AuthService.demoPassword}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
