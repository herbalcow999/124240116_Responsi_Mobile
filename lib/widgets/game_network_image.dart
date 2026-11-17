import 'package:flutter/material.dart';

/// Gambar game dengan loading, fallback, dan dukungan fallback HTML untuk web.
class GameNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double iconSize;

  const GameNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    if (url.isEmpty) return _fallback();

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      // Berguna untuk Flutter Web/Chrome ketika request gambar lintas-domain
      // gagal melalui ImageProvider biasa karena kebijakan CORS.
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: const Color(0xFF1B2030),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() => Container(
        width: width,
        height: height,
        color: const Color(0xFF1B2030),
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined,
            size: iconSize, color: Colors.white54),
      );
}
