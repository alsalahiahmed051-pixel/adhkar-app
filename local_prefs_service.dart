import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dhikr_item.dart';

/// Everything here is private to this device/install — equivalent to the
/// `shared:false` calls in the web prototype (favorites, your own
/// not-yet-shared items, builtin counters, theme choice, daily stats).
class LocalPrefsService {
  static const _kMine = 'my_items';
  static const _kFavorites = 'favorites';
  static const _kBuiltinCounts = 'builtin_counts';
  static const _kTheme = 'theme_mode';
  static const _kDailyStats = 'daily_stats';
  static const _kSeenOnboarding = 'seen_onboarding';
  static const _kReminderMorning = 'reminder_morning';
  static const _kReminderEvening = 'reminder_evening';
  static const _kReminderEnabled = 'reminder_enabled';

  Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  Future<List<DhikrItem>> getMine() async {
    final p = await _p;
    final raw = p.getString(_kMine);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(DhikrItem.fromJson).toList();
  }

  Future<void> setMine(List<DhikrItem> items) async {
    final p = await _p;
    await p.setString(_kMine, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<Set<String>> getFavorites() async {
    final p = await _p;
    return (p.getStringList(_kFavorites) ?? []).toSet();
  }

  Future<void> setFavorites(Set<String> ids) async {
    final p = await _p;
    await p.setStringList(_kFavorites, ids.toList());
  }

  Future<Map<String, int>> getBuiltinCounts() async {
    final p = await _p;
    final raw = p.getString(_kBuiltinCounts);
    if (raw == null) return {};
    return Map<String, int>.from(jsonDecode(raw) as Map);
  }

  Future<void> setBuiltinCounts(Map<String, int> counts) async {
    final p = await _p;
    await p.setString(_kBuiltinCounts, jsonEncode(counts));
  }

  Future<String> getTheme() async {
    final p = await _p;
    return p.getString(_kTheme) ?? 'light';
  }

  Future<void> setTheme(String mode) async {
    final p = await _p;
    await p.setString(_kTheme, mode);
  }

  /// Returns {date: 'YYYY-MM-DD', count: n}, reset automatically if the
  /// stored date isn't today.
  Future<int> getTodayCount() async {
    final p = await _p;
    final raw = p.getString(_kDailyStats);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (raw == null) return 0;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (map['date'] != today) return 0;
    return map['count'] as int;
  }

  Future<int> bumpTodayCount() async {
    final p = await _p;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final current = await getTodayCount();
    final next = current + 1;
    await p.setString(_kDailyStats, jsonEncode({'date': today, 'count': next}));
    return next;
  }

  Future<bool> getSeenOnboarding() async => (await _p).getBool(_kSeenOnboarding) ?? false;
  Future<void> setSeenOnboarding(bool v) async => (await _p).setBool(_kSeenOnboarding, v);

  Future<Map<String, dynamic>> getReminderSettings() async {
    final p = await _p;
    return {
      'morning': p.getString(_kReminderMorning) ?? '05:30',
      'evening': p.getString(_kReminderEvening) ?? '17:30',
      'enabled': p.getBool(_kReminderEnabled) ?? false,
    };
  }

  Future<void> setReminderSettings({required String morning, required String evening, required bool enabled}) async {
    final p = await _p;
    await p.setString(_kReminderMorning, morning);
    await p.setString(_kReminderEvening, evening);
    await p.setBool(_kReminderEnabled, enabled);
  }
}
