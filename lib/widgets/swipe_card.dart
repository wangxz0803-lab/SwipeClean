import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/photo_item.dart';
import '../theme/app_theme.dart';

class SwipeCard extends StatefulWidget {
  final PhotoItem photo;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final bool isFrontCard;

  const SwipeCard({
    super.key,
    required this.photo,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.isFrontCard = true,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;

  late AnimationController _animController;
  Animation<Offset>? _posAnimation;

  static const double _swipeThreshold = 100.0;
  static const double _maxRotation = 0.3;
  static const double _flyOffDistance = 600.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.addListener(_onAnimate);
  }

  @override
  void dispose() {
    _animController.removeListener(_onAnimate);
    _animController.dispose();
    super.dispose();
  }

  void _onAnimate() {
    if (_posAnimation != null) {
      setState(() {
        _position = _posAnimation!.value;
      });
    }
  }

  double get _rotationAngle {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth == 0) return 0;
    return _position.dx / screenWidth * _maxRotation;
  }

  double _overlayOpacity(double displacement) {
    return (displacement.abs() / _swipeThreshold).clamp(0.0, 1.0);
  }

  _SwipeIntent get _currentIntent {
    final dx = _position.dx.abs();
    final dy = -_position.dy; // negative Y = swiping up

    if (dy > dx && dy > _swipeThreshold * 0.5) {
      return _SwipeIntent.up;
    } else if (_position.dx > _swipeThreshold * 0.5) {
      return _SwipeIntent.right;
    } else if (_position.dx < -_swipeThreshold * 0.5) {
      return _SwipeIntent.left;
    }
    return _SwipeIntent.none;
  }

  void _onPanStart(DragStartDetails details) {
    _animController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final dx = _position.dx;
    final dy = _position.dy;
    final velocity = details.velocity.pixelsPerSecond;

    // Check if swipe threshold met
    bool swipedLeft = dx < -_swipeThreshold || velocity.dx < -800;
    bool swipedRight = dx > _swipeThreshold || velocity.dx > 800;
    bool swipedUp = dy < -_swipeThreshold || velocity.dy < -800;

    // Prioritize up swipe if diagonal
    if (swipedUp && -dy > dx.abs()) {
      _flyOff(Offset(dx * 0.5, -_flyOffDistance), widget.onSwipeUp);
    } else if (swipedLeft) {
      _flyOff(Offset(-_flyOffDistance, dy * 0.5), widget.onSwipeLeft);
    } else if (swipedRight) {
      _flyOff(Offset(_flyOffDistance, dy * 0.5), widget.onSwipeRight);
    } else {
      _snapBack();
    }
  }

  void _flyOff(Offset target, VoidCallback? callback) {
    _posAnimation = Tween<Offset>(
      begin: _position,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInQuad,
    ));

    _animController.forward(from: 0).then((_) {
      callback?.call();
      // Reset position after callback
      if (mounted) {
        setState(() {
          _position = Offset.zero;
        });
      }
    });
  }

  void _snapBack() {
    _posAnimation = Tween<Offset>(
      begin: _position,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    ));

    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final double scale = widget.isFrontCard ? 1.0 : 0.95;

    Widget card = Transform.scale(
      scale: scale,
      child: Transform.translate(
        offset: widget.isFrontCard ? _position : Offset.zero,
        child: Transform.rotate(
          angle: widget.isFrontCard ? _rotationAngle : 0,
          alignment: Alignment(0, 0.5),
          child: _buildCard(),
        ),
      ),
    );

    if (widget.isFrontCard) {
      card = GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: card,
      );
    }

    return card;
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isFrontCard ? 0.15 : 0.08),
            blurRadius: widget.isFrontCard ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            _buildPhoto(),
            // Swipe direction overlay
            if (widget.isFrontCard) _buildOverlays(),
            // Bottom info bar
            _buildInfoBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    return FutureBuilder<Uint8List?>(
      future: widget.photo.loadThumbnail(size: 800),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: AppTheme.background,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            ),
          );
        }

        if (snapshot.data == null) {
          return Container(
            color: AppTheme.background,
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: AppTheme.textSecondary,
              ),
            ),
          );
        }

        final data = snapshot.data!;
        return Stack(
          fit: StackFit.expand,
          children: [
            // Bottom layer: stretched/cropped background
            Image.memory(
              data,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
            // Middle layer: blur + dark overlay
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(color: const Color(0x40000000)),
              ),
            ),
            // Top layer: full photo without cropping
            Center(
              child: Image.memory(
                data,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverlays() {
    final intent = _currentIntent;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Delete overlay (left)
        _buildDirectionOverlay(
          color: AppTheme.danger,
          icon: Icons.delete_rounded,
          label: '删除',
          opacity: intent == _SwipeIntent.left
              ? _overlayOpacity(_position.dx)
              : (_position.dx < 0 ? _overlayOpacity(_position.dx) : 0),
          alignment: Alignment.center,
        ),
        // Keep overlay (right)
        _buildDirectionOverlay(
          color: AppTheme.success,
          icon: Icons.check_circle_rounded,
          label: '保留',
          opacity: intent == _SwipeIntent.right
              ? _overlayOpacity(_position.dx)
              : (_position.dx > 0 ? _overlayOpacity(_position.dx) : 0),
          alignment: Alignment.center,
        ),
        // Favorite overlay (up)
        _buildDirectionOverlay(
          color: AppTheme.favorite,
          icon: Icons.star_rounded,
          label: '收藏',
          opacity: intent == _SwipeIntent.up
              ? _overlayOpacity(_position.dy)
              : (_position.dy < 0 ? _overlayOpacity(_position.dy) : 0),
          alignment: Alignment.center,
        ),
      ],
    );
  }

  Widget _buildDirectionOverlay({
    required Color color,
    required IconData icon,
    required String label,
    required double opacity,
    required Alignment alignment,
  }) {
    if (opacity <= 0) return const SizedBox.shrink();

    return Opacity(
      opacity: opacity.clamp(0.0, 0.8),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.4),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 64),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      _formatDate(widget.photo.createDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.photo.width} × ${widget.photo.height}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

enum _SwipeIntent { none, left, right, up }
