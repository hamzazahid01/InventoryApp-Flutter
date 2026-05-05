import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'product_thumb_image.dart';

/// Small thumbnail for grid/list; shows [imageUrl] or a placeholder icon.
class ProductThumb extends StatelessWidget {
  const ProductThumb({
    super.key,
    required this.imageUrl,
    this.localImagePath,
    this.size = 48,
  });

  final String? imageUrl;
  final String? localImagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    final url = imageUrl?.trim();
    final local = localImagePath?.trim();

    // Prefer remote if it looks valid.
    if (url == null ||
        url.isEmpty ||
        !(url.startsWith('http://') || url.startsWith('https://'))) {
      // Fallback to local file path (mobile/desktop only).
      if (!kIsWeb && local != null && local.isNotEmpty) {
        return ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            width: size,
            height: size,
            child: buildLocalThumbImage(
              path: local,
              size: size,
              onError: _placeholderIcon(context, size),
            ),
          ),
        );
      }
      return ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.inventory_2_outlined,
              size: size * 0.45,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          // Avoid decoding huge thumbnails in lists (reduces OOM / decode failures).
          filterQuality: FilterQuality.medium,
          errorBuilder: (ctx, error, stack) => SizedBox.expand(
            child: Icon(
              Icons.broken_image_outlined,
              size: size * 0.45,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _placeholderIcon(BuildContext context, double size) {
    return Icon(
      Icons.inventory_2_outlined,
      size: size * 0.45,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
    );
  }
}
