import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/anime_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/download_progress_tile.dart';

/// ─── Downloads Screen ──────────────────────────────────────────────
///
/// Displays the list of current and completed downloads.
/// Uses the AnimeService's downloader progress stream.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحميلات'),
      ),
      body: Consumer<AnimeService>(
        builder: (context, service, _) {
          return StreamBuilder(
            stream: service.downloadProgress,
            builder: (context, snapshot) {
              // Get current state from downloader queue and history
              // For a complete app, we'd want to store history in Hive/DB.
              // Here we're just displaying active progress events from the stream.
              
              if (!snapshot.hasData && service.downloader.queuedCount == 0) {
                return _buildEmptyState();
              }
              
              // Simplistic representation, typically we'd maintain a list
              // of all active tasks in AnimeService or DownloadManager
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.download_rounded,
                        size: 64,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'جاري تتبع التحميلات النشطة...',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'في طابور التحميل: ${service.downloader.queuedCount}\nاكتمل: ${service.downloader.completedCount}\nفشل: ${service.downloader.failedCount}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary,
                      ),
                      if (snapshot.hasData) ...[
                        const SizedBox(height: 24),
                        DownloadProgressTile(
                          progress: snapshot.data!,
                          onCancel: () => service.cancelAllDownloads(),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_done_rounded,
            size: 80,
            color: AppColors.textMuted.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تحميلات',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'حلقات الأنمي المحملة ستظهر هنا',
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}
