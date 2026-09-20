import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../download/download_task.dart';

/// ─── Download Progress Tile ────────────────────────────────────────
///
/// Shows a download task's progress with animated progress bar,
/// file size info, and status indicators.
class DownloadProgressTile extends StatelessWidget {
  final DownloadProgress progress;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final VoidCallback? onPlay;

  const DownloadProgressTile({
    super.key,
    required this.progress,
    this.onRetry,
    this.onCancel,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _statusBorderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Row ─────────────────────────────────
          Row(
            children: [
              _buildStatusIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.task.episodeTitle.isNotEmpty
                          ? progress.task.episodeTitle
                          : 'الحلقة ${progress.task.episodeNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusText,
                      style: AppTextStyles.caption.copyWith(
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              _buildActionButton(),
            ],
          ),

          // ─── Progress Bar ───────────────────────────────
          if (progress.status == DownloadStatus.downloading ||
              progress.status == DownloadStatus.retrying) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.progress),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_statusColor),
                    minHeight: 5,
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progress.progressPercent,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                    fontFamily: AppTextStyles.latinFont,
                  ),
                ),
                if (progress.sizeInfo.isNotEmpty)
                  Text(
                    progress.sizeInfo,
                    style: AppTextStyles.caption.copyWith(
                      fontFamily: AppTextStyles.latinFont,
                    ),
                  ),
              ],
            ),
          ],

          // ─── Error Message ──────────────────────────────
          if (progress.error != null &&
              progress.status == DownloadStatus.failed) ...[
            const SizedBox(height: 8),
            Text(
              progress.error!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    switch (progress.status) {
      case DownloadStatus.queued:
        icon = Icons.hourglass_top_rounded;
        break;
      case DownloadStatus.starting:
        icon = Icons.sync_rounded;
        break;
      case DownloadStatus.downloading:
        icon = Icons.downloading_rounded;
        break;
      case DownloadStatus.completed:
        icon = Icons.check_circle_rounded;
        break;
      case DownloadStatus.failed:
        icon = Icons.error_outline_rounded;
        break;
      case DownloadStatus.retrying:
        icon = Icons.refresh_rounded;
        break;
      case DownloadStatus.cancelled:
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: _statusColor, size: 22),
    );
  }

  Widget _buildActionButton() {
    switch (progress.status) {
      case DownloadStatus.downloading:
      case DownloadStatus.starting:
      case DownloadStatus.queued:
        return IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          color: AppColors.textMuted,
          onPressed: onCancel,
          tooltip: 'إلغاء',
        );
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 22),
          color: AppColors.warning,
          onPressed: onRetry,
          tooltip: 'إعادة المحاولة',
        );
      case DownloadStatus.completed:
        return IconButton(
          icon: const Icon(Icons.play_circle_filled, size: 26),
          color: AppColors.success,
          onPressed: onPlay,
          tooltip: 'تشغيل',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Color get _statusColor {
    switch (progress.status) {
      case DownloadStatus.queued:
        return AppColors.textMuted;
      case DownloadStatus.starting:
      case DownloadStatus.downloading:
        return AppColors.accent;
      case DownloadStatus.completed:
        return AppColors.success;
      case DownloadStatus.failed:
        return AppColors.error;
      case DownloadStatus.retrying:
        return AppColors.warning;
      case DownloadStatus.cancelled:
        return AppColors.textMuted;
    }
  }

  Color get _statusBorderColor => _statusColor;

  String get _statusText {
    switch (progress.status) {
      case DownloadStatus.queued:
        return 'في قائمة الانتظار';
      case DownloadStatus.starting:
        return 'جاري البدء...';
      case DownloadStatus.downloading:
        return 'جاري التحميل';
      case DownloadStatus.completed:
        return 'اكتمل التحميل';
      case DownloadStatus.failed:
        return 'فشل التحميل';
      case DownloadStatus.retrying:
        return 'إعادة المحاولة (${progress.task.retryCount})';
      case DownloadStatus.cancelled:
        return 'تم الإلغاء';
    }
  }
}
