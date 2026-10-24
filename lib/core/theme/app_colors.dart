import 'package:flutter/material.dart';

class AppColors {
  // Preset seed colors for user theme personalization
  static const List<Color> seedPalette = [
    Color(0xFF6342E8), // Deep Violet (Default Gitora)
    Color(0xFF4F46E5), // Indigo
    Color(0xFF2563EB), // Royal Blue
    Color(0xFF0D9488), // Cyber Teal
    Color(0xFF059669), // Emerald
    Color(0xFFD97706), // Sunset Amber
    Color(0xFFE11D48), // Crimson Rose
  ];

  static const Color defaultSeed = Color(0xFF6342E8);

  // Git state indicators
  static const Color gitAdded = Color(0xFF10B981);
  static const Color gitModified = Color(0xFF3B82F6);
  static const Color gitDeleted = Color(0xFFEF4444);
  static const Color gitRenamed = Color(0xFF8B5CF6);
  static const Color gitUntracked = Color(0xFFF59E0B);
  static const Color gitIgnored = Color(0xFF6B7280);
  static const Color gitConflict = Color(0xFFEC4899);

  // Diff colors
  static const Color diffAddedLineBgLight = Color(0x2210B981);
  static const Color diffAddedLineBgDark = Color(0x3310B981);
  static const Color diffAddedText = Color(0xFF059669);

  static const Color diffDeletedLineBgLight = Color(0x22EF4444);
  static const Color diffDeletedLineBgDark = Color(0x33EF4444);
  static const Color diffDeletedText = Color(0xFFDC2626);

  static const Color diffHunkHeaderBgLight = Color(0x156342E8);
  static const Color diffHunkHeaderBgDark = Color(0x2A6342E8);

  // Graph branch color lanes (high contrast, distinct)
  static const List<Color> graphLaneColors = [
    Color(0xFF6342E8), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF3B82F6), // Blue
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
    Color(0xFFA855F7), // Purple bright
  ];
}
