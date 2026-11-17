import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/login_page.dart';
import 'screens/main_page.dart';
import 'services/auth_service.dart';
import 'services/library_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LibraryService.init();
  await AuthService.init();
  runApp(const HydraGamesApp());
}

class HydraGamesApp extends StatelessWidget {
  const HydraGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4F7CFF);
    return MaterialApp(
      title: 'Hydra Games',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF10131B),
        cardColor: const Color(0xFF1B2030),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF10131B),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1B2030),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Gerbang autentikasi reaktif agar pengguna yang belum login
/// selalu diarahkan ke LoginPage dan tidak bisa membuka halaman utama.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.authStateListenable,
      builder: (context, isLoggedIn, _) {
        if (isLoggedIn && AuthService.isLoggedIn) {
          return const MainPage();
        }
        return const LoginPage();
      },
    );
  }
}
