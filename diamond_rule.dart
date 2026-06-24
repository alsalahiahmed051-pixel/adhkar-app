import 'package:flutter/material.dart';

class DiamondRule extends StatelessWidget {
  final Color accent;
  const DiamondRule({super.key, this.accent = const Color(0xFFC9A227)});

  @override
  Widget build(BuildContext context) {
    Widget diamond(double s, double opacity) => Transform.rotate(
          angle: 0.785398,
          child: Container(width: s, height: s, color: accent.withOpacity(opacity)),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 40, height: 1, color: accent.withOpacity(0.33)),
          const SizedBox(width: 8),
          diamond(6, 1),
          const SizedBox(width: 6),
          diamond(4, 0.6),
          const SizedBox(width: 6),
          diamond(6, 1),
          const SizedBox(width: 8),
          Container(width: 40, height: 1, color: accent.withOpacity(0.33)),
        ],
      ),
    );
  }
}
