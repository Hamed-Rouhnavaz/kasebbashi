import 'package:flutter/material.dart';

import 'images.dart';

class ProductThumb extends StatelessWidget {
  final String image;
  final double size;

  const ProductThumb(this.image, {super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (image.isEmpty) {
      child = Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.image_outlined),
      );
    } else {
      child = Image.file(
        ImageStore.fileSync(image),
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}
