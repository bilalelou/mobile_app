import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/anime_service.dart';
import '../models/anime.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/anime_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/shimmer_loading.dart';
import 'anime_details_screen.dart';

/// ─── Home Screen ───────────────────────────────────────────────────
///
/// Main search and browse screen with glassmorphism search bar
/// and animated grid of anime results.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<AnimeService>().search(query);
    }
  }

  void _onAnimeSelected(AnimeSearchResult anime) {
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
    super.build(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ───────────────────────────────────
              _buildHeader(),

              // ─── Search Bar ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppSearchBar(
                  controller: _searchController,
                  onSearch: _onSearch,
                ),
              ),

              const SizedBox(height: 16),

              // ─── Results ──────────────────────────────────
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo / App icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أنمي قراب',
                    style: AppTextStyles.h2.copyWith(fontSize: 24),
                  ),
                  Text(
                    'ابحث وشاهد أنمي مترجم',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<AnimeService>(
      builder: (context, service, _) {
        // Loading state
        if (service.isSearching) {
          return const ShimmerGrid();
        }

        // Error state
        if (service.errorMessage != null && service.searchResults.isEmpty) {
          return _buildEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'حدث خطأ',
            subtitle: service.errorMessage!,
            iconColor: AppColors.error,
          );
        }

        // Results
        if (service.searchResults.isNotEmpty) {
          return _buildSearchResults(service.searchResults);
        }

        // Initial empty state
        return _buildEmptyState(
          icon: Icons.movie_filter_outlined,
          title: 'ابحث عن أنمي',
          subtitle: 'اكتب اسم الأنمي في شريط البحث\nلبدء الاستكشاف',
        );
      },
    );
  }

  Widget _buildSearchResults(List<AnimeSearchResult> results) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final anime = results[index];
        return _AnimatedCard(
          index: index,
          child: AnimeCard(
            title: anime.title,
            posterUrl: anime.posterUrl,
            type: anime.type,
            onTap: () => _onAnimeSelected(anime),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor ?? AppColors.textMuted.withOpacity(0.4),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Staggered fade-in animation for grid cards
class _AnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedCard({required this.index, required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Staggered delay based on index
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
