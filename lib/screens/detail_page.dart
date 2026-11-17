import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/game.dart';
import '../services/api_service.dart';
import '../services/library_service.dart';
import '../widgets/game_network_image.dart';

class DetailPage extends StatefulWidget {
  final Game initialGame;
  final bool fetchRemoteDetails;

  const DetailPage({
    super.key,
    required this.initialGame,
    this.fetchRemoteDetails = true,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Game _game;
  bool _loadingDetails = false;
  String? _detailError;

  @override
  void initState() {
    super.initState();
    _game = widget.initialGame;
    if (widget.fetchRemoteDetails) {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loadingDetails = true;
      _detailError = null;
    });
    try {
      final detail = await ApiService.fetchMergedDetail(widget.initialGame);
      if (!mounted) return;
      setState(() {
        _game = detail;
        _loadingDetails = false;
      });
      await LibraryService.updateIfOwned(detail);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        // Data dari /games tetap ditampilkan meskipun endpoint detail gagal.
        _loadingDetails = false;
        _detailError =
            'Data tambahan belum bisa dimuat. Informasi dasar tetap ditampilkan.';
      });
    }
  }

  Future<void> _addToLibrary() async {
    await LibraryService.add(_game);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${_game.title} ditambahkan ke Library')),
      );
  }

  Future<void> _removeFromLibrary() async {
    await LibraryService.remove(_game.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${_game.title} dihapus dari Library')),
      );
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan tidak valid.')),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan eksternal.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka browser untuk tautan ini.')),
      );
    }
  }

  void _showScreenshotPreview(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: GameNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                iconSize: 48,
              ),
            ),
            IconButton(
              tooltip: 'Tutup pratinjau',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroImage = _game.thumbnail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Game'),
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_loadingDetails)
            const Padding(
              padding: EdgeInsets.only(right: 18),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          // Thumbnail dari endpoint /games langsung digunakan sebagai hero image.
          AspectRatio(
            aspectRatio: 16 / 9,
            child: GameNetworkImage(
              imageUrl: heroImage,
              width: double.infinity,
              fit: BoxFit.cover,
              iconSize: 58,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_detailError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _detailError!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadDetails,
                          child: const Text('Ulangi'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tag(_game.genre),
                    _Tag(_game.platform),
                    if (_game.status?.isNotEmpty == true) _Tag(_game.status!),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _game.title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_game.shortDescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _game.shortDescription,
                    style: TextStyle(color: Colors.grey.shade400, height: 1.4),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 18,
                  runSpacing: 14,
                  children: [
                    _Info(label: 'Release Date', value: _game.releaseDate),
                    _Info(label: 'Publisher', value: _game.publisher),
                    _Info(label: 'Developer', value: _game.developer),
                  ],
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<Box<String>>(
                  valueListenable: LibraryService.listenable(),
                  builder: (context, box, _) {
                    final owned = LibraryService.containsInBox(box, _game.id);
                    if (!owned) {
                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const Key('add_to_library_button'),
                          onPressed: _addToLibrary,
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Add to Library',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F7CFF),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.greenAccent,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'In Library',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          key: const Key('remove_from_library_button'),
                          onPressed: _removeFromLibrary,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            'Remove from Library',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.redAccent.withValues(alpha: 0.6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (_game.gameUrl.isNotEmpty || _game.profileUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (_game.gameUrl.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _openUrl(_game.gameUrl),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Buka Halaman Resmi'),
                        ),
                      if (_game.profileUrl.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _openUrl(_game.profileUrl),
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('Profil FreeToGame'),
                        ),
                    ],
                  ),
                ],
                if (_game.screenshots.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  const Text(
                    'Screenshots',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _game.screenshots.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, index) {
                        final url = _game.screenshots[index];
                        return GestureDetector(
                          onTap: () => _showScreenshotPreview(url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: GameNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                iconSize: 30,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else if (_loadingDetails) ...[
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    'Mengambil screenshots game...',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Text(
                    'Screenshot tidak disediakan oleh API untuk game ini.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 26),
                const Text(
                  'Deskripsi Game',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  (_game.description?.trim().isNotEmpty ?? false)
                      ? _game.description!
                      : (_game.shortDescription.isNotEmpty
                          ? _game.shortDescription
                          : 'Deskripsi belum tersedia.'),
                  style: TextStyle(color: Colors.grey.shade300, height: 1.5),
                ),
                if (_game.minimumSystemRequirements.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  const Text(
                    'Minimum System Requirements',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2030),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: _game.minimumSystemRequirements.entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      _label(entry.key),
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Center(
                  child: InkWell(
                    onTap: () => _openUrl('https://www.freetogame.com'),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Game data provided by FreeToGame.com',
                        style: TextStyle(
                          color: Color(0xFF9DB4FF),
                          decoration: TextDecoration.underline,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _label(String key) {
    switch (key.toLowerCase()) {
      case 'os':
        return 'OS';
      case 'processor':
        return 'Processor';
      case 'memory':
        return 'Memory';
      case 'graphics':
        return 'Graphics';
      case 'storage':
        return 'Storage';
      default:
        return key;
    }
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF293653),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: const TextStyle(fontSize: 11)),
      );
}

class _Info extends StatelessWidget {
  final String label;
  final String value;
  const _Info({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 95,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}
