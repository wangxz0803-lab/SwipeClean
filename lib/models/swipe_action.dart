import '../models/photo_item.dart';

enum SwipeDirection { left, right, up }

enum ActionType { delete, keep, favorite }

ActionType actionFromDirection(SwipeDirection dir) {
  switch (dir) {
    case SwipeDirection.left:
      return ActionType.delete;
    case SwipeDirection.right:
      return ActionType.keep;
    case SwipeDirection.up:
      return ActionType.favorite;
  }
}

class SwipeRecord {
  final PhotoItem photo;
  final ActionType action;
  final DateTime timestamp;
  final int fileSize;

  SwipeRecord({
    required this.photo,
    required this.action,
    this.fileSize = 0,
  }) : timestamp = DateTime.now();
}
