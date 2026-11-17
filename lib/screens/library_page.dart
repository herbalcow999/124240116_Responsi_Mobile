import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/library_service.dart';
import '../widgets/game_tile.dart';
import 'detail_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<String>>(
      valueListenable: LibraryService.listenable(),
      builder: (context, box, _) {
        final games = LibraryService.gamesFromBox(box);
        return Scaffold(
          appBar: AppBar(
            title: Text(
              games.isEmpty ? 'My Library' : 'My Library (${games.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: games.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 64,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Library masih kosong',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tambahkan game melalui halaman Detail Game.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return GameTile(
                      game: game,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailPage(initialGame: game),
                        ),
                      ),
                      trailing: IconButton(
                        key: Key('delete_library_game_${game.id}'),
                        tooltip: 'Hapus dari Library',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () async {
                          await LibraryService.remove(game.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${game.title} dihapus dari Library',
                                  ),
                                ),
                              );
                          }
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
