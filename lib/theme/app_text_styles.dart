import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ─── AnimeGrab Typography ──────────────────────────────────────────
///
/// Uses Cairo for Arabic headings (beautiful, modern Arabic typeface)
/// and Inter for Latin/numeric content.
/// All styles are RTL-ready.
class AppTextStyles {
  AppTextStyles._();

  // ─── Arabic Font Family ─────────────────────────────────────────
  static const String arabicFont = 'Cairo';
  static const String latinFont = 'Inter';

  // ─── Headings ───────────────────────────────────────────────────

  /// App bar title, big headings
  static const TextStyle h1 = TextStyle(
    fontFamily: arabicFont,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Section titles
  static const TextStyle h2 = TextStyle(
    fontFamily: arabicFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Card titles, anime names
  static const TextStyle h3 = TextStyle(
    fontFamily: arabicFont,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ─── Body ───────────────────────────────────────────────────────

  /// Normal body text
  static const TextStyle body = TextStyle(
    fontFamily: arabicFont,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  /// Secondary body text (descriptions, subtitles)
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: arabicFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  /// Small text (captions, metadata)
  static const TextStyle caption = TextStyle(
    fontFamily: arabicFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  // ─── Special ────────────────────────────────────────────────────

  /// Episode numbers, download stats
  static const TextStyle number = TextStyle(
    fontFamily: latinFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryLight,
    height: 1.2,
  );

  /// Chip labels (genres)
  static const TextStyle chip = TextStyle(
    fontFamily: arabicFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryLight,
    height: 1.3,
  );

  /// Button text
  static const TextStyle button = TextStyle(
    fontFamily: arabicFont,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: 0.3,
  );

  /// Search bar hint
  static const TextStyle searchHint = TextStyle(
    fontFamily: arabicFont,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );
}
