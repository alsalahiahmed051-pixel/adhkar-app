import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dhikr_item.dart';
import '../models/category.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'tasbih_ring.dart';
import 'pill.dart';

class DhikrCard extends StatelessWidget {
  final DhikrItem item;
  final int count;
  final bool isFav;
  final bool isPending;
  final VoidCallback onTap;
  final VoidCallback onOpen;
  final VoidCallback onToggleFav;
  final VoidCallback onVoice;

  const DhikrCard({
    super.key,
    required this.item,
    required this.count,
    required this.isFav,
    required this.isPending,
    required this.onTap,
    required this.onOpen,
    required this.onToggleFav,
    required this.onVoice,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final meta = findCategory(state.allCategories, item.category);
    final surface = state.surface;

    return Card(
      elevation: 0,
      color: surface.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: meta.accent.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // left accent bar (RTL — appears on the right visually)
            Positioned.directional(
              textDirection: TextDirection.rtl,
              start: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: ColoredBox(color: meta.accent),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onOpen,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: meta.accent.withOpacity(0.12),
                              child: Icon(meta.icon, size: 15, color: meta.accent),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: surface.text,
                                  fontFamily: 'Amiri',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            _iconBtn(Icons.mic_rounded, AppColors.voiceRed, onVoice),
                            _iconBtn(
                              isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              AppColors.gold,
                              onToggleFav,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _ItemPreview(item: item, surface: surface),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (item.target.isNotEmpty) Pill(text: 'السُّنّة: ${item.target}', accent: meta.accent),
                            if (item.source.isNotEmpty) Pill(text: item.source, accent: meta.accent),
                            if (item.shareCode != null) Pill(text: 'مُشارَك · ${item.shareCode}', accent: meta.accent),
                            if (isPending) Pill(text: '⏳ بانتظار المراجعة', accent: const Color(0xFFB5651D)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: meta.accent.withOpacity(0.13)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(meta.label,
                          style: TextStyle(color: meta.accent, fontSize: 11, fontWeight: FontWeight.w500)),
                      TasbihRing(count: count, accent: meta.accent, size: 56, onTap: onTap),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onPressed) => IconButton(
        icon: Icon(icon, size: 20, color: color),
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(),
        onPressed: onPressed,
        tooltip: icon == Icons.mic_rounded ? 'ذكر بصوتك' : 'مفضلة',
      );
}

class _ItemPreview extends StatelessWidget {
  final DhikrItem item;
  final AppSurface surface;
  const _ItemPreview({required this.item, required this.surface});

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case 'text':
        final preview = item.text.length > 140 ? '${item.text.substring(0, 140)}…' : item.text;
        return Text(preview,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'Amiri', fontSize: 17, color: surface.text, height: 2.1));
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(item.mediaUrl, height: 110, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox()),
        );
      case 'audio':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: surface.cardAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.music_note_rounded, size: 18),
            const SizedBox(width: 8),
            Text(item.title, style: TextStyle(fontSize: 13, color: surface.muted)),
          ]),
        );
      default:
        return Row(children: [
          const Icon(Icons.attach_file_rounded, size: 18),
          const SizedBox(width: 6),
          Text(item.fileName.isNotEmpty ? item.fileName : item.title,
              style: TextStyle(fontSize: 13, color: surface.muted)),
        ]);
    }
  }
}
