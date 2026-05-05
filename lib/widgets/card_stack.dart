import 'package:flutter/material.dart';
import '../models/photo_item.dart';
import '../models/swipe_action.dart';
import '../theme/app_theme.dart';
import 'swipe_card.dart';

class CardStack extends StatelessWidget {
  final List<PhotoItem> photos;
  final int currentIndex;
  final Function(SwipeDirection) onSwipe;

  const CardStack({
    super.key,
    required this.photos,
    required this.currentIndex,
    required this.onSwipe,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty || currentIndex >= photos.length) {
      return _buildEmptyState();
    }

    final visibleCards = <Widget>[];
    final cardsToShow = (photos.length - currentIndex).clamp(0, 3);

    for (int i = cardsToShow - 1; i >= 0; i--) {
      final photoIndex = currentIndex + i;
      if (photoIndex >= photos.length) continue;

      final photo = photos[photoIndex];
      final isFront = i == 0;

      double scale;
      double offsetY;

      switch (i) {
        case 0:
          scale = 1.0;
          offsetY = 0;
          break;
        case 1:
          scale = 0.95;
          offsetY = 8;
          break;
        default:
          scale = 0.90;
          offsetY = 16;
          break;
      }

      visibleCards.add(
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: Transform.scale(
              scale: isFront ? 1.0 : scale,
              child: SwipeCard(
                key: ValueKey(photo.id),
                photo: photo,
                isFrontCard: isFront,
                onSwipeLeft: isFront
                    ? () => onSwipe(SwipeDirection.left)
                    : null,
                onSwipeRight: isFront
                    ? () => onSwipe(SwipeDirection.right)
                    : null,
                onSwipeUp: isFront
                    ? () => onSwipe(SwipeDirection.up)
                    : null,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: visibleCards,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 80,
            color: AppTheme.success.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            '全部清理完毕！',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '所有照片都已审阅',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
