import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;

  const AuthResult.success()
      : success = true,
        errorMessage = null;

  const AuthResult.failure(this.errorMessage) : success = false;
}

/// Autentikasi lokal (demo) berbasis SharedPreferences.
///
/// CATATAN PENTING:
/// Implementasi ini adalah autentikasi lokal/demo untuk kebutuhan tugas responsi
/// karena proyek ini belum memiliki konfigurasi Firebase atau backend server.
/// Untuk aplikasi produksi yang aman, gunakan Firebase Authentication atau API backend.
class AuthService {
  static SharedPreferences? _prefs;
  static const String _emailKey = 'user_email';
  static const String _loggedInKey = 'is_logged_in';
  static const String _sessionTokenKey = 'session_token';
  static const String _accountsKey = 'local_demo_accounts';

  static const String demoEmail = 'jasson@gmail.com';
  static const String demoPassword = '123456';

  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  static final ValueNotifier<bool> _authNotifier = ValueNotifier<bool>(false);

  static ValueListenable<bool> get authStateListenable => _authNotifier;

  static Future<void> init({SharedPreferences? prefs}) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    await _seedDemoAccount();
    _authNotifier.value = isLoggedIn;
  }

  static Future<SharedPreferences> _ensurePrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  static Future<void> _seedDemoAccount() async {
    final accounts = _readAccounts();
    if (!accounts.containsKey(demoEmail)) {
      accounts[demoEmail] = _digestPassword(demoEmail, demoPassword);
      await _prefs?.setString(_accountsKey, jsonEncode(accounts));
    }
  }

  static bool get isLoggedIn {
    final loggedIn = _prefs?.getBool(_loggedInKey) ?? false;
    final storedEmail = _prefs?.getString(_emailKey)?.trim() ?? '';
    final token = _prefs?.getString(_sessionTokenKey)?.trim() ?? '';
    return loggedIn && storedEmail.isNotEmpty && token.isNotEmpty;
  }

  static String get email => _prefs?.getString(_emailKey) ?? '';

  static String? validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Format email tidak valid (contoh: nama@email.com)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final raw = value ?? '';
    if (raw.trim().isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (raw.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  static Future<AuthResult> login(String email, String password) async {
    final prefs = await _ensurePrefs();
    final emailError = validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      return AuthResult.failure(passwordError);
    }

    final normalizedEmail = email.trim().toLowerCase();
    final digest = _digestPassword(normalizedEmail, password);
    final accounts = _readAccounts();

    if (accounts.containsKey(normalizedEmail)) {
      if (accounts[normalizedEmail] != digest) {
        return const AuthResult.failure(
          'Email atau password salah. Silakan periksa kembali kredensial Anda.',
        );
      }
    } else {
      // Sesuai ketentuan responsi (kredensial bebas), email baru otomatis
      // didaftarkan sebagai akun lokal demo pada login pertama dan password-nya
      // akan diverifikasi pada login berikutnya.
      accounts[normalizedEmail] = digest;
      await prefs.setString(_accountsKey, jsonEncode(accounts));
    }

    await _saveSession(prefs, normalizedEmail);
    return const AuthResult.success();
  }

  static Future<AuthResult> register(
    String email,
    String password,
    String confirmPassword,
  ) async {
    final prefs = await _ensurePrefs();
    final emailError = validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      return AuthResult.failure(passwordError);
    }

    if (password != confirmPassword) {
      return const AuthResult.failure('Konfirmasi password tidak cocok.');
    }

    final normalizedEmail = email.trim().toLowerCase();
    final accounts = _readAccounts();
    if (accounts.containsKey(normalizedEmail)) {
      return const AuthResult.failure(
        'Email sudah terdaftar. Silakan masuk menggunakan tab Login.',
      );
    }

    accounts[normalizedEmail] = _digestPassword(normalizedEmail, password);
    await prefs.setString(_accountsKey, jsonEncode(accounts));
    await _saveSession(prefs, normalizedEmail);
    return const AuthResult.success();
  }

  static Future<void> logout() async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_loggedInKey, false);
    await prefs.remove(_emailKey);
    await prefs.remove(_sessionTokenKey);
    _authNotifier.value = false;
  }

  static Future<void> _saveSession(
    SharedPreferences prefs,
    String normalizedEmail,
  ) async {
    final token =
        'demo_${normalizedEmail.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(_emailKey, normalizedEmail);
    await prefs.setString(_sessionTokenKey, token);
    await prefs.setBool(_loggedInKey, true);
    _authNotifier.value = true;
  }

  static Map<String, String> _readAccounts() {
    final raw = _prefs?.getString(_accountsKey);
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    } catch (_) {
      // Abaikan data korup dan mulai ulang map akun lokal.
    }
    return <String, String>{};
  }

  /// Hash lokal ringan untuk perbandingan password demo di SharedPreferences
  /// (bukan pengganti hashing kriptografis server-side seperti bcrypt/Argon2).
  static String _digestPassword(String normalizedEmail, String password) {
    final input = utf8.encode('hydra_demo_salt::$normalizedEmail::$password');
    int hash = 0x811c9dc5;
    for (final byte in input) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return '${hash.toRadixString(16).padLeft(8, '0')}_${input.length}';
  }
}
