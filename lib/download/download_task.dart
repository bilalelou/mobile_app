/// Represents a single download task in the queue
class DownloadTask {
  final int episodeNumber;
  final String episodeTitle;
  final String directUrl;
  final String savePath;
  final String? referer;
  int retryCount;

  DownloadTask({
    required this.episodeNumber,
    required this.directUrl,
    required this.savePath,
    this.episodeTitle = '',
    this.referer,
    this.retryCount = 0,
  });

  @override
  String toString() =>
      'DownloadTask(EP $episodeNumber → $savePath)';
}

/// Download status enum
enum DownloadStatus {
  queued,
  starting,
  downloading,
  completed,
  failed,
  retrying,
  cancelled,
}

/// Progress update for a download task
class DownloadProgress {
  final DownloadTask task;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final int bytesReceived;
  final int totalBytes;
  final String? error;

  DownloadProgress({
    required this.task,
    required this.status,
    required this.progress,
    this.bytesReceived = 0,
    this.totalBytes = 0,
    this.error,
  });

  String get progressPercent => '${(progress * 100).toStringAsFixed(1)}%';

  String get sizeInfo {
    if (totalBytes <= 0) return '';
    final receivedMB = (bytesReceived / 1024 / 1024).toStringAsFixed(1);
    final totalMB = (totalBytes / 1024 / 1024).toStringAsFixed(1);
    return '$receivedMB / $totalMB MB';
  }
}
