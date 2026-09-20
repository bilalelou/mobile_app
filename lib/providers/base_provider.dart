import '../models/anime.dart';

/// Abstract provider interface — each anime site implements this
abstract class BaseProvider {
  /// Human-readable name of this provider
  String get name;

  /// Current base URL (configurable for domain changes)
  String get baseUrl;

  /// Update the base URL (when domain changes)
  set baseUrl(String url);

  /// Search for anime by name
  /// Returns a list of search results with titles and URLs
  Future<List<AnimeSearchResult>> search(String query);

  /// Load full anime details including episode list
  /// [animeUrl] is the URL from a search result
  Future<AnimeDetails> loadAnimeDetails(String animeUrl);

  /// Extract video sources (embedded player URLs) for a specific episode
  /// [episodeUrl] is the URL from the episode list
  Future<List<VideoSource>> getVideoSources(String episodeUrl);
}
