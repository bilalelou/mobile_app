import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../services/anime_service.dart';
import '../models/anime.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// ─── Player Screen ─────────────────────────────────────────────────
///
/// Full-screen video player with:
/// - Server selection dropdown
/// - Auto-fallback to next server on failure
/// - Chewie controls (seek, volume, fullscreen)
class PlayerScreen extends StatefulWidget {
  final Episode episode;
  final List<VideoSource> sources;
  final String animeTitle;

  const PlayerScreen({
    super.key,
    required this.episode,
    required this.sources,
    required this.animeTitle,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;
  int _currentSourceIndex = 0;
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    // Force landscape for video
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    _initializePlayer();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    // Restore portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final service = context.read<AnimeService>();

    // Try to resolve current source
    for (int i = _currentSourceIndex; i < widget.sources.length; i++) {
      _currentSourceIndex = i;
      final source = widget.sources[i];

      try {
        final url = await service.resolveVideoUrl(source);
        if (url == null) continue;

        _resolvedUrl = url;

        // Dispose old controllers
        _chewieController?.dispose();
        _videoController?.dispose();

        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(url),
          httpHeaders: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/126.0.0.0 Mobile Safari/537.36',
          },
        );

        await _videoController!.initialize();

        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primaryLight,
            backgroundColor: AppColors.surfaceLight,
            bufferedColor: AppColors.primary.withOpacity(0.3),
          ),
          errorBuilder: (context, errorMessage) {
            return _buildErrorWidget('فشل تشغيل الفيديو: $errorMessage');
          },
        );

        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      } catch (e) {
        debugPrint('⚠️ Server ${source.serverName} failed: $e');
        continue;
      }
    }

    // All servers failed
    if (mounted) {
      setState(() {
        _isLoading = false;
        _error = 'فشل تشغيل جميع السيرفرات المتاحة';
      });
    }
  }

  void _switchServer(int index) {
    _currentSourceIndex = index;
    _initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.background.withOpacity(0.9),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.animeTitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'الحلقة ${widget.episode.number}',
              style: AppTextStyles.body.copyWith(fontSize: 15),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ─── Video Player ─────────────────────────────
          Expanded(
            child: _isLoading
                ? _buildLoadingWidget()
                : _error != null
                    ? _buildErrorWidget(_error!)
                    : _chewieController != null
                        ? Chewie(controller: _chewieController!)
                        : _buildLoadingWidget(),
          ),

          // ─── Server Selector ──────────────────────────
          _buildServerSelector(),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل الفيديو...',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 6),
          Text(
            'سيرفر: ${widget.sources[_currentSourceIndex].serverName}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 50, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _currentSourceIndex = 0;
                _initializePlayer();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerSelector() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('السيرفرات المتاحة:', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.sources.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final source = widget.sources[index];
                final isActive = index == _currentSourceIndex;
                return GestureDetector(
                  onTap: () => _switchServer(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isActive ? AppColors.primaryGradient : null,
                      color: isActive ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? Colors.transparent
                            : AppColors.surfaceLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          source.serverName,
                          style: AppTextStyles.caption.copyWith(
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        if (source.quality != 'unknown') ...[
                          const SizedBox(width: 4),
                          Text(
                            source.quality,
                            style: AppTextStyles.caption.copyWith(
                              color: isActive
                                  ? Colors.white70
                                  : AppColors.textMuted,
                              fontSize: 10,
                              fontFamily: AppTextStyles.latinFont,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
