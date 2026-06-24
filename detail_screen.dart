import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/dhikr_item.dart';
import '../models/category.dart';
import '../providers/app_state.dart';
import '../services/utils.dart';
import '../theme/app_colors.dart';
import '../widgets/tasbih_ring.dart';
import '../widgets/diamond_rule.dart';
import '../widgets/pill.dart';

class DetailScreen extends StatefulWidget {
  final DhikrItem item;
  final bool isPending;
  final void Function(DhikrItem item) onVoice;

  const DetailScreen({
    super.key,
    required this.item,
    required this.isPending,
    required this.onVoice,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late DhikrItem _item;
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _player.onPlayerComplete.listen((_) => setState(() => _playing = false));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  int _getCount(AppState state) {
    if (_item.isBuiltin) return state.builtinCount(_item.id);
    final communityMatch = state.mine.where((x) => x.id == _item.id);
    if (communityMatch.isNotEmpty) return communityMatch.first.count;
    return _item.count;
  }

  void _bump(AppState state) {
    if (_item.isBuiltin) {
      state.bumpBuiltin(_item.id);
    } else {
      final isMine = state.mine.any((x) => x.id == _item.id);
      if (isMine) {
        state.updateMineCount(_item.id, (c) => c + 1);
      } else {
        state.firestore.incrementCount(_item.id, isPending: widget.isPending);
        state.bumpDailyOnly();
        setState(() => _item = _item.copyWith(count: _item.count + 1));
      }
    }
  }

  void _reset(AppState state) {
    if (_item.isBuiltin) {
      state.resetBuiltin(_item.id);
    } else {
      final isMine = state.mine.any((x) => x.id == _item.id);
      if (isMine) {
        state.updateMineCount(_item.id, (_) => 0);
      } else {
        state.firestore.resetCount(_item.id, isPending: widget.isPending);
        setState(() => _item = _item.copyWith(count: 0));
      }
    }
  }

  String _shareText() {
    final text = _item.type == 'text' ? _item.text.substring(0, _item.text.length.clamp(0, 140)) : '';
    final code = _item.shareCode != null ? 'أكمل العدّاد معي — ابحث عن الكود: ${_item.shareCode}' : '';
    return '${_item.title}\n$text\n$code'.trim();
  }

  void _copyText() {
    final t = _item.type == 'text' ? _item.text : _shareText();
    Clipboard.setData(ClipboardData(text: t));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ النص'), duration: Duration(seconds: 2)),
    );
  }

  void _copyCode() {
    if (_item.shareCode == null) return;
    Clipboard.setData(ClipboardData(text: _item.shareCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الكود'), duration: Duration(seconds: 2)),
    );
  }

  void _whatsApp() {
    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_shareText())}');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _nativeShare() => Share.share(_shareText(), subject: _item.title);

  void _publish(AppState state) async {
    final code = generateShareCode();
    final published = DhikrItem(
      id: _item.isBuiltin ? generateId() : _item.id,
      category: _item.category,
      type: _item.type,
      title: _item.title,
      source: _item.source,
      target: _item.target,
      text: _item.text,
      mediaUrl: _item.mediaUrl,
      caption: _item.caption,
      fileName: _item.fileName,
      count: _getCount(state),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      shareCode: code,
    );
    if (!_item.isBuiltin) await state.removeMine(_item.id);
    await state.firestore.submitForReview(published);
    setState(() => _item = published);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الإرسال — شارك الكود والآن ينتظر موافقة المشرف')),
      );
    }
  }

  Future<void> _toggleAudio() async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
    } else {
      await _player.play(UrlSource(_item.mediaUrl));
      setState(() => _playing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final meta = findCategory(state.allCategories, _item.category);
    final surface = state.surface;
    final count = _getCount(state);

    return Scaffold(
      backgroundColor: surface.bg,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        leading: const BackButton(color: Color(0xFFF6EFE2)),
        title: Text(_item.title,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 18, color: Color(0xFFF6EFE2))),
        actions: [
          IconButton(
            icon: Icon(
              state.isFavorite(_item.id)
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: AppColors.gold,
            ),
            onPressed: () => state.toggleFavorite(_item.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header band
            Container(
              padding: const EdgeInsets.all(16),
              color: meta.accent.withOpacity(0.08),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: meta.accent.withOpacity(0.18),
                    child: Icon(meta.icon, color: meta.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(meta.label, style: TextStyle(color: meta.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                    if (_item.source.isNotEmpty)
                      Text(_item.source, style: TextStyle(color: surface.muted, fontSize: 12)),
                  ]),
                  if (widget.isPending) ...[
                    const Spacer(),
                    Pill(text: '⏳ بانتظار المراجعة', accent: const Color(0xFFB5651D)),
                  ],
                ],
              ),
            ),
            DiamondRule(accent: meta.accent),
            // body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildBody(surface),
            ),
            const SizedBox(height: 16),
            // big tasbih
            Center(
              child: TasbihRing(
                count: count,
                accent: meta.accent,
                size: 220,
                label: 'اضغط على الحلقة للتسبيح',
                onTap: () => _bump(state),
                onReset: () => _reset(state),
              ),
            ),
            const SizedBox(height: 16),
            DiamondRule(accent: meta.accent),
            // action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _actionChip(Icons.mic_rounded, 'ذكر بصوتك', AppColors.voiceRed,
                          () { widget.onVoice(_item); Navigator.pop(context); }),
                      _actionChip(Icons.copy_rounded, 'نسخ', meta.accent, _copyText),
                      _actionChip(Icons.share_rounded, 'مشاركة', meta.accent, _nativeShare),
                      _actionChip(Icons.chat_rounded, 'واتساب', const Color(0xFF1F6F5C), _whatsApp),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_item.shareCode != null) _codePanel(meta.accent, surface) else _publishBtn(state, meta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppSurface surface) {
    switch (_item.type) {
      case 'text':
        return SelectableText(
          _item.text,
          style: TextStyle(fontFamily: 'Amiri', fontSize: 21, color: surface.text, height: 2.15),
          textDirection: TextDirection.rtl,
        );
      case 'image':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(_item.mediaUrl, fit: BoxFit.cover, width: double.infinity),
          ),
          if (_item.caption.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_item.caption,
                style: TextStyle(color: surface.muted, fontSize: 14, fontStyle: FontStyle.italic)),
          ],
        ]);
      case 'audio':
        return Container(
          decoration: BoxDecoration(color: surface.card, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            IconButton(
              icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: AppColors.ink, size: 32),
              onPressed: _toggleAudio,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(_item.title, style: TextStyle(color: surface.text, fontSize: 15))),
          ]),
        );
      default: // file
        return GestureDetector(
          onTap: () => launchUrl(Uri.parse(_item.mediaUrl)),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: surface.card, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.attach_file_rounded, color: AppColors.ink),
              const SizedBox(width: 10),
              Expanded(child: Text(_item.fileName.isNotEmpty ? _item.fileName : 'فتح الملف',
                  style: TextStyle(color: surface.text))),
              Icon(Icons.open_in_new_rounded, size: 18, color: surface.muted),
            ]),
          ),
        );
    }
  }

  Widget _actionChip(IconData icon, String label, Color color, VoidCallback onTap) => ActionChip(
        avatar: Icon(icon, size: 15, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: color.withOpacity(0.1),
        side: BorderSide.none,
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      );

  Widget _codePanel(Color accent, AppSurface surface) => Container(
        decoration: BoxDecoration(
          color: surface.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('كود المشاركة', style: TextStyle(color: accent, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  _item.shareCode!,
                  style: TextStyle(
                    color: surface.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    fontFamily: 'monospace',
                  ),
                ),
              ]),
            ),
            IconButton(
              onPressed: _copyCode,
              icon: Icon(Icons.copy_rounded, color: accent),
              tooltip: 'نسخ الكود',
            ),
          ],
        ),
      );

  Widget _publishBtn(AppState state, DhikrCategory meta) => ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.link_rounded, size: 18),
        label: const Text('انشر هذا الذكر (يحتاج موافقة المشرف)', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _publish(state),
      );
}
