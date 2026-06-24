import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/dhikr_item.dart';
import '../models/category.dart';
import '../models/seed_data.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/tasbih_ring.dart';

class VoiceScreen extends StatefulWidget {
  final DhikrItem? presetItem;
  const VoiceScreen({super.key, this.presetItem});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

const List<String> _kQuickPhrases = [
  'سبحان الله',
  'الحمد لله',
  'الله أكبر',
  'لا إله إلا الله',
  'أستغفر الله',
  'اللهم صل على محمد',
  'لا حول ولا قوة إلا بالله',
  'بسم الله',
];

class _VoiceScreenState extends State<VoiceScreen> {
  final _stt = SpeechToText();
  bool _sttAvailable = false;
  bool _listening = false;
  bool _speaking = false;
  String _interim = '';
  List<String> _log = [];

  bool _useCustom = false;
  String _customPhrase = 'سبحان الله';
  String? _targetId;
  int _localCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.presetItem != null) {
      _targetId = widget.presetItem!.id;
      _useCustom = false;
    } else {
      _useCustom = true;
    }
    _initStt();
  }

  Future<void> _initStt() async {
    final ok = await _stt.initialize(
      onStatus: (status) {
        if (status == 'listening') setState(() => _speaking = true);
        if (status == 'notListening' || status == 'done') setState(() => _speaking = false);
      },
      onError: (e) {
        setState(() { _listening = false; _speaking = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.errorMsg)));
      },
    );
    setState(() => _sttAvailable = ok);
  }

  void _start(AppState state) async {
    if (!_sttAvailable) return;
    await _stt.listen(
      localeId: 'ar_SA',
      listenMode: ListenMode.confirmation,
      onResult: (r) {
        setState(() => _interim = r.recognizedWords);
        if (r.finalResult && r.recognizedWords.isNotEmpty) {
          _count(state, r.recognizedWords);
          setState(() { _interim = ''; });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
    setState(() => _listening = true);
  }

  void _stop() async {
    await _stt.stop();
    setState(() { _listening = false; _speaking = false; _interim = ''; });
  }

  void _count(AppState state, String phrase) {
    if (_useCustom) {
      setState(() { _localCount++; _log = [phrase, ..._log].take(5).toList(); });
      state.bumpDailyOnly();
    } else {
      final item = _getTargetItem(state);
      if (item == null) return;
      if (item.isBuiltin) {
        state.bumpBuiltin(item.id);
      } else {
        state.firestore.incrementCount(item.id, isPending: false);
        state.bumpDailyOnly();
      }
      setState(() => _log = [phrase, ..._log].take(5).toList());
    }
  }

  void _manualTap(AppState state) {
    if (_useCustom) {
      setState(() => _localCount++);
      state.bumpDailyOnly();
    } else {
      final item = _getTargetItem(state);
      if (item == null) return;
      if (item.isBuiltin) state.bumpBuiltin(item.id);
      else { state.firestore.incrementCount(item.id, isPending: false); state.bumpDailyOnly(); }
    }
  }

  void _reset(AppState state) {
    if (_useCustom) { setState(() => _localCount = 0); return; }
    final item = _getTargetItem(state);
    if (item == null) return;
    if (item.isBuiltin) state.resetBuiltin(item.id);
    else state.firestore.resetCount(item.id, isPending: false);
  }

  DhikrItem? _getTargetItem(AppState state) {
    if (_targetId == null) return null;
    final all = [...kSeedItems, ...state.mine];
    try { return all.firstWhere((i) => i.id == _targetId); } catch (_) { return null; }
  }

  int _getCount(AppState state) {
    if (_useCustom) return _localCount;
    final item = _getTargetItem(state);
    if (item == null) return 0;
    if (item.isBuiltin) return state.builtinCount(item.id);
    return item.count;
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final surface = state.surface;
    final accent = const Color(0xFFC0392B);
    final count = _getCount(state);
    final all = [...kSeedItems, ...state.mine];
    final grouped = state.allCategories.map((c) => MapEntry(c, all.where((i) => i.category == c.id).toList())).where((e) => e.value.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: surface.bg,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        leading: const BackButton(color: Color(0xFFF6EFE2)),
        title: const Text('اذكر الله بصوتك',
            style: TextStyle(fontFamily: 'Amiri', fontSize: 18, color: Color(0xFFF6EFE2))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('اختر الذكر الذي تردّده، اضغط «ابدأ الاستماع»، وسيُحتسب كل ما تقوله تلقائيًا.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: surface.muted, height: 1.7)),
            const SizedBox(height: 16),
            if (!_sttAvailable)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFfdecea), borderRadius: BorderRadius.circular(12)),
                child: const Text('التعرّف الصوتي غير مدعوم على هذا الجهاز / الإعداد.',
                    textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFC0392B))),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _modeChip('ذكر محفوظ', !_useCustom, () => setState(() => _useCustom = false)),
                const SizedBox(width: 10),
                _modeChip('ذكر حر', _useCustom, () => setState(() => _useCustom = true)),
              ],
            ),
            const SizedBox(height: 12),
            if (!_useCustom)
              DropdownButtonFormField<String>(
                value: _targetId,
                decoration: InputDecoration(
                  filled: true, fillColor: surface.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: [
                  for (final g in grouped)
                    for (final i in g.value)
                      DropdownMenuItem(value: i.id, child: Text(i.title, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: _listening ? null : (v) => setState(() => _targetId = v),
              )
            else
              Column(children: [
                TextField(
                  enabled: !_listening,
                  onChanged: (v) => setState(() => _customPhrase = v),
                  controller: TextEditingController.fromValue(
                    TextEditingValue(text: _customPhrase, selection: TextSelection.collapsed(offset: _customPhrase.length))),
                  decoration: InputDecoration(
                    hintText: 'اكتب الذكر...',
                    filled: true, fillColor: surface.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  style: TextStyle(fontFamily: 'Amiri', fontSize: 17, color: surface.text),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: _kQuickPhrases.map((s) => GestureDetector(
                    onTap: _listening ? null : () => setState(() => _customPhrase = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _customPhrase == s ? accent.withOpacity(0.12) : surface.card,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: accent.withOpacity(0.3)),
                      ),
                      child: Text(s, style: TextStyle(fontSize: 13, color: accent)),
                    ),
                  )).toList(),
                ),
              ]),
            const SizedBox(height: 20),
            TasbihRing(
              count: count,
              accent: accent,
              size: 200,
              onTap: () => _manualTap(state),
              onReset: _listening ? null : () => _reset(state),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: _listening
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7A2E2E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('إيقاف الاستماع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: _stop)
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      icon: const Icon(Icons.mic_rounded),
                      label: const Text('ابدأ الاستماع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: _sttAvailable ? () => _start(state) : null),
            ),
            if (_listening) ...[
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _speaking ? const Color(0xFF1F6F5C) : AppColors.gold),
                ),
                const SizedBox(width: 8),
                Text(
                  _interim.isNotEmpty ? '...يسمع: $_interim' : _speaking ? 'يسمعك الآن...' : 'بانتظار صوتك...',
                  style: TextStyle(fontSize: 13, color: surface.muted, fontStyle: FontStyle.italic),
                ),
              ]),
            ],
            if (_log.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._log.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: accent.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(Icons.check_rounded, size: 14, color: accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t, style: TextStyle(fontSize: 13, color: surface.text))),
                ]),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _modeChip(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: _listening ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFC0392B).withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFC0392B).withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: active ? const Color(0xFFC0392B) : Colors.grey,
      )),
    ),
  );
}
