import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// ─── Episode Tile ──────────────────────────────────────────────────
///
/// List tile for a single episode with episode number badge,
/// title, and action buttons (watch/download).
class EpisodeTile extends StatelessWidget {
  final int episodeNumber;
  final String title;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback? onWatch;
  final VoidCallback? onDownload;

  const EpisodeTile({
    super.key,
    required this.episodeNumber,
    required this.title,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.onWatch,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDownloading
              ? AppColors.accent.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onWatch,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ─── Episode Number Badge ───────────────────
                _buildNumberBadge(),

                const SizedBox(width: 14),

                // ─── Title ──────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(fontSize: 14),
                      ),
                      if (isDownloading) ...[
                        const SizedBox(height: 6),
                        _buildProgressBar(),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ─── Action Buttons ─────────────────────────
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberBadge() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: isDownloaded
            ? const LinearGradient(
                colors: [AppColors.success, Color(0xFF059669)],
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '$episodeNumber',
          style: AppTextStyles.number.copyWith(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: downloadProgress,
        backgroundColor: AppColors.surfaceLight,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
        minHeight: 4,
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Watch button
        IconButton(
          icon: const Icon(Icons.play_circle_outline, size: 26),
          color: AppColors.primaryLight,
          onPressed: onWatch,
          tooltip: 'مشاهدة',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),

        // Download button
        if (!isDownloaded)
          IconButton(
            icon: isDownloading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: downloadProgress > 0 ? downloadProgress : null,
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  )
                : const Icon(Icons.download_outlined, size: 24),
            color: AppColors.accent,
            onPressed: isDownloading ? null : onDownload,
            tooltip: 'تحميل',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          )
        else
          const Icon(
            Icons.download_done,
            color: AppColors.success,
            size: 22,
          ),
      ],
    );
  }
}
