import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:gitora/application/providers/onboarding_provider.dart';
import 'package:gitora/application/providers/settings_provider.dart';
import 'package:gitora/core/constants/app_constants.dart';
import 'package:gitora/core/theme/app_theme.dart';
import 'package:gitora/infrastructure/db/database_service.dart';
import 'package:gitora/l10n/app_localizations.dart';
import 'package:gitora/presentation/screens/onboarding/onboarding_wizard.dart';
import 'package:gitora/presentation/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI for Desktop
  await DatabaseService.initialize();

  // Load preferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize desktop window manager
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1340, 840),
        minimumSize: Size(1000, 680),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        title: AppConstants.appName,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (_) {
      // Window manager might not be available in headless test environments
    }
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const GitoraApp(),
    ),
  );
}

class GitoraApp extends ConsumerWidget {
  const GitoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final onboardingState = ref.watch(onboardingProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(
        seedColor: settings.seedColor,
        density: settings.density,
      ),
      darkTheme: AppTheme.darkTheme(
        seedColor: settings.seedColor,
        density: settings.density,
      ),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: onboardingState.isCompleted
          ? const MainShell()
          : const OnboardingWizard(),
    );
  }
}
