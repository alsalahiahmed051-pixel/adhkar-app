import 'dart:math';
import 'package:flutter/material.dart';

class TasbihRing extends StatefulWidget {
  final int count;
  final Color accent;
  final double size;
  final String? label;
  final VoidCallback onTap;
  final VoidCallback? onReset;

  const TasbihRing({
    super.key,
    required this.count,
    required this.accent,
    this.size = 64,
    this.label,
    required this.onTap,
    this.onReset,
  });

  @override
  State<TasbihRing> createState() => _TasbihRingState();
}

class _TasbihRingState extends State<TasbihRing> with TickerProviderStateMixin {
  late final AnimationController _bumpCtrl;
  late final AnimationController _pingCtrl;

  @override
  void initState() {
    super.initState();
    _bumpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _pingCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _bumpCtrl.dispose();
    _pingCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bumpCtrl.forward(from: 0).then((_) => _bumpCtrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final showTassel = widget.size >= 140;
    final extraHeight = showTassel ? widget.size * 0.22 : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: _bumpCtrl,
            builder: (context, child) {
              final scale = 1.0 + (_bumpCtrl.value * 0.08);
              return Transform.scale(scale: scale, child: child);
            },
            child: SizedBox(
              width: widget.size,
              height: widget.size + extraHeight,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (widget.count == 0)
                    AnimatedBuilder(
                      animation: _pingCtrl,
                      builder: (context, _) {
                        final t = _pingCtrl.value;
                        return Opacity(
                          opacity: (1 - t) * 0.35,
                          child: Transform.scale(
                            scale: 0.9 + t * 0.4,
                            child: Container(
                              width: widget.size,
                              height: widget.size,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.accent),
                            ),
                          ),
                        );
                      },
                    ),
                  CustomPaint(
                    size: Size(widget.size, widget.size + extraHeight),
                    painter: _BeadRingPainter(
                      count: widget.count,
                      accent: widget.accent,
                      showTassel: showTassel,
                    ),
                  ),
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: Center(
                      child: Text(
                        '${widget.count}',
                        style: TextStyle(
                          color: widget.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: max(13.0, widget.size * 0.26),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 6),
          Text(widget.label!, style: TextStyle(color: widget.accent, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
        if (widget.onReset != null && widget.count > 0) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: widget.onReset,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 13, color: widget.accent.withOpacity(0.7)),
                const SizedBox(width: 3),
                Text('إعادة', style: TextStyle(color: widget.accent.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BeadRingPainter extends CustomPainter {
  final int count;
  final Color accent;
  final bool showTassel;
  static const beads = 33;

  _BeadRingPainter({required this.count, required this.accent, required this.showTassel});

  @override
  void paint(Canvas canvas, Size size) {
    final ringSize = size.width;
    final c = Offset(ringSize / 2, ringSize / 2);
    final r = ringSize * 0.42;
    final filled = (count % beads == 0 && count > 0) ? beads : count % beads;

    final guide = Paint()
      ..color = accent.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.6, ringSize * 0.006);
    canvas.drawCircle(c, r, guide);

    for (int i = 0; i < beads; i++) {
      final angle = (i * (360 / beads) - 90) * pi / 180;
      final pos = Offset(c.dx + r * cos(angle), c.dy + r * sin(angle));
      final isFilled = i < filled;
      final isImam = i == 0;
      final radius = isImam ? max(2.4, ringSize * 0.044) : max(1.6, ringSize * 0.028);

      if (isFilled || isImam) {
        final paint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [Colors.white.withOpacity(0.9), accent],
            stops: const [0.0, 0.55],
          ).createShader(Rect.fromCircle(center: pos, radius: radius));
        canvas.drawCircle(pos, radius, paint);
        if (isImam && !isFilled) {
          canvas.drawCircle(pos, radius, Paint()..color = accent.withOpacity(0.55));
        }
      } else {
        final outline = Paint()
          ..color = accent.withOpacity(0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(pos, radius, outline);
      }
    }

    if (showTassel) {
      final tasselPaint = Paint()
        ..color = accent.withOpacity(0.85)
        ..strokeWidth = ringSize * 0.012
        ..strokeCap = StrokeCap.round;
      final topY = c.dy + r - 1;
      final knotY = c.dy + r + ringSize * 0.15;
      canvas.drawLine(Offset(c.dx, topY), Offset(c.dx, c.dy + r + ringSize * 0.12), tasselPaint);
      canvas.drawCircle(Offset(c.dx, knotY), ringSize * 0.03, Paint()..color = accent);
      for (final dx in [-6.0, 0.0, 6.0]) {
        canvas.drawLine(
          Offset(c.dx + dx * 0.7, c.dy + r + ringSize * 0.17),
          Offset(c.dx + dx, c.dy + r + ringSize * 0.25),
          tasselPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BeadRingPainter oldDelegate) =>
      oldDelegate.count != count || oldDelegate.accent != accent;
}
