import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/game.dart';

class ApiService {
  static const String _baseUrl = 'https://www.freetogame.com/api';
  static const Duration _timeout = Duration(seconds: 20);
  static const Duration _webDirectTimeout = Duration(seconds: 8);

  /// Pada Flutter Web (Chrome), API FreeToGame tidak selalu menyertakan header
  /// CORS `Access-Control-Allow-Origin`. Aplikasi mencoba endpoint resmi terlebih
  /// dahulu, lalu fallback ke CORS proxy publik khusus mode Web jika diblokir browser.
  static List<Uri> _candidateUris(Uri directUri) {
    if (!kIsWeb) {
      return [directUri];
    }
    final encoded = Uri.encodeComponent(directUri.toString());
    return [
      directUri,
      Uri.parse('https://corsproxy.io/?url=$encoded'),
      Uri.parse('https://api.allorigins.win/raw?url=$encoded'),
    ];
  }

  static Future<String> _getJsonBody(
    Uri directUri, {
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final shouldClose = client == null;
    final uris = _candidateUris(directUri);
    Object? lastError;

    try {
      for (var i = 0; i < uris.length; i++) {
        final uri = uris[i];
        final isWebDirectAttempt = kIsWeb && i == 0 && uris.length > 1;
        try {
          final response = await httpClient
              .get(uri, headers: const {'Accept': 'application/json'})
              .timeout(isWebDirectAttempt ? _webDirectTimeout : _timeout);

          if (response.statusCode == 200) {
            return response.body;
          }
          lastError = Exception(
            'Server mengembalikan HTTP ${response.statusCode}.',
          );
        } catch (error) {
          lastError = error;
        }
      }
    } finally {
      if (shouldClose) {
        httpClient.close();
      }
    }

    if (kIsWeb) {
      throw Exception(
        'Gagal mengambil data dari FreeToGame API di browser (kemungkinan '
        'terkendala koneksi atau kebijakan CORS). Detail: $lastError',
      );
    }
    throw Exception('Gagal menghubungi FreeToGame API: $lastError');
  }

  static Future<List<Game>> fetchGames({http.Client? client}) async {
    final body = await _getJsonBody(
      Uri.parse('$_baseUrl/games'),
      client: client,
    );

    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw const FormatException('Respons /games bukan JSON array.');
    }

    return decoded
        .whereType<Map>()
        .map((item) => Game.fromJson(Map<String, dynamic>.from(item)))
        .where((game) => game.id > 0)
        .toList();
  }

  static Future<Game> fetchGameDetail(int id, {http.Client? client}) async {
    final uri = Uri.parse('$_baseUrl/game')
        .replace(queryParameters: {'id': id.toString()});
    final body = await _getJsonBody(uri, client: client);

    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Respons /game bukan JSON object.');
    }
    return Game.fromJson(Map<String, dynamic>.from(decoded));
  }

  static Future<Game> fetchMergedDetail(
    Game summary, {
    http.Client? client,
  }) async {
    final detail = await fetchGameDetail(summary.id, client: client);
    return summary.mergeDetails(detail);
  }
}
