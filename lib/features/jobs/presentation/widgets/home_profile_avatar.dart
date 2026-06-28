import 'package:flutter/material.dart';
import 'package:hireasy_mobile/core/api/api_endpoints.dart';

class HomeProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;
  final String fallbackText;
  final double radius;

  const HomeProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.fallbackText,
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final cleanImageUrl = imageUrl?.trim() ?? '';
    return Container(
      width: radius * 2,
      height: radius * 2,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white24,
        shape: BoxShape.circle,
      ),
      child: cleanImageUrl.isEmpty
          ? _fallback()
          : Image.network(
              _resolveImageUrl(cleanImageUrl),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            ),
    );
  }

  Widget _fallback() {
    final cleanFallbackText = fallbackText.trim();
    return Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Center(
        child: Text(
          cleanFallbackText.isEmpty ? '?' : cleanFallbackText[0].toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.72,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  String _resolveImageUrl(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    if (uri != null && uri.hasScheme) return imageUrl;

    final baseUri = Uri.parse(ApiEndpoints.baseUrl);
    final origin = '${baseUri.scheme}://${baseUri.authority}';
    final cleanImageUrl = imageUrl.replaceAll('\\', '/');
    if (cleanImageUrl.startsWith('/')) return '$origin$cleanImageUrl';
    return '$origin/$cleanImageUrl';
  }
}
