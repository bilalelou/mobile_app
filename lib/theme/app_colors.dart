import 'package:flutter/material.dart';

/// ─── AnimeGrab Color System ────────────────────────────────────────
///
/// Dark theme with purple/cyan accents inspired by modern anime UIs.
/// All colors are carefully chosen for WCAG AA contrast on dark surfaces.
class AppColors {
  AppColors._();

  // ─── Background Layers ──────────────────────────────────────────
  static const Color background = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252542);
  static const Color surfaceOverlay = Color(0x331A1A2E); // 20% opacity

  // ─── Primary (Purple) ───────────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF5B21B6);

  // ─── Accent (Cyan) ─────────────────────────────────────────────
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentLight = Color(0xFF22D3EE);

  // ─── Text ───────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF1F1F6);
  static const Color textSecondary = Color(0xFFA1A1B5);
  static const Color textMuted = Color(0xFF6B6B80);

  // ─── Status ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ─── Glassmorphism ──────────────────────────────────────────────
  static const Color glassFill = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white

  // ─── Gradients ──────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF9333EA)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFF0891B2)],
  );

  static const LinearGradient cardOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC0D0D1A)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF16132B), background],
  );
}
