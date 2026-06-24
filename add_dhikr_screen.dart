import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/dhikr_item.dart';
import '../providers/app_state.dart';
import '../services/utils.dart';
import '../theme/app_colors.dart';

class AddDhikrScreen extends StatefulWidget {
  final String defaultCategoryId;
  const AddDhikrScreen({super.key, required this.defaultCategoryId});

  @override
  State<AddDhikrScreen> createState() => _AddDhikrScreenState();
}

class _AddDhikrScreenState extends State<AddDhikrScreen> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'text';
  late String _categoryId;
  String _title = '';
  String _source = '';
  String _target = '';
  String _text = '';
  String _caption = '';
  bool _shared = true;
  bool _uploadMode = true;
  bool _uploading = false;
  String _mediaUrl = '';
  String _fileName = '';
  File? _pickedFile;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.defaultCategoryId;
  }

  bool get _canSave {
    if (_title.trim().isEmpty) return false;
    if (_type == 'text') return _text.trim().isNotEmpty;
    return _mediaUrl.trim().isNotEmpty;
  }

  Future<void> _pickFile() async {
    if (_type == 'image') {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;
      setState(() { _pickedFile = File(picked.path); _fileName = picked.name; _mediaUrl = picked.path; });
    } else if (_type == 'audio') {
      final res = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (res == null || res.files.single.path == null) return;
      setState(() { _pickedFile = File(res.files.single.path!); _fileName = res.files.single.name; _mediaUrl = res.files.single.path!; });
    } else {
      final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg']);
      if (res == null || res.files.single.path == null) return;
      setState(() { _pickedFile = File(res.files.single.path!); _fileName = res.files.single.name; _mediaUrl = res.files.single.path!; });
    }
  }

  Future<void> _save(AppState state) async {
    if (!_canSave) return;
    setState(() => _uploading = true);
    String finalUrl = _mediaUrl;
    try {
      if (_pickedFile != null && _type != 'text') {
        finalUrl = await state.firestore.uploadFile(
          _pickedFile!,
          _type == 'image' ? 'images' : _type == 'audio' ? 'audio' : 'files',
          _fileName,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الرفع: $e')));
      }
      setState(() => _uploading = false);
      return;
    }

    final item = DhikrItem(
      id: generateId(),
      category: _categoryId,
      type: _type,
      title: _title.trim(),
      source: _source.trim(),
      target: _target.trim(),
      text: _type == 'text' ? _text.trim() : '',
      mediaUrl: _type != 'text' ? finalUrl : '',
      caption: _type == 'image' ? _caption.trim() : '',
      fileName: _type == 'file' ? _fileName : '',
      count: 0,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      shareCode: _shared ? generateShareCode() : null,
    );

    if (_shared) {
      await state.firestore.submitForReview(item);
    } else {
      await state.saveMine(item);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_shared ? 'تم الإرسال — ينتظر موافقة المشرف' : 'تم الحفظ في ذكرك الخاص')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final surface = state.surface;
    final TYPES = [
      ('text', 'نص', Icons.menu_book_rounded),
      ('image', 'صورة', Icons.image_rounded),
      ('audio', 'صوت', Icons.music_note_rounded),
      ('file', 'ملف / PDF', Icons.attach_file_rounded),
    ];

    return Scaffold(
      backgroundColor: surface.bg,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        leading: const CloseButton(color: Color(0xFFF6EFE2)),
        title: const Text('إضافة ذكر جديد',
            style: TextStyle(fontFamily: 'Amiri', fontSize: 19, color: Color(0xFFF6EFE2))),
        actions: [
          TextButton(
            onPressed: _canSave && !_uploading ? () => _save(state) : null,
            child: Text('حفظ',
                style: TextStyle(
                    color: (_canSave && !_uploading) ? AppColors.gold : AppColors.gold.withOpacity(0.4),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // type selector
            Row(
              children: TYPES.map((t) {
                final active = _type == t.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? AppColors.ink : surface.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: active ? AppColors.ink : AppColors.gold.withOpacity(0.3)),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(t.$3, size: 17, color: active ? Colors.white : AppColors.ink),
                        const SizedBox(height: 4),
                        Text(t.$2, style: TextStyle(fontSize: 11, color: active ? Colors.white : AppColors.ink)),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _field('العنوان *', onChanged: (v) => _title = v),
            _dropdown(state),
            Row(children: [
              Expanded(child: _field('المصدر / الشيخ', onChanged: (v) => _source = v)),
              const SizedBox(width: 12),
              Expanded(child: _field('عدد التكرار', onChanged: (v) => _target = v)),
            ]),
            if (_type == 'text')
              _field('نص الذكر *', onChanged: (v) => _text = v, maxLines: 6,
                  style: const TextStyle(fontFamily: 'Amiri', fontSize: 18, height: 2.1))
            else
              _mediaSection(surface),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text('إرساله للمجتمع', style: TextStyle(color: surface.text, fontSize: 15)),
              subtitle: Text('يحصل على كود مشاركة فوري، ويظهر للجميع بعد موافقة المشرف.',
                  style: TextStyle(color: surface.muted, fontSize: 12)),
              value: _shared,
              activeColor: AppColors.ink,
              onChanged: (v) => setState(() => _shared = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            if (_uploading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink, foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.ink.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: _canSave ? () => _save(state) : null,
                icon: const Icon(Icons.check_rounded),
                label: const Text('حفظ الذكر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(String hint, {required Function(String) onChanged, int maxLines = 1, TextStyle? style}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          onChanged: (v) { onChanged(v); setState(() {}); },
          maxLines: maxLines,
          style: style,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: context.read<AppState>().surface.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );

  Widget _dropdown(AppState state) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: _categoryId,
      decoration: InputDecoration(
        filled: true, fillColor: state.surface.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: state.allCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.label))).toList(),
      onChanged: (v) { if (v != null) setState(() => _categoryId = v); },
    ),
  );

  Widget _mediaSection(AppSurface surface) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        _modeChip('رفع ملف', _uploadMode, () => setState(() => _uploadMode = true)),
        const SizedBox(width: 8),
        _modeChip('رابط مباشر', !_uploadMode, () => setState(() => _uploadMode = false)),
      ]),
      const SizedBox(height: 10),
      if (_uploadMode)
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: surface.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withOpacity(0.4), style: BorderStyle.solid),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.upload_rounded, size: 28, color: AppColors.maroon),
              const SizedBox(height: 8),
              Text(_fileName.isNotEmpty ? 'تم اختيار: $_fileName' : 'اختر ملفًا من الجهاز',
                  style: TextStyle(color: AppColors.maroon, fontSize: 14)),
            ]),
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            onChanged: (v) { _mediaUrl = v; setState(() {}); },
            decoration: InputDecoration(
              hintText: 'https://...',
              filled: true, fillColor: surface.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      if (_type == 'image' && _pickedFile != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(_pickedFile!, height: 120, fit: BoxFit.cover),
        ),
      if (_type == 'image')
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextField(
            onChanged: (v) => setState(() => _caption = v),
            decoration: InputDecoration(
              hintText: 'وصف أسفل الصورة (اختياري)',
              filled: true, fillColor: surface.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      const SizedBox(height: 12),
    ],
  );

  Widget _modeChip(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AppColors.gold.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.ink, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
    ),
  );
}
