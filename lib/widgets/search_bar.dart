import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'glass_container.dart';

/// ─── App Search Bar ────────────────────────────────────────────────
///
/// Glassmorphism search bar with animated search icon,
/// Arabic RTL support, and clear button.
class AppSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final String hintText;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.hintText = 'ابحث عن أنمي...',
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _iconController.forward();
      } else {
        _iconController.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _iconController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (widget.controller.text.trim().isNotEmpty) {
      FocusScope.of(context).unfocus();
      widget.onSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      borderRadius: 18,
      blur: 15,
      child: Row(
        children: [
          // ─── Search Icon ──────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 4, left: 8),
            child: AnimatedBuilder(
              animation: _iconController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _iconController.value * 0.5,
                  child: Icon(
                    Icons.search_rounded,
                    color: Color.lerp(
                      AppColors.textMuted,
                      AppColors.primaryLight,
                      _iconController.value,
                    ),
                    size: 24,
                  ),
                );
              },
            ),
          ),

          // ─── Text Field ───────────────────────────────
          Expanded(
            child: TextField(
              controller: widget.controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _handleSubmit(),
              textDirection: TextDirection.rtl,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTextStyles.searchHint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // ─── Clear / Search Button ────────────────────
          if (_hasText)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textMuted,
                  onPressed: () {
                    widget.controller.clear();
                  },
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    color: Colors.white,
                    onPressed: _handleSubmit,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 38, minHeight: 38),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
