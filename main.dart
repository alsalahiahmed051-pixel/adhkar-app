import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const AdhkarApp(),
    ),
  );
}

class AdhkarApp extends StatelessWidget {
  const AdhkarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, state, __) {
        final isDark = state.themeMode == 'dark';
        final surface = isDark ? AppSurface.dark : AppSurface.light;
        return MaterialApp(
          title: 'أذكاري',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(AppSurface.light, Brightness.light),
          darkTheme: AppTheme.build(AppSurface.dark, Brightness.dark),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          locale: const Locale('ar', 'SA'),
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
          home: state.loading
              ? _Splash(surface: surface)
              : state.seenOnboarding
                  ? const HomeScreen()
                  : const OnboardingScreen(),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  final AppSurface surface;
  const _Splash({required this.surface});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أذكاري',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
