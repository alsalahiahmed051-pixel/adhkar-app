import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      color: AppColors.gold,
      title: 'أهلًا بك في أذكاري',
      body: 'تطبيقك المرافق لأذكار الصباح والمساء والنوم وكل أوقات اليوم. سبّح، احفظ، وشارك ذِكرك مع من تحب.',
    ),
    _OnboardingPage(
      icon: Icons.radio_button_unchecked_rounded,
      color: Color(0xFF1F6F5C),
      title: 'المسبحة الرقمية',
      body: 'اضغط على حلقة المسبحة لتبدأ العدّاد. كل 33 حبّة تكتمل جولة تلقائيًا. الحبّة الكبيرة هي الإمام.',
    ),
    _OnboardingPage(
      icon: Icons.mic_rounded,
      color: AppColors.voiceRed,
      title: 'اذكر الله بصوتك',
      body: 'الأيقونة الحمراء 🎙 على كل ذكر تفتح وضع العدّ الصوتي — قل الذكر بصوتك وسيُحتسب تلقائيًا دون أي لمس.',
    ),
    _OnboardingPage(
      icon: Icons.link_rounded,
      color: Color(0xFF5B57A0),
      title: 'شارك عدّادك',
      body: 'افتح أي ذكر واضغط «انشر» — ستحصل على كود خاص. شاركه مع أحد فيكمل معاك نفس العدّاد من أي مكان.',
    ),
    _OnboardingPage(
      icon: Icons.shield_rounded,
      color: AppColors.ink,
      title: 'محتوى مُراجَع',
      body: 'أي ذكر يُضاف من قِبل المستخدمين يمرّ بمراجعة المشرف قبل أن يظهر للجميع — للحفاظ على جودة المحتوى.',
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next(AppState state) {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      state.dismissOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final surface = state.surface;
    final page = _pages[_page];

    return Scaffold(
      backgroundColor: surface.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageContent(page: _pages[i], surface: surface),
              ),
            ),
            // dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                width: i == _page ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page ? page.color : page.color.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  if (_page > 0)
                    OutlinedButton(
                      onPressed: () => _ctrl.previousPage(
                          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: page.color.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _next(state),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: page.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _page == _pages.length - 1 ? 'ابدأ الآن!' : 'التالي',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  final AppSurface surface;
  const _PageContent({required this.page, required this.surface});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.color.withOpacity(0.12),
            ),
            child: Icon(page.icon, size: 48, color: page.color),
          ),
          const SizedBox(height: 32),
          Text(page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Amiri', fontSize: 26, fontWeight: FontWeight.bold, color: surface.text)),
          const SizedBox(height: 16),
          Text(page.body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: surface.muted, height: 1.8)),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}
