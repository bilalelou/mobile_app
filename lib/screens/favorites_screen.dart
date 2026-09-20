import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/favorites_service.dart';
import '../models/anime.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/anime_card.dart';
import 'anime_details_screen.dart';

/// ─── Favorites Screen ──────────────────────────────────────────────
///
/// Displays the user's saved favorite anime in a grid.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  void _onAnimeSelected(BuildContext context, FavoriteAnime anime) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimeDetailsScreen(
          animeUrl: anime.url,
          title: anime.title,
          posterUrl: anime.posterUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
      ),
      body: Consumer<FavoritesService>(
        builder: (context, service, _) {
          if (service.favorites.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.58,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: service.favorites.length,
            itemBuilder: (context, index) {
              final anime = service.favorites[index];
              return Stack(
                children: [
                  AnimeCard(
                    title: anime.title,
                    posterUrl: anime.posterUrl,
                    type: anime.type,
                    onTap: () => _onAnimeSelected(context, anime),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        service.removeFavorite(anime.url);
                      },
                    ),
                  ),
                ],
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
            Icons.favorite_border_rounded,
            size: 80,
            color: AppColors.textMuted.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد مفضلات',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'احفظ الأنمي المفضل لديك للرجوع إليه لاحقاً',
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}
