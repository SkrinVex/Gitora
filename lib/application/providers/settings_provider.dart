import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gitora/core/constants/app_constants.dart';
import 'package:gitora/core/theme/app_colors.dart';
import 'package:gitora/core/theme/app_theme.dart';
import 'package:gitora/infrastructure/git/hybrid_git_service.dart';

class AppSettings {
  final ThemeMode themeMode;
  final Color seedColor;
  final InterfaceDensity density;
  final bool reduceAnimations;
  final Locale? locale;
  final GitBackendMode backendMode;
  final String customGitPath;
  final bool isUnifiedDiff;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.seedColor = AppColors.defaultSeed,
    this.density = InterfaceDensity.comfortable,
    this.reduceAnimations = false,
    this.locale,
    this.backendMode = GitBackendMode.auto,
    this.customGitPath = '',
    this.isUnifiedDiff = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    Color? seedColor,
    InterfaceDensity? density,
    bool? reduceAnimations,
    Locale? locale,
    GitBackendMode? backendMode,
    String? customGitPath,
    bool? isUnifiedDiff,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      density: density ?? this.density,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      locale: locale ?? this.locale,
      backendMode: backendMode ?? this.backendMode,
      customGitPath: customGitPath ?? this.customGitPath,
      isUnifiedDiff: isUnifiedDiff ?? this.isUnifiedDiff,
    );
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    if (prefs == null) return const AppSettings();

    final themeStr = prefs.getString(AppConstants.prefThemeMode);
    final themeMode = themeStr == 'dark'
        ? ThemeMode.dark
        : (themeStr == 'light' ? ThemeMode.light : ThemeMode.system);

    final colorVal = prefs.getInt(AppConstants.prefSeedColor);
    final seedColor = colorVal != null
        ? Color(colorVal)
        : AppColors.defaultSeed;

    final densityStr = prefs.getString(AppConstants.prefDensity);
    final density = densityStr == 'compact'
        ? InterfaceDensity.compact
        : InterfaceDensity.comfortable;

    final reduceAnim =
        prefs.getBool(AppConstants.prefReduceAnimations) ?? false;

    final lang = prefs.getString(AppConstants.prefLanguage);
    final locale = lang != null && lang.isNotEmpty ? Locale(lang) : null;

    final backendStr = prefs.getString(AppConstants.prefBackend);
    final backendMode = backendStr == 'libgit2Only'
        ? GitBackendMode.libgit2Only
        : (backendStr == 'cliOnly'
              ? GitBackendMode.cliOnly
              : GitBackendMode.auto);

    final gitPath = prefs.getString(AppConstants.prefGitPath) ?? '';
    final isUnified = prefs.getBool(AppConstants.prefDiffViewMode) ?? true;

    return AppSettings(
      themeMode: themeMode,
      seedColor: seedColor,
      density: density,
      reduceAnimations: reduceAnim,
      locale: locale,
      backendMode: backendMode,
      customGitPath: gitPath,
      isUnifiedDiff: isUnified,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = ref.read(sharedPreferencesProvider);
    final str = mode == ThemeMode.dark
        ? 'dark'
        : (mode == ThemeMode.light ? 'light' : 'system');
    await prefs?.setString(AppConstants.prefThemeMode, str);
  }

  Future<void> setSeedColor(Color color) async {
    state = state.copyWith(seedColor: color);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs?.setInt(AppConstants.prefSeedColor, color.toARGB32());
  }

  Future<void> setDensity(InterfaceDensity density) async {
    state = state.copyWith(density: density);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs?.setString(
      AppConstants.prefDensity,
      density == InterfaceDensity.compact ? 'compact' : 'comfortable',
    );
  }

  Future<void> setReduceAnimations(bool value) async {
    state = state.copyWith(reduceAnimations: value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs?.setBool(AppConstants.prefReduceAnimations, value);
  }

  Future<void> setLanguage(String languageCode) async {
    final locale = languageCode.isNotEmpty ? Locale(languageCode) : null;
    state = state.copyWith(locale: locale);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs?.setString(AppConstants.prefLanguage, languageCode);
  }

  Future<void> setBackendMode(GitBackendMode mode) async {
    state = state.copyWith(backendMode: mode);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs?.setString(AppConstants.prefBackend, mode.name);
  }

  Future<void> setCustomGitPath(String path) async {
    state = state.copyWith(customGitPath: path);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs?.setString(AppConstants.prefGitPath, path);
  }

  Future<void> toggleDiffViewMode() async {
    final next = !state.isUnifiedDiff;
    state = state.copyWith(isUnifiedDiff: next);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs?.setBool(AppConstants.prefDiffViewMode, next);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
