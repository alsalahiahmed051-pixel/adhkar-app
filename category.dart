import 'package:flutter/material.dart';

class DhikrCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color accent;
  final bool isCustom;

  const DhikrCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.accent,
    this.isCustom = false,
  });

  factory DhikrCategory.fromMap(Map<String, dynamic> map) => DhikrCategory(
        id: map['id'] as String,
        label: map['label'] as String,
        icon: kIconChoices[map['iconKey']] ?? Icons.star_rounded,
        accent: Color(int.parse((map['accent'] as String).replaceFirst('#', '0xFF'))),
        isCustom: true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'iconKey': kIconChoices.entries.firstWhere(
          (e) => e.value == icon,
          orElse: () => const MapEntry('Star', Icons.star_rounded),
        ).key,
        'accent': '#${accent.value.toRadixString(16).substring(2).toUpperCase()}',
      };
}

/// Curated icon choices a user can pick from when proposing a category
/// (mirrors ICON_MAP in the web prototype — must stay serializable).
const Map<String, IconData> kIconChoices = {
  'Sun': Icons.wb_sunny_rounded,
  'Moon': Icons.nightlight_round,
  'Star': Icons.star_rounded,
  'Heart': Icons.favorite_rounded,
  'BookOpen': Icons.menu_book_rounded,
  'Layers': Icons.layers_rounded,
  'Mail': Icons.mail_rounded,
  'Sparkles': Icons.auto_awesome_rounded,
  'Music': Icons.music_note_rounded,
  'Paperclip': Icons.attach_file_rounded,
  'RefreshCw': Icons.refresh_rounded,
  'Bookmark': Icons.bookmark_rounded,
};

const List<String> kAccentChoices = [
  '#C9A227', '#5B57A0', '#4A5C9E', '#1F6F5C', '#1E8A8A',
  '#6B6F2A', '#B5651D', '#7A2E2E', '#8E3B60', '#C0392B',
];

Color colorFromHex(String hex) =>
    Color(int.parse(hex.replaceFirst('#', '0xFF')));

const List<DhikrCategory> kBuiltinCategories = [
  DhikrCategory(id: 'morning', label: 'أذكار الصباح', icon: Icons.wb_sunny_rounded, accent: Color(0xFFC9A227)),
  DhikrCategory(id: 'evening', label: 'أذكار المساء', icon: Icons.nightlight_round, accent: Color(0xFF5B57A0)),
  DhikrCategory(id: 'sleep', label: 'أذكار النوم', icon: Icons.star_rounded, accent: Color(0xFF4A5C9E)),
  DhikrCategory(id: 'salawat', label: 'الصلاة على النبي ﷺ', icon: Icons.favorite_rounded, accent: Color(0xFF1F6F5C)),
  DhikrCategory(id: 'full', label: 'أذكار الله الكاملة', icon: Icons.menu_book_rounded, accent: Color(0xFF1E8A8A)),
  DhikrCategory(id: 'ahzab', label: 'الأحزاب', icon: Icons.layers_rounded, accent: Color(0xFF6B6F2A)),
  DhikrCategory(id: 'awrad', label: 'الأوراد', icon: Icons.refresh_rounded, accent: Color(0xFFB5651D)),
  DhikrCategory(id: 'risala', label: 'الرسالة', icon: Icons.mail_rounded, accent: Color(0xFF7A2E2E)),
  DhikrCategory(id: 'mawalid', label: 'الموالد', icon: Icons.auto_awesome_rounded, accent: Color(0xFF8E3B60)),
];

/// Cross-cutting tabs (not real content categories — filters/sections).
const List<DhikrCategory> kCrossTabs = [
  DhikrCategory(id: '__fav', label: 'المفضلة', icon: Icons.bookmark_rounded, accent: Color(0xFFC9A227)),
  DhikrCategory(id: '__voice', label: 'اذكر الله بصوتك', icon: Icons.mic_rounded, accent: Color(0xFFC0392B)),
  DhikrCategory(id: '__audio', label: 'الصوتيات', icon: Icons.volume_up_rounded, accent: Color(0xFF44546B)),
  DhikrCategory(id: '__files', label: 'الملفات', icon: Icons.folder_rounded, accent: Color(0xFF8A6A4B)),
];

DhikrCategory findCategory(List<DhikrCategory> all, String id) =>
    all.firstWhere((c) => c.id == id, orElse: () => all.first);
