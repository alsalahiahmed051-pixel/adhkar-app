import 'dart:async';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/dhikr_item.dart';
import '../services/local_prefs_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

const String kAdminPasscode = '1234'; // demo-only gate, see README for the real-app note

class AppState extends ChangeNotifier {
  final LocalPrefsService _prefs = LocalPrefsService();
  final FirestoreService firestore = FirestoreService();

  bool loading = true;
  String themeMode = 'light';
  Set<String> favorites = {};
  List<DhikrItem> mine = [];
  Map<String, int> builtinCounts = {};
  int todayCount = 0;
  bool isAdmin = false;
  bool seenOnboarding = false;

  List<DhikrCategory> customCategories = [];
  List<DhikrCategory> pendingCategories = [];

  StreamSubscription? _customCatSub;
  StreamSubscription? _pendingCatSub;

  AppSurface get surface => themeMode == 'light' ? AppSurface.light : AppSurface.dark;
  List<DhikrCategory> get allCategories => [...kBuiltinCategories, ...customCategories];
  List<DhikrCategory> get allTabs => [...allCategories, ...kCrossTabs];

  Future<void> init() async {
    themeMode = await _prefs.getTheme();
    favorites = await _prefs.getFavorites();
    mine = await _prefs.getMine();
    builtinCounts = await _prefs.getBuiltinCounts();
    todayCount = await _prefs.getTodayCount();
    seenOnboarding = await _prefs.getSeenOnboarding();

    _customCatSub = firestore.watchCustomCategories().listen((cats) {
      customCategories = cats;
      notifyListeners();
    });
    _pendingCatSub = firestore.watchPendingCategories().listen((cats) {
      pendingCategories = cats;
      notifyListeners();
    });

    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _customCatSub?.cancel();
    _pendingCatSub?.cancel();
    super.dispose();
  }

  Future<void> toggleTheme() async {
    themeMode = themeMode == 'light' ? 'dark' : 'light';
    await _prefs.setTheme(themeMode);
    notifyListeners();
  }

  Future<void> dismissOnboarding() async {
    seenOnboarding = true;
    await _prefs.setSeenOnboarding(true);
    notifyListeners();
  }

  bool isFavorite(String id) => favorites.contains(id);

  Future<void> toggleFavorite(String id) async {
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    await _prefs.setFavorites(favorites);
    notifyListeners();
  }

  int builtinCount(String id) => builtinCounts[id] ?? 0;

  Future<void> bumpBuiltin(String id) async {
    builtinCounts[id] = (builtinCounts[id] ?? 0) + 1;
    await _prefs.setBuiltinCounts(builtinCounts);
    todayCount = await _prefs.bumpTodayCount();
    notifyListeners();
  }

  Future<void> resetBuiltin(String id) async {
    builtinCounts[id] = 0;
    await _prefs.setBuiltinCounts(builtinCounts);
    notifyListeners();
  }

  Future<void> bumpDailyOnly() async {
    todayCount = await _prefs.bumpTodayCount();
    notifyListeners();
  }

  Future<void> saveMine(DhikrItem item) async {
    mine = [item, ...mine];
    await _prefs.setMine(mine);
    notifyListeners();
  }

  Future<void> updateMineCount(String id, int Function(int) updater) async {
    mine = mine.map((x) => x.id == id ? x.copyWith(count: updater(x.count)) : x).toList();
    await _prefs.setMine(mine);
    notifyListeners();
  }

  Future<void> removeMine(String id) async {
    mine = mine.where((x) => x.id != id).toList();
    await _prefs.setMine(mine);
  }

  bool checkAdminPasscode(String pin) {
    if (pin.trim() == kAdminPasscode) {
      isAdmin = true;
      notifyListeners();
      return true;
    }
    return false;
  }
}
