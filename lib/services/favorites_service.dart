import 'package:flutter/foundation.dart';
import '../models/anime.dart';

/// ─── Favorites Service ─────────────────────────────────────────────
///
/// Manages the user's favorite anime list with in-memory storage.
/// Uses ChangeNotifier for reactive UI updates.
/// Can be extended later with Hive or SharedPreferences for persistence.
class FavoritesService extends ChangeNotifier {
  final List<FavoriteAnime> _favorites = [];

  List<FavoriteAnime> get favorites => List.unmodifiable(_favorites);
  int get count => _favorites.length;

  /// Check if an anime URL is in favorites
  bool isFavorite(String animeUrl) {
    return _favorites.any((f) => f.url == animeUrl);
  }

  /// Toggle favorite status for an anime
  void toggleFavorite(AnimeSearchResult anime) {
    final index = _favorites.indexWhere((f) => f.url == anime.url);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(FavoriteAnime(
        title: anime.title,
        url: anime.url,
        posterUrl: anime.posterUrl,
        type: anime.type,
        addedAt: DateTime.now(),
      ));
    }
    notifyListeners();
  }

  /// Add to favorites from anime details
  void addFromDetails(AnimeDetails details, String url) {
    if (isFavorite(url)) return;
    _favorites.add(FavoriteAnime(
      title: details.title,
      url: url,
      posterUrl: details.posterUrl ?? '',
      type: details.type,
      addedAt: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Remove a favorite by URL
  void removeFavorite(String animeUrl) {
    _favorites.removeWhere((f) => f.url == animeUrl);
    notifyListeners();
  }

  /// Clear all favorites
  void clearAll() {
    _favorites.clear();
    notifyListeners();
  }
}

/// Model for a saved favorite anime
class FavoriteAnime {
  final String title;
  final String url;
  final String posterUrl;
  final String? type;
  final DateTime addedAt;

  FavoriteAnime({
    required this.title,
    required this.url,
    this.posterUrl = '',
    this.type,
    required this.addedAt,
  });
}
