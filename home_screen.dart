import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dhikr_item.dart';
import '../models/category.dart';
import '../models/seed_data.dart';
import '../providers/app_state.dart';
import '../services/utils.dart';
import '../theme/app_colors.dart';
import '../widgets/dhikr_card.dart';
import '../widgets/diamond_rule.dart';
import 'detail_screen.dart';
import 'add_dhikr_screen.dart';
import 'voice_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _tab = 'morning';
  String _searchQ = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _goVoice(DhikrItem item, BuildContext ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => VoiceScreen(presetItem: item)));
  }

  void _openDetail(DhikrItem item, AppState state, BuildContext ctx) {
    final isPending = state.firestore.watchPendingItems() != null &&
        item.shareCode != null &&
        !item.isBuiltin;
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => DetailScreen(item: item, isPending: false, onVoice: (i) => _goVoice(i, ctx)),
      ),
    );
  }

  int _getCount(DhikrItem item, AppState state) {
    if (item.isBuiltin) return state.builtinCount(item.id);
    final mine = state.mine.where((x) => x.id == item.id);
    if (mine.isNotEmpty) return mine.first.count;
    return item.count;
  }

  void _bump(DhikrItem item, AppState state) {
    if (item.isBuiltin) {
      state.bumpBuiltin(item.id);
    } else {
      final isMine = state.mine.any((x) => x.id == item.id);
      if (isMine) {
        state.updateMineCount(item.id, (c) => c + 1);
      } else {
        state.firestore.incrementCount(item.id, isPending: false);
        state.bumpDailyOnly();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final surface = state.surface;

    return Scaffold(
      backgroundColor: surface.bg,
      drawer: _AppDrawer(
        currentTab: _tab,
        onSelect: (id) { setState(() => _tab = id); Navigator.pop(context); },
      ),
      body: StreamBuilder<List<DhikrItem>>(
        stream: state.firestore.watchCommunityItems(),
        builder: (ctx, snapCommunity) {
          final community = snapCommunity.data ?? [];
          final allItems = [...kSeedItems, ...community, ...state.mine];

          List<DhikrItem> visible;
          final q = normalizeArabic(_searchQ);
          if (q.length >= 2) {
            visible = allItems.where((i) =>
              normalizeArabic(i.title).contains(q) ||
              normalizeArabic(i.text).contains(q) ||
              normalizeArabic(i.source).contains(q) ||
              (i.shareCode?.toLowerCase() == _searchQ.trim().toLowerCase())).toList();
          } else if (_tab == '__fav') {
            visible = allItems.where((i) => state.isFavorite(i.id)).toList();
          } else if (_tab == '__audio') {
            visible = allItems.where((i) => i.type == 'audio').toList();
          } else if (_tab == '__files') {
            visible = allItems.where((i) => i.type == 'file' || i.type == 'image').toList();
          } else if (_tab == '__voice') {
            // voice has its own full screen; show empty state with nav button
            visible = [];
          } else {
            visible = allItems.where((i) => i.category == _tab).toList();
          }

          final activeMeta = findCategory([...state.allCategories, ...kCrossTabs], _tab);

          return NestedScrollView(
            headerSliverBuilder: (ctx2, _) => [
              SliverAppBar(
                pinned: true,
                expandedHeight: 130,
                backgroundColor: AppColors.ink,
                leading: Builder(builder: (ctx3) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppColors.gold),
                  onPressed: () => Scaffold.of(ctx3).openDrawer(),
                )),
                actions: [
                  IconButton(
                    icon: Icon(state.surface == AppSurface.light ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                        color: AppColors.gold),
                    onPressed: state.toggleTheme,
                    tooltip: 'تبديل الوضع الليلي',
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.gold),
                    onPressed: () => _showReminder(context),
                    tooltip: 'تذكير يومي',
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(bottom: 16),
                  title: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('أذكاري',
                        style: TextStyle(fontFamily: 'Amiri', fontSize: 22, color: Color(0xFFF6EFE2), fontWeight: FontWeight.w800)),
                    Text('تسبيحاتك اليوم: ${state.todayCount}',
                        style: const TextStyle(color: AppColors.gold, fontSize: 11)),
                  ]),
                  background: Container(color: AppColors.ink),
                ),
              ),
              SliverToBoxAdapter(child: _SearchBar(ctrl: _searchCtrl, onChanged: (v) => setState(() => _searchQ = v))),
              SliverToBoxAdapter(child: _CategoryScrollRow(currentTab: _tab, onSelect: (id) {
                if (id == '__voice') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceScreen()));
                  return;
                }
                setState(() => _tab = id);
              }, categories: state.allTabs)),
              SliverToBoxAdapter(child: DiamondRule(accent: activeMeta.accent)),
            ],
            body: visible.isEmpty
                ? _emptyState(activeMeta, surface, context)
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (ctx2, i) {
                      final item = visible[i];
                      return DhikrCard(
                        item: item,
                        count: _getCount(item, state),
                        isFav: state.isFavorite(item.id),
                        isPending: false,
                        onTap: () => _bump(item, state),
                        onOpen: () => _openDetail(item, state, ctx2),
                        onToggleFav: () => state.toggleFavorite(item.id),
                        onVoice: () => _goVoice(item, ctx2),
                      );
                    },
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة ذكر', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddDhikrScreen(defaultCategoryId: state.allCategories.any((c) => c.id == _tab) ? _tab : 'morning'),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(DhikrCategory meta, AppSurface surface, BuildContext ctx) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(meta.icon, size: 48, color: meta.accent.withOpacity(0.5)),
      const SizedBox(height: 16),
      Text('لا يوجد محتوى في «${meta.label}»',
          style: TextStyle(color: surface.text, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      if (_tab == '__voice')
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B), foregroundColor: Colors.white),
          icon: const Icon(Icons.mic_rounded),
          label: const Text('ابدأ الذكر بصوتك'),
          onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const VoiceScreen())),
        )
      else
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: meta.accent, foregroundColor: Colors.white),
          onPressed: () => Navigator.push(ctx, MaterialPageRoute(
            builder: (_) => AddDhikrScreen(defaultCategoryId: _tab),
          )),
          child: const Text('+ أضف الآن'),
        ),
    ]),
  );

  void _showReminder(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: context.read<AppState>().surface.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _ReminderSheet(),
    );
  }
}

// ─── Search bar ──────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final surface = context.watch<AppState>().surface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: TextField(
        controller: ctrl,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'ابحث عن ذكر أو أدخل كود مشاركة...',
          hintStyle: TextStyle(color: surface.muted, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.maroon, size: 20),
          suffixIcon: ctrl.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () { ctrl.clear(); onChanged(''); })
              : null,
          filled: true,
          fillColor: surface.card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }
}

// ─── Horizontal category pills ───────────────────────────────────────────────

class _CategoryScrollRow extends StatelessWidget {
  final String currentTab;
  final ValueChanged<String> onSelect;
  final List<DhikrCategory> categories;
  const _CategoryScrollRow({required this.currentTab, required this.onSelect, required this.categories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = categories[i];
          final active = currentTab == c.id;
          return GestureDetector(
            onTap: () => onSelect(c.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? c.accent : c.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.accent.withOpacity(active ? 0 : 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(c.icon, size: 15, color: active ? Colors.white : c.accent),
                const SizedBox(width: 6),
                Text(c.label, style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: active ? Colors.white : c.accent)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ─── Nav drawer ──────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final String currentTab;
  final ValueChanged<String> onSelect;
  const _AppDrawer({required this.currentTab, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Drawer(
      backgroundColor: AppColors.ink,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('أذكاري', style: TextStyle(fontFamily: 'Amiri', fontSize: 24, color: Color(0xFFF6EFE2), fontWeight: FontWeight.bold)),
                Text('سبّح واحفظ وشارك', style: TextStyle(color: AppColors.gold, fontSize: 12)),
              ]),
              IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFFF6EFE2)), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(color: Colors.white12),
          Expanded(child: ListView(padding: EdgeInsets.zero, children: [
            _label('التصنيفات'),
            ...state.allCategories.map((c) => _tile(c, c.id == currentTab, () => onSelect(c.id))),
            const Divider(color: Colors.white12, indent: 16, endIndent: 16),
            _label('أقسام خاصة'),
            ...kCrossTabs.map((c) => _tile(c, c.id == currentTab, () {
              if (c.id == '__voice') {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceScreen()));
              } else {
                onSelect(c.id);
              }
            })),
            const Divider(color: Colors.white12, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.add_circle_outlined, color: AppColors.gold, size: 20),
              title: const Text('اقترح تصنيفًا جديدًا', style: TextStyle(color: AppColors.gold, fontSize: 14)),
              onTap: () { Navigator.pop(context); _showProposeSheet(context, state); },
            ),
            ListTile(
              leading: const Icon(Icons.shield_rounded, color: Colors.white54, size: 20),
              title: const Text('لوحة المراجعة (المشرف)', style: TextStyle(color: Colors.white54, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => state.isAdmin ? const AdminPanelScreen() : const AdminGateScreen(),
                ));
              },
            ),
            ListTile(
              leading: Icon(state.themeMode == 'light' ? Icons.nightlight_round : Icons.wb_sunny_rounded, color: Colors.white54, size: 20),
              title: Text(state.themeMode == 'light' ? 'الوضع الليلي' : 'الوضع النهاري',
                  style: const TextStyle(color: Colors.white54, fontSize: 14)),
              onTap: () { state.toggleTheme(); Navigator.pop(context); },
            ),
          ])),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('نسخة تجريبية · أذكاري ١.٠',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 11)),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Text(text, style: const TextStyle(color: AppColors.gold, fontSize: 10, letterSpacing: 2)),
  );

  Widget _tile(DhikrCategory c, bool active, VoidCallback onTap) => ListTile(
    leading: Icon(c.icon, size: 18, color: active ? c.accent : Colors.white54),
    title: Text(c.label, style: TextStyle(color: active ? Colors.white : Colors.white70, fontSize: 14)),
    selected: active,
    selectedTileColor: c.accent.withOpacity(0.2),
    shape: Border(right: BorderSide(color: active ? c.accent : Colors.transparent, width: 3)),
    onTap: onTap,
  );

  void _showProposeSheet(BuildContext ctx, AppState state) {
    showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (_) => _ProposeCategorySheet());
  }
}

// ─── Propose Category Sheet ───────────────────────────────────────────────────

class _ProposeCategorySheet extends StatefulWidget {
  @override
  State<_ProposeCategorySheet> createState() => _ProposeCategorySheetState();
}

class _ProposeCategorySheetState extends State<_ProposeCategorySheet> {
  String _label = '';
  String _iconKey = 'Star';
  Color _accent = const Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final surface = state.surface;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('اقتراح تصنيف جديد',
            style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: surface.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) => setState(() => _label = v),
          decoration: InputDecoration(
            hintText: 'مثال: أذكار السفر',
            filled: true, fillColor: surface.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        Text('الأيقونة', style: TextStyle(color: surface.muted, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: kIconChoices.entries.map((e) {
          final active = _iconKey == e.key;
          return GestureDetector(
            onTap: () => setState(() => _iconKey = e.key),
            child: CircleAvatar(
              backgroundColor: active ? _accent.withOpacity(0.2) : surface.card,
              child: Icon(e.value, color: active ? _accent : surface.muted, size: 18),
            ),
          );
        }).toList()),
        const SizedBox(height: 12),
        Text('اللون', style: TextStyle(color: surface.muted, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: kAccentChoices.map((hex) {
          final c = colorFromHex(hex);
          return GestureDetector(
            onTap: () => setState(() => _accent = c),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c, border: Border.all(
                color: _accent == c ? surface.text : Colors.transparent, width: 2)),
            ),
          );
        }).toList()),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.send_rounded),
          label: const Text('إرسال للمراجعة', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _label.trim().length >= 2 ? () async {
            final cat = DhikrCategory(
              id: generateId(), label: _label.trim(),
              icon: kIconChoices[_iconKey]!, accent: _accent, isCustom: true,
            );
            await state.firestore.proposeCategory(cat);
            if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الإرسال للمراجعة'))); }
          } : null,
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ─── Reminder sheet ──────────────────────────────────────────────────────────

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet();
  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  TimeOfDay _morning = const TimeOfDay(hour: 5, minute: 30);
  TimeOfDay _evening = const TimeOfDay(hour: 17, minute: 30);
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    context.read<AppState>().surface; // just to trigger rebuild
  }

  Future<void> _pick(bool isMorning) async {
    final t = await showTimePicker(context: context, initialTime: isMorning ? _morning : _evening);
    if (t == null) return;
    setState(() { if (isMorning) _morning = t; else _evening = t; });
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.watch<AppState>().surface;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('تذكير يومي', style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: surface.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('وقت أذكار الصباح ☀️', style: TextStyle(color: surface.text)),
          trailing: OutlinedButton(onPressed: () => _pick(true), child: Text(_morning.format(context))),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('وقت أذكار المساء 🌙', style: TextStyle(color: surface.text)),
          trailing: OutlinedButton(onPressed: () => _pick(false), child: Text(_evening.format(context))),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('تفعيل التذكير', style: TextStyle(color: surface.text)),
          value: _enabled,
          activeColor: AppColors.ink,
          onChanged: (v) => setState(() => _enabled = v),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_enabled ? 'تم تفعيل التذكير' : 'تم حفظ الإعدادات'))); },
          child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}
