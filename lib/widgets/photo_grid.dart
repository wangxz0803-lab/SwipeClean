import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/photo_item.dart';
import '../theme/app_theme.dart';

class PhotoGrid extends StatelessWidget {
  final List<PhotoItem> photos;
  final void Function(PhotoItem photo)? onTap;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(String id, bool selected)? onSelectionChanged;

  const PhotoGrid({
    super.key,
    required this.photos,
    this.onTap,
    this.selectionMode = false,
    this.selectedIds = const {},
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            '没有照片',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final isSelected = selectedIds.contains(photo.id);

        return _PhotoGridCell(
          photo: photo,
          isSelected: isSelected,
          selectionMode: selectionMode,
          onTap: () {
            if (selectionMode) {
              onSelectionChanged?.call(photo.id, !isSelected);
            } else {
              onTap?.call(photo);
            }
          },
          onLongPress: () {
            if (!selectionMode) {
              onSelectionChanged?.call(photo.id, true);
            }
          },
        );
      },
    );
  }
}

class _PhotoGridCell extends StatelessWidget {
  final PhotoItem photo;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _PhotoGridCell({
    required this.photo,
    required this.isSelected,
    required this.selectionMode,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          FutureBuilder<Uint8List?>(
            future: photo.loadThumbnail(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  color: AppTheme.background,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.data == null) {
                return Container(
                  color: AppTheme.background,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.textSecondary,
                    size: 24,
                  ),
                );
              }

              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              );
            },
          ),
          // Selection overlay
          if (selectionMode)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppTheme.primary
                      : Colors.black.withValues(alpha: 0.3),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ),
          // Selection highlight
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primary,
                  width: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
