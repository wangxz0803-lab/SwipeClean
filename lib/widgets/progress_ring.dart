import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProgressRing extends StatefulWidget {
  final double progress;
  final int reviewed;
  final int total;
  final double size;
  final double strokeWidth;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.reviewed,
    required this.total,
    this.size = 80,
    this.strokeWidth = 6,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _oldProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnimation =
        Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _oldProgress = oldWidget.progress;
      _progressAnimation =
          Tween<double>(begin: _oldProgress, end: widget.progress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final animatedProgress = _progressAnimation.value;
        final percent = (animatedProgress * 100).round();

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: animatedProgress,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: widget.size * 0.2,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${widget.reviewed}/${widget.total}',
                    style: TextStyle(
                      fontSize: widget.size * 0.12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    // Progress ring with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * pi * progress;

    // Color interpolation from primary to success
    final progressColor =
        Color.lerp(AppTheme.primary, AppTheme.success, progress) ??
            AppTheme.primary;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + sweepAngle,
        colors: [AppTheme.primary, progressColor],
        stops: const [0.0, 1.0],
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

