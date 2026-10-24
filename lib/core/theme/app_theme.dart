import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gitora/core/theme/app_colors.dart';

enum InterfaceDensity { comfortable, compact }

class AppTheme {
  static ThemeData lightTheme({
    Color seedColor = AppColors.defaultSeed,
    InterfaceDensity density = InterfaceDensity.comfortable,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return _buildTheme(colorScheme, density);
  }

  static ThemeData darkTheme({
    Color seedColor = AppColors.defaultSeed,
    InterfaceDensity density = InterfaceDensity.comfortable,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return _buildTheme(colorScheme, density);
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    InterfaceDensity density,
  ) {
    final isCompact = density == InterfaceDensity.compact;
    final visualDensity = isCompact
        ? VisualDensity.compact
        : VisualDensity.standard;

    // Use Inter with system font fallback
    final baseTextTheme = Typography.material2021().black;
    final textTheme =
        GoogleFonts.interTextTheme(
          colorScheme.brightness == Brightness.dark
              ? Typography.material2021().white
              : baseTextTheme,
        ).copyWith(
          headlineSmall: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          titleLarge: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          titleMedium: const TextStyle(fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(fontSize: 14.5, height: 1.4),
          bodyMedium: const TextStyle(fontSize: 13.5, height: 1.4),
          labelLarge: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: visualDensity,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(80),
            width: 1,
          ),
        ),
        color: colorScheme.surfaceContainerLow,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        backgroundColor: colorScheme.surfaceContainerHigh,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 14 : 18,
            vertical: isCompact ? 10 : 14,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(color: colorScheme.outline.withAlpha(120)),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 14 : 18,
            vertical: isCompact ? 10 : 14,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(120),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isCompact ? 10 : 14,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.secondaryContainer,
        selectedIconTheme: IconThemeData(
          color: colorScheme.onSecondaryContainer,
        ),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: colorScheme.onInverseSurface, fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withAlpha(60),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
