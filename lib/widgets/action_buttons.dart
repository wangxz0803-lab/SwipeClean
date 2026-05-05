import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback? onUndo;
  final VoidCallback onDelete;
  final VoidCallback onKeep;
  final VoidCallback onFavorite;
  final bool canUndo;
  final int undoCount;

  const ActionButtons({
    super.key,
    this.onUndo,
    required this.onDelete,
    required this.onKeep,
    required this.onFavorite,
    this.canUndo = false,
    this.undoCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Undo button (small)
          _ActionButton(
            icon: Icons.undo_rounded,
            color: AppTheme.textSecondary,
            size: 44,
            iconSize: 22,
            onTap: canUndo ? onUndo : null,
            enabled: canUndo,
            badge: canUndo && undoCount > 0 ? undoCount : null,
          ),
          // Delete button
          _ActionButton(
            icon: Icons.close_rounded,
            color: AppTheme.danger,
            size: 58,
            iconSize: 30,
            onTap: onDelete,
          ),
          // Favorite button
          _ActionButton(
            icon: Icons.star_rounded,
            color: AppTheme.favorite,
            size: 58,
            iconSize: 30,
            onTap: onFavorite,
          ),
          // Keep button
          _ActionButton(
            icon: Icons.check_rounded,
            color: AppTheme.success,
            size: 58,
            iconSize: 30,
            onTap: onKeep,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final VoidCallback? onTap;
  final bool enabled;
  final int? badge;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    this.onTap,
    this.enabled = true,
    this.badge,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.enabled ? widget.color : widget.color.withValues(alpha: 0.3);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: effectiveColor.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: effectiveColor.withValues(
                        alpha: widget.enabled ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: effectiveColor,
                size: widget.iconSize,
              ),
            ),
            if (widget.badge != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.badge}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

