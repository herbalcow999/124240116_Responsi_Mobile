class Game {
  final int id;
  final String title;
  final String thumbnail;
  final String genre;
  final String platform;
  final String shortDescription;
  final String gameUrl;
  final String profileUrl;
  final String publisher;
  final String developer;
  final String releaseDate;
  final String? description;
  final String? status;
  final Map<String, String> minimumSystemRequirements;
  final List<String> screenshots;

  const Game({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.genre,
    required this.platform,
    required this.shortDescription,
    required this.gameUrl,
    required this.publisher,
    required this.developer,
    required this.releaseDate,
    this.profileUrl = '',
    this.description,
    this.status,
    this.minimumSystemRequirements = const {},
    this.screenshots = const [],
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    final screenshots = <String>[];
    final rawScreenshots = json['screenshots'];
    if (rawScreenshots is List) {
      for (final item in rawScreenshots) {
        String? url;
        if (item is Map) {
          url = item['image']?.toString();
        } else if (item is String) {
          url = item;
        }
        if (url != null && (url.startsWith('https://') || url.startsWith('http://'))) {
          screenshots.add(url);
        }
      }
    }

    final requirements = <String, String>{};
    final rawRequirements = json['minimum_system_requirements'];
    if (rawRequirements is Map) {
      for (final entry in rawRequirements.entries) {
        final value = entry.value;
        if (value != null && value.toString().trim().isNotEmpty) {
          requirements[entry.key.toString()] = value.toString();
        }
      }
    }

    return Game(
      id: _toInt(json['id']),
      title: _string(json['title']),
      thumbnail: _string(json['thumbnail']),
      genre: _string(json['genre'], fallback: '-'),
      platform: _string(json['platform'], fallback: '-'),
      shortDescription: _string(json['short_description']),
      gameUrl: _string(json['game_url']),
      profileUrl: _string(json['freetogame_profile_url']),
      publisher: _string(json['publisher'], fallback: '-'),
      developer: _string(json['developer'], fallback: '-'),
      releaseDate: _string(json['release_date'], fallback: '-'),
      description: _nullableString(json['description']),
      status: _nullableString(json['status']),
      minimumSystemRequirements: requirements,
      screenshots: screenshots,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  static String? _nullableString(dynamic value) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? null : result;
  }

  /// Gabungkan data ringkas /games dengan data lengkap /game?id=.
  /// Field dasar tetap diambil dari /games bila tidak tersedia pada detail.
  Game mergeDetails(Game detail) {
    return Game(
      id: id,
      title: _prefer(detail.title, title),
      thumbnail: _prefer(detail.thumbnail, thumbnail),
      genre: _prefer(detail.genre, genre),
      platform: _prefer(detail.platform, platform),
      shortDescription: _prefer(detail.shortDescription, shortDescription),
      gameUrl: _prefer(detail.gameUrl, gameUrl),
      profileUrl: _prefer(detail.profileUrl, profileUrl),
      publisher: _prefer(detail.publisher, publisher),
      developer: _prefer(detail.developer, developer),
      releaseDate: _prefer(detail.releaseDate, releaseDate),
      description: _preferNullable(detail.description, description),
      status: _preferNullable(detail.status, status),
      minimumSystemRequirements: detail.minimumSystemRequirements.isNotEmpty
          ? detail.minimumSystemRequirements
          : minimumSystemRequirements,
      screenshots: detail.screenshots.isNotEmpty ? detail.screenshots : screenshots,
    );
  }

  static String _prefer(String preferred, String fallback) {
    return preferred.trim().isNotEmpty && preferred != '-' ? preferred : fallback;
  }

  static String? _preferNullable(String? preferred, String? fallback) {
    return preferred != null && preferred.trim().isNotEmpty ? preferred : fallback;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thumbnail': thumbnail,
        'genre': genre,
        'platform': platform,
        'short_description': shortDescription,
        'game_url': gameUrl,
        'freetogame_profile_url': profileUrl,
        'publisher': publisher,
        'developer': developer,
        'release_date': releaseDate,
        'description': description,
        'status': status,
        'minimum_system_requirements': minimumSystemRequirements,
        'screenshots': screenshots.map((url) => {'image': url}).toList(),
      };
}
