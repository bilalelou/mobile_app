import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// ─── Glass Container ───────────────────────────────────────────────
///
/// Reusable glassmorphism container with frosted blur, semi-transparent
/// fill, and a subtle border. Used across the app for search bars,
/// cards, and overlays.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final Color? fillColor;
  final Color? borderColor;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.blur = 20,
    this.fillColor,
    this.borderColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fillColor ?? AppColors.glassFill,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? AppColors.glassBorder,
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
