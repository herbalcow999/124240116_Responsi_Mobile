import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hydra_games/models/game.dart';
import 'package:hydra_games/screens/detail_page.dart';
import 'package:hydra_games/screens/library_page.dart';
import 'package:hydra_games/screens/login_page.dart';
import 'package:hydra_games/screens/profile_page.dart';
import 'package:hydra_games/services/api_service.dart';
import 'package:hydra_games/services/auth_service.dart';
import 'package:hydra_games/services/library_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Game _sampleGame({int id = 540, String title = 'Overwatch 2'}) {
  return Game(
    id: id,
    title: title,
    thumbnail: '',
    genre: 'Shooter',
    platform: 'PC (Windows)',
    shortDescription: 'A hero-focused first-person team shooter.',
    gameUrl: 'https://www.freetogame.com/open/overwatch-2',
    profileUrl: 'https://www.freetogame.com/overwatch-2',
    publisher: 'Activision Blizzard',
    developer: 'Blizzard Entertainment',
    releaseDate: '2022-10-04',
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hydra_games_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.init();
    if (Hive.isBoxOpen('game_library_test')) {
      await Hive.box<String>('game_library_test').clear();
    } else {
      await Hive.openBox<String>('game_library_test');
    }
    await LibraryService.init(testBox: Hive.box<String>('game_library_test'));
  });

  tearDown(() async {
    if (Hive.isBoxOpen('game_library_test')) {
      await Hive.box<String>('game_library_test').clear();
    }
  });

  group('Game model & detail merging', () {
    test('mergeDetails keeps summary fields when detail response is partial', () {
      final summary = _sampleGame();
      final partialDetail = Game.fromJson({
        'id': 540,
        'title': '',
        'genre': '-',
        'platform': '',
        'description': 'Full game description from /game endpoint.',
        'status': 'Live',
        'minimum_system_requirements': {
          'os': 'Windows 10 64-bit',
          'memory': '6 GB RAM',
        },
        'screenshots': [
          {'id': 1, 'image': 'https://www.freetogame.com/g/540/ow2-1.jpg'},
        ],
      });

      final merged = summary.mergeDetails(partialDetail);

      expect(merged.id, 540);
      expect(merged.title, 'Overwatch 2');
      expect(merged.genre, 'Shooter');
      expect(merged.platform, 'PC (Windows)');
      expect(merged.publisher, 'Activision Blizzard');
      expect(merged.developer, 'Blizzard Entertainment');
      expect(merged.description, 'Full game description from /game endpoint.');
      expect(merged.status, 'Live');
      expect(merged.minimumSystemRequirements['os'], 'Windows 10 64-bit');
      expect(merged.screenshots.length, 1);
    });
  });

  group('ApiService', () {
    test('fetchGames and fetchMergedDetail parse FreeToGame responses', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/games')) {
          return http.Response(
            jsonEncode([
              {
                'id': 540,
                'title': 'Overwatch 2',
                'thumbnail': 'https://www.freetogame.com/g/540/thumbnail.jpg',
                'short_description': 'Team shooter',
                'game_url': 'https://www.freetogame.com/open/overwatch-2',
                'genre': 'Shooter',
                'platform': 'PC (Windows)',
                'publisher': 'Activision Blizzard',
                'developer': 'Blizzard Entertainment',
                'release_date': '2022-10-04',
                'freetogame_profile_url':
                    'https://www.freetogame.com/overwatch-2',
              }
            ]),
            200,
          );
        }
        if (request.url.path.endsWith('/game') &&
            request.url.queryParameters['id'] == '540') {
          return http.Response(
            jsonEncode({
              'id': 540,
              'status': 'Live',
              'description': 'Detailed description',
              'screenshots': [
                {'image': 'https://www.freetogame.com/g/540/ss1.jpg'}
              ],
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final games = await ApiService.fetchGames(client: mockClient);
      expect(games, hasLength(1));
      expect(games.first.title, 'Overwatch 2');

      final merged =
          await ApiService.fetchMergedDetail(games.first, client: mockClient);
      expect(merged.title, 'Overwatch 2');
      expect(merged.description, 'Detailed description');
      expect(merged.screenshots, hasLength(1));
    });
  });

  group('AuthService local session & validation', () {
    test('rejects wrong password, saves session, persists, and logs out', () async {
      expect(AuthService.isLoggedIn, isFalse);

      final wrongDemo = await AuthService.login(
        AuthService.demoEmail,
        'wrongpass',
      );
      expect(wrongDemo.success, isFalse);
      expect(wrongDemo.errorMessage, isNotNull);
      expect(AuthService.isLoggedIn, isFalse);

      final okDemo = await AuthService.login(
        AuthService.demoEmail,
        AuthService.demoPassword,
      );
      expect(okDemo.success, isTrue);
      expect(AuthService.isLoggedIn, isTrue);
      expect(AuthService.email, AuthService.demoEmail);

      // Simulasi aplikasi ditutup lalu dibuka kembali (re-init SharedPreferences)
      await AuthService.init();
      expect(AuthService.isLoggedIn, isTrue);
      expect(AuthService.email, AuthService.demoEmail);

      // Logout menghapus session
      await AuthService.logout();
      expect(AuthService.isLoggedIn, isFalse);
      expect(AuthService.email, isEmpty);
    });

    test('register prevents duplicates and verifies password on next login', () async {
      final reg = await AuthService.register(
        'gamer@upnyk.ac.id',
        'secret123',
        'secret123',
      );
      expect(reg.success, isTrue);
      expect(AuthService.isLoggedIn, isTrue);

      await AuthService.logout();

      final duplicate = await AuthService.register(
        'gamer@upnyk.ac.id',
        'secret123',
        'secret123',
      );
      expect(duplicate.success, isFalse);

      final badPass = await AuthService.login('gamer@upnyk.ac.id', 'other999');
      expect(badPass.success, isFalse);

      final goodPass = await AuthService.login('gamer@upnyk.ac.id', 'secret123');
      expect(goodPass.success, isTrue);
    });
  });

  group('LibraryService Hive persistence & reactive updates', () {
    test('persists games across Hive box reopen and notifies listeners', () async {
      var notificationCount = 0;
      final listenable = LibraryService.listenable();
      void listener() => notificationCount++;
      listenable.addListener(listener);

      final game = _sampleGame(id: 99, title: 'Genshin Impact');
      await LibraryService.add(game);
      expect(notificationCount, greaterThan(0));
      expect(LibraryService.contains(99), isTrue);

      listenable.removeListener(listener);

      // Tutup lalu buka kembali box untuk menguji persistensi Hive
      await Hive.box<String>('game_library_test').close();
      final reopened = await Hive.openBox<String>('game_library_test');
      await LibraryService.init(testBox: reopened);

      expect(LibraryService.contains(99), isTrue);
      expect(LibraryService.games.first.title, 'Genshin Impact');
    });
  });

  group('Widget tests: Login, Reactive Library, Detail, and Profile', () {
    testWidgets('LoginPage validates inputs, toggles password, and handles errors',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Submit kosong -> tampil pesan validasi
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();
      expect(find.text('Email tidak boleh kosong'), findsOneWidget);
      expect(find.text('Password tidak boleh kosong'), findsOneWidget);

      // Password tersembunyi default dan bisa di-toggle
      EditableText passwordEditable() => tester.widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('login_password_field')),
              matching: find.byType(EditableText),
            ),
          );
      expect(passwordEditable().obscureText, isTrue);

      await tester.tap(find.byKey(const Key('toggle_password_visibility')));
      await tester.pump();
      expect(passwordEditable().obscureText, isFalse);

      // Password salah untuk akun demo -> muncul pesan error autentikasi
      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        AuthService.demoEmail,
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'salah123',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Email atau password salah'),
        findsOneWidget,
      );
    });

    testWidgets(
      'LibraryPage and ProfilePage in IndexedStack update immediately on Hive add/remove',
      (tester) async {
        await AuthService.login(AuthService.demoEmail, AuthService.demoPassword);

        var currentIndex = 0;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) => MaterialApp(
              home: Scaffold(
                body: IndexedStack(
                  index: currentIndex,
                  children: const [
                    LibraryPage(),
                    ProfilePage(),
                  ],
                ),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: currentIndex,
                  onTap: (i) => setState(() => currentIndex = i),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.list),
                      label: 'Library',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('Library masih kosong'), findsOneWidget);

        // Tambah game langsung ke Hive (seperti dari DetailPage) tanpa refresh
        final game = _sampleGame(id: 540, title: 'Overwatch 2');
        await tester.runAsync(() => LibraryService.add(game));
        await tester.pump();

        expect(find.text('Overwatch 2'), findsOneWidget);

        // Pindah ke ProfilePage (yang tetap mounted di IndexedStack)
        await tester.tap(find.text('Profile'));
        await tester.pump();
        expect(find.text(AuthService.demoEmail), findsOneWidget);
        expect(find.text('1 game'), findsOneWidget);

        // Hapus game dari Hive -> ProfilePage langsung berubah ke 0 game
        await tester.runAsync(() => LibraryService.remove(540));
        await tester.pump();
        expect(find.text('0 game'), findsOneWidget);

        // Kembali ke LibraryPage -> game sudah langsung hilang
        await tester.tap(find.text('Library'));
        await tester.pump();
        expect(find.text('Library masih kosong'), findsOneWidget);
      },
    );

    testWidgets('DetailPage Add/Remove buttons update Hive immediately',
        (tester) async {
      final game = _sampleGame(id: 777, title: 'Valorant');
      await tester.pumpWidget(
        MaterialApp(
          home: DetailPage(initialGame: game, fetchRemoteDetails: false),
        ),
      );

      final addButton = find.byKey(const Key('add_to_library_button'));
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      expect(LibraryService.contains(777), isTrue);
      final removeButton = find.byKey(const Key('remove_from_library_button'));
      await tester.ensureVisible(removeButton);
      await tester.pumpAndSettle();
      expect(removeButton, findsOneWidget);

      await tester.tap(removeButton);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      expect(LibraryService.contains(777), isFalse);
      expect(addButton, findsOneWidget);
    });

    testWidgets('ProfilePage Logout clears session and returns to LoginPage',
        (tester) async {
      await AuthService.login(AuthService.demoEmail, AuthService.demoPassword);

      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      expect(find.text(AuthService.demoEmail), findsOneWidget);

      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();

      expect(AuthService.isLoggedIn, isFalse);
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
