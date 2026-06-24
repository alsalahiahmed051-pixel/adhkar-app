import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/dhikr_item.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/pill.dart';

// ─── Gate ────────────────────────────────────────────────────────────────────

class AdminGateScreen extends StatefulWidget {
  const AdminGateScreen({super.key});
  @override
  State<AdminGateScreen> createState() => _AdminGateScreenState();
}

class _AdminGateScreenState extends State<AdminGateScreen> {
  final _ctrl = TextEditingController();
  String _error = '';

  void _submit(AppState state) {
    if (state.checkAdminPasscode(_ctrl.text)) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
    } else {
      setState(() => _error = 'الرمز غير صحيح.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final surface = state.surface;
    return Scaffold(
      backgroundColor: surface.bg,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        leading: const BackButton(color: Color(0xFFF6EFE2)),
        title: const Text('دخول المشرف',
            style: TextStyle(fontFamily: 'Amiri', color: Color(0xFFF6EFE2), fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, size: 48, color: AppColors.ink),
            const SizedBox(height: 16),
            Text('أدخل رمز المراجعة',
                style: TextStyle(color: surface.text, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(color: surface.text, fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                filled: true, fillColor: surface.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _submit(state),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_error, style: const TextStyle(color: AppColors.voiceRed)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _submit(state),
                child: const Text('دخول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            Text('قفل تجريبي بسيط — وليس نظام صلاحيات حقيقي.',
                style: TextStyle(color: surface.muted, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Panel ───────────────────────────────────────────────────────────────────

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final surface = state.surface;
    return Scaffold(
      backgroundColor: surface.bg,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        leading: const BackButton(color: Color(0xFFF6EFE2)),
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.shield_rounded, color: AppColors.gold, size: 20),
          SizedBox(width: 8),
          Text('لوحة المراجعة', style: TextStyle(fontFamily: 'Amiri', color: Color(0xFFF6EFE2), fontSize: 18)),
        ]),
      ),
      body: StreamBuilder<List<DhikrItem>>(
        stream: state.firestore.watchPendingItems(),
        builder: (context, snapItems) {
          final pendingItems = snapItems.data ?? [];
          final pendingCats = state.pendingCategories;
          final empty = pendingItems.isEmpty && pendingCats.isEmpty;

          if (empty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_rounded, size: 48, color: const Color(0xFF1F6F5C).withOpacity(0.7)),
                const SizedBox(height: 12),
                Text('لا يوجد شيء بانتظار المراجعة 🎉',
                    style: TextStyle(color: surface.text, fontSize: 16)),
              ]),
            );
          }

          return ListView(padding: const EdgeInsets.all(16), children: [
            if (pendingCats.isNotEmpty) ...[
              _sectionLabel('تصنيفات بانتظار الموافقة (${pendingCats.length})', surface),
              ...pendingCats.map((c) => _CategoryTile(cat: c)),
              const SizedBox(height: 16),
            ],
            if (pendingItems.isNotEmpty) ...[
              _sectionLabel('أذكار بانتظار الموافقة (${pendingItems.length})', surface),
              ...pendingItems.map((i) => _ItemTile(item: i)),
            ],
          ]);
        },
      ),
    );
  }

  Widget _sectionLabel(String text, AppSurface surface) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(color: AppColors.maroon, fontSize: 13, fontWeight: FontWeight.w700)),
  );
}

class _CategoryTile extends StatelessWidget {
  final DhikrCategory cat;
  const _CategoryTile({required this.cat});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: state.surface.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cat.accent.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cat.accent.withOpacity(0.12),
          child: Icon(cat.icon, color: cat.accent, size: 18),
        ),
        title: Text(cat.label, style: TextStyle(color: state.surface.text, fontWeight: FontWeight.w600)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          _actionBtn(Icons.check_rounded, const Color(0xFF1F6F5C), () => state.firestore.approveCategory(cat)),
          _actionBtn(Icons.close_rounded, AppColors.voiceRed, () => state.firestore.rejectCategory(cat.id)),
        ]),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final DhikrItem item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final meta = findCategory(state.allCategories, item.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: state.surface.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: meta.accent.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: meta.accent.withOpacity(0.12),
          child: Icon(meta.icon, color: meta.accent, size: 18),
        ),
        title: Text(item.title, style: TextStyle(color: state.surface.text, fontWeight: FontWeight.w600)),
        subtitle: Text(meta.label, style: TextStyle(color: meta.accent, fontSize: 12)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          _actionBtn(Icons.check_rounded, const Color(0xFF1F6F5C), () => state.firestore.approveItem(item)),
          _actionBtn(Icons.close_rounded, AppColors.voiceRed, () => state.firestore.rejectItem(item.id)),
        ]),
      ),
    );
  }
}

Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) => IconButton(
  icon: CircleAvatar(
    backgroundColor: color.withOpacity(0.12),
    radius: 16,
    child: Icon(icon, size: 16, color: color),
  ),
  onPressed: onTap,
);
