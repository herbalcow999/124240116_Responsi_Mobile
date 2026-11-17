import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game.dart';

class LibraryService {
  static const String _boxName = 'game_library';
  static Box<String>? _box;

  static Future<void> init({Box<String>? testBox}) async {
    if (testBox != null) {
      _box = testBox;
      return;
    }
    if (_box != null && _box!.isOpen) {
      return;
    }
    _box = await Hive.openBox<String>(_boxName);
  }

  static Box<String> get _requireBox {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError(
        'LibraryService belum diinisialisasi. Panggil LibraryService.init() terlebih dahulu.',
      );
    }
    return box;
  }

  /// Listener reaktif Hive agar LibraryPage, ProfilePage, dan DetailPage
  /// otomatis diperbarui setiap ada penambahan/penghapusan game tanpa refresh.
  static ValueListenable<Box<String>> listenable() => _requireBox.listenable();

  static List<Game> gamesFromBox(Box<String> box) {
    final result = <Game>[];
    for (final raw in box.values) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final game = Game.fromJson(Map<String, dynamic>.from(decoded));
          if (game.id > 0) {
            result.add(game);
          }
        }
      } catch (_) {
        // Lewati entri yang tidak valid agar UI tetap stabil.
      }
    }
    return result;
  }

  static List<Game> get games {
    final box = _box;
    if (box == null || !box.isOpen) return const [];
    return gamesFromBox(box);
  }

  static int get count {
    final box = _box;
    if (box == null || !box.isOpen) return 0;
    return box.length;
  }

  static bool contains(int id) => _box?.containsKey(id.toString()) ?? false;

  static bool containsInBox(Box<String> box, int id) =>
      box.containsKey(id.toString());

  static Future<void> add(Game game) async {
    await _requireBox.put(game.id.toString(), jsonEncode(game.toJson()));
  }

  static Future<void> remove(int id) async {
    await _requireBox.delete(id.toString());
  }

  /// Perbarui detail game di Hive jika game sudah dimiliki pengguna.
  static Future<void> updateIfOwned(Game game) async {
    if (contains(game.id)) {
      await add(game);
    }
  }

  @visibleForTesting
  static void resetForTesting() {
    _box = null;
  }
}
