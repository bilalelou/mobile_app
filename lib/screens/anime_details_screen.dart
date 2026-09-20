import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/anime_service.dart';
import '../services/favorites_service.dart';
import '../models/anime.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/episode_tile.dart';
import '../widgets/shimmer_loading.dart';
import 'player_screen.dart';

/// ─── Anime Details Screen ──────────────────────────────────────────
///
/// Full anime details page with:
/// - Blurred poster backdrop header
/// - Title, description, genre chips
/// - Episode list with watch/download buttons
/// - Favorite toggle
class AnimeDetailsScreen extends StatefulWidget {
  final String animeUrl;
  final String title;
  final String posterUrl;

  const AnimeDetailsScreen({
    super.key,
    required this.animeUrl,
    required this.title,
    this.posterUrl = '',
  });

  @override
  State<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends State<AnimeDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Load anime details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimeService>().loadAnimeDetails(widget.animeUrl);
    });
  }

  void _onWatchEpisode(Episode episode) async {
    final service = context.read<AnimeService>();

    // Show loading dialog
    _showLoadingDialog('جاري جلب سيرفرات الحلقة ${episode.number}...');

    final sources = await service.getVideoSources(episode.url);
    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    if (sources.isEmpty) {
      _showSnackBar('لم يتم العثور على سيرفرات لهذه الحلقة', isError: true);
      return;
    }

    // Navigate to player
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          episode: episode,
          sources: sources,
          animeTitle: widget.title,
        ),
      ),
    );
  }

  void _onDownloadEpisode(Episode episode) async {
    final service = context.read<AnimeService>();

    _showSnackBar('جاري تحليل رابط الحلقة ${episode.number}...');

    final sources = await service.getVideoSources(episode.url);
    if (!mounted) return;

    if (sources.isEmpty) {
      _showSnackBar('لم يتم العثور على سيرفرات للتحميل', isError: true);
      return;
    }

    final directUrl = await service.resolveFirstWorking(sources);
    if (!mounted) return;

    if (directUrl == null) {
      _showSnackBar('فشل فك رابط التحميل. جرب سيرفر آخر', isError: true);
      return;
    }

    // Start download
    service.startDownload(
      episodeNumber: episode.number,
      episodeTitle: '${widget.title} - الحلقة ${episode.number}',
      directUrl: directUrl,
      savePath: 'downloads/${widget.title}/EP${episode.number}.mp4',
    );

    _showSnackBar('تمت إضافة الحلقة ${episode.number} لقائمة التحميل ✅');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AnimeService>(
        builder: (context, service, _) {
          if (service.isLoadingDetails) {
            return _buildLoadingState();
          }

          if (service.errorMessage != null && service.currentAnime == null) {
            return _buildErrorState(service.errorMessage!);
          }

          final anime = service.currentAnime;
          if (anime == null) {
            return _buildLoadingState();
          }

          return _buildContent(anime);
        },
      ),
    );
  }

  Widget _buildContent(AnimeDetails anime) {
    return CustomScrollView(
      slivers: [
        // ─── Header with blurred backdrop ──────────────
        _buildSliverHeader(anime),

        // ─── Info Section ──────────────────────────────
        SliverToBoxAdapter(child: _buildInfoSection(anime)),

        // ─── Episode List ──────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'الحلقات (${anime.episodes.length})',
                  style: AppTextStyles.h3,
                ),
              ],
            ),
          ),
        ),

        // ─── Episode Items ─────────────────────────────
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final episode = anime.episodes[index];
              return EpisodeTile(
                episodeNumber: episode.number,
                title: episode.title,
                onWatch: () => _onWatchEpisode(episode),
                onDownload: () => _onDownloadEpisode(episode),
              );
            },
            childCount: anime.episodes.length,
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildSliverHeader(AnimeDetails anime) {
    final posterUrl = anime.posterUrl ?? widget.posterUrl;

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.surface,
      leading: _buildBackButton(),
      actions: [_buildFavoriteButton()],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred background poster
            if (posterUrl.isNotEmpty)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Image.network(
                  posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceLight,
                  ),
                ),
              ),

            // Dark overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withOpacity(0.4),
                    AppColors.background.withOpacity(0.85),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),

            // Poster + Title overlay
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Poster thumbnail
                  if (posterUrl.isNotEmpty)
                    Hero(
                      tag: 'poster_${widget.animeUrl}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          posterUrl,
                          width: 100,
                          height: 145,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100,
                            height: 145,
                            color: AppColors.surfaceLight,
                            child: const Icon(Icons.movie_outlined,
                                color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          anime.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h2,
                        ),
                        if (anime.type != null || anime.status != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (anime.type != null)
                                _buildInfoChip(anime.type!, Icons.tv_rounded),
                              if (anime.status != null) ...[
                                const SizedBox(width: 8),
                                _buildInfoChip(
                                    anime.status!, Icons.circle, 8),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(AnimeDetails anime) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Genres ─────────────────────────────────
          if (anime.genres.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: anime.genres.map((genre) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(genre, style: AppTextStyles.chip),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // ─── Description ────────────────────────────
          if (anime.description != null &&
              anime.description!.isNotEmpty) ...[
            Text(
              anime.description!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySecondary.copyWith(height: 1.7),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, [double? iconSize]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize ?? 14, color: AppColors.primaryLight),
          const SizedBox(width: 4),
          Text(text, style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          )),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Consumer<FavoritesService>(
      builder: (context, favService, _) {
        final isFav = favService.isFavorite(widget.animeUrl);
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  key: ValueKey(isFav),
                  color: isFav ? AppColors.error : AppColors.textPrimary,
                ),
              ),
              onPressed: () {
                final anime = context.read<AnimeService>().currentAnime;
                if (anime != null) {
                  favService.addFromDetails(anime, widget.animeUrl);
                  if (!isFav) {
                    favService.toggleFavorite(AnimeSearchResult(
                      title: '', url: '', // dummy, addFromDetails handles it
                    ));
                  }
                }
                // Simple toggle using search result format
                favService.toggleFavorite(AnimeSearchResult(
                  title: widget.title,
                  url: widget.animeUrl,
                  posterUrl: widget.posterUrl,
                ));
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              leading: _buildBackButton(),
            ),
            const Expanded(child: ShimmerList(itemCount: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              leading: _buildBackButton(),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 60, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(error,
                          style: AppTextStyles.bodySecondary,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => context
                            .read<AnimeService>()
                            .loadAnimeDetails(widget.animeUrl),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(message, style: AppTextStyles.body),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.body.copyWith(fontSize: 13),
        ),
        backgroundColor:
            isError ? AppColors.error.withOpacity(0.9) : AppColors.surfaceLight,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
}
