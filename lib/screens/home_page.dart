import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/api_service.dart';
import '../widgets/game_tile.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  List<Game> _games = [];
  bool _loading = true;
  String? _errorMessage;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await ApiService.fetchGames();
      if (!mounted) return;
      setState(() {
        _games = data;
        _loading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      if (isRefresh && _games.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui daftar game: $error'),
          ),
        );
      } else {
        setState(() {
          _loading = false;
          _errorMessage = error.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Game> get _filteredGames {
    if (_query.isEmpty) return _games;
    return _games.where((g) {
      return g.title.toLowerCase().contains(_query) ||
          g.genre.toLowerCase().contains(_query) ||
          g.platform.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleGames = _filteredGames;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Browse Games',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh daftar game',
            icon: const Icon(Icons.refresh),
            onPressed: _loading
                ? null
                : () => _loadGames(isRefresh: _games.isNotEmpty),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari judul, genre, atau platform...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: _buildBody(visibleGames),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Game> visibleGames) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorView(
        message: _errorMessage!,
        onRetry: () => _loadGames(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadGames(isRefresh: true),
      child: visibleGames.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'Game tidak ditemukan.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              itemCount: visibleGames.length,
              itemBuilder: (context, index) {
                final game = visibleGames[index];
                return GameTile(
                  game: game,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailPage(initialGame: game),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.white70),
              const SizedBox(height: 12),
              const Text(
                'Data game gagal dimuat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
}
