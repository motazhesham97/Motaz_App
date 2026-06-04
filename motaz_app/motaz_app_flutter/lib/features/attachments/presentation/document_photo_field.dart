import 'dart:io';

import 'package:flutter/material.dart';

class DocumentPhotoField extends StatelessWidget {
  const DocumentPhotoField({
    super.key,
    required this.label,
    required this.localPath,
    required this.onCapture,
    required this.onRemove,
  });

  final String label;
  final String? localPath;
  final VoidCallback onCapture;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final path = localPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (path == null)
          OutlinedButton.icon(
            onPressed: onCapture,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(label),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 420),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return ColoredBox(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Center(child: Text('تعذر عرض الصورة')),
                      );
                    },
                  ),
                ),
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: IconButton.filledTonal(
                    tooltip: 'إزالة الصورة',
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
