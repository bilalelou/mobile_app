import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants.dart';
import 'download_task.dart';

/// Sequential download manager with retry and resume support
///
/// Downloads episodes one at a time to avoid:
/// - Server rate limiting
/// - Network congestion
/// - IP bans from parallel connections
///
/// Features:
/// - Sequential queue (no overlap)
/// - Automatic retry with exponential backoff
/// - Progress reporting via Stream
/// - Polite delays between downloads
class DownloadManager {
  final Queue<DownloadTask> _queue = Queue();
  DownloadTask? _currentTask;
  bool _isRunning = false;
  bool _cancelRequested = false;
  final int maxRetries;
  CancelToken? _currentCancelToken;

  // Progress stream
  final _progressController = StreamController<DownloadProgress>.broadcast();
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  // Stats
  int _completedCount = 0;
  int _failedCount = 0;
  int get completedCount => _completedCount;
  int get failedCount => _failedCount;
  int get queuedCount => _queue.length;
  bool get isRunning => _isRunning;

  DownloadManager({this.maxRetries = kMaxDownloadRetries});

  /// Add a single task to the queue
  void enqueue(DownloadTask task) {
    _queue.add(task);
    _emit(task, DownloadStatus.queued, 0.0);
    if (!_isRunning) _processQueue();
  }

  /// Add multiple tasks to the queue
  void enqueueAll(List<DownloadTask> tasks) {
    for (final task in tasks) {
      _queue.add(task);
      _emit(task, DownloadStatus.queued, 0.0);
    }
    if (!_isRunning) _processQueue();
  }

  /// Process the queue sequentially
  Future<void> _processQueue() async {
    _isRunning = true;
    _cancelRequested = false;

    while (_queue.isNotEmpty && !_cancelRequested) {
      _currentTask = _queue.removeFirst();
      final task = _currentTask!;

      _emit(task, DownloadStatus.starting, 0.0);

      bool success = false;
      int attempt = 0;

      while (!success && attempt < maxRetries && !_cancelRequested) {
        attempt++;
        task.retryCount = attempt;

        try {
          await _downloadFile(task);
          success = true;
          _completedCount++;
          _emit(task, DownloadStatus.completed, 1.0);
          print('  ✅ Episode ${task.episodeNumber} downloaded successfully');
        } catch (e) {
          if (_cancelRequested) break;

          if (attempt < maxRetries) {
            final waitSec = 5 * attempt; // Exponential backoff: 5s, 10s, 15s
            _emit(task, DownloadStatus.retrying, 0.0,
                error: 'Attempt $attempt/$maxRetries failed: $e. Retrying in ${waitSec}s...');
            print('  ⚠️  Attempt $attempt failed for EP ${task.episodeNumber}: $e');
            print('      Retrying in $waitSec seconds...');
            await Future.delayed(Duration(seconds: waitSec));
          } else {
            _failedCount++;
            _emit(task, DownloadStatus.failed, 0.0,
                error: 'All $maxRetries attempts failed: $e');
            print('  ❌ Episode ${task.episodeNumber} FAILED after $maxRetries attempts: $e');
          }
        }
      }

      // Polite delay between downloads
      if (_queue.isNotEmpty && !_cancelRequested) {
        print('  ⏳ Waiting ${kBetweenDownloadDelaySec}s before next download...');
        await Future.delayed(Duration(seconds: kBetweenDownloadDelaySec));
      }
    }

    _isRunning = false;
    _currentTask = null;
    print('\n📊 Download session complete: '
        '$_completedCount succeeded, $_failedCount failed, '
        '${_queue.length} remaining in queue');
  }

  /// Download a single file using Dio with progress tracking
  Future<void> _downloadFile(DownloadTask task) async {
    // Ensure the directory exists
    final dir = Directory(task.savePath.substring(
      0,
      task.savePath.lastIndexOf(Platform.pathSeparator.isEmpty ? '/' : Platform.pathSeparator),
    ));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    _currentCancelToken = CancelToken();

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 30), // Large files
      headers: {
        'User-Agent': getRandomUserAgent(),
        if (task.referer != null) 'Referer': task.referer!,
      },
    ));

    try {
      // Check if partial download exists (for resume)
      final file = File(task.savePath);
      int downloadedBytes = 0;
      if (file.existsSync()) {
        downloadedBytes = file.lengthSync();
        if (downloadedBytes > 0) {
          print('  📥 Resuming from ${(downloadedBytes / 1024 / 1024).toStringAsFixed(1)} MB');
        }
      }

      await dio.download(
        task.directUrl,
        task.savePath,
        cancelToken: _currentCancelToken,
        deleteOnError: false, // Keep partial file for resume
        options: Options(
          headers: downloadedBytes > 0
              ? {'Range': 'bytes=$downloadedBytes-'}
              : null,
        ),
        onReceiveProgress: (received, total) {
          final actualReceived = received + downloadedBytes;
          final actualTotal = total > 0 ? total + downloadedBytes : -1;
          if (actualTotal > 0) {
            _emit(
              task,
              DownloadStatus.downloading,
              actualReceived / actualTotal,
              bytesReceived: actualReceived,
              totalBytes: actualTotal,
            );
          }
        },
      );
    } finally {
      dio.close();
    }
  }

  /// Cancel the current download and clear the queue
  void cancelAll() {
    _cancelRequested = true;
    _currentCancelToken?.cancel('Download cancelled by user');
    _queue.clear();
    if (_currentTask != null) {
      _emit(_currentTask!, DownloadStatus.cancelled, 0.0);
    }
  }

  /// Emit a progress update
  void _emit(DownloadTask task, DownloadStatus status, double progress,
      {String? error, int bytesReceived = 0, int totalBytes = 0}) {
    _progressController.add(DownloadProgress(
      task: task,
      status: status,
      progress: progress,
      bytesReceived: bytesReceived,
      totalBytes: totalBytes,
      error: error,
    ));
  }

  void dispose() {
    cancelAll();
    _progressController.close();
  }
}
