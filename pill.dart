import 'package:flutter/material.dart';

class Pill extends StatelessWidget {
  final String text;
  final Color accent;
  const Pill({super.key, required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Text(text, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
