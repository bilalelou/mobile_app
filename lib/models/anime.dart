/// Represents an anime search result
class AnimeSearchResult {
  final String title;
  final String url;
  final String posterUrl;
  final String? type; // TV, Movie, OVA, etc.
  final String? status; // Ongoing, Completed

  AnimeSearchResult({
    required this.title,
    required this.url,
    this.posterUrl = '',
    this.type,
    this.status,
  });

  @override
  String toString() => 'AnimeSearchResult(title: $title, url: $url)';
}

/// Represents full anime details with episodes
class AnimeDetails {
  final String title;
  final String? description;
  final String? posterUrl;
  final String? type;
  final String? status;
  final List<String> genres;
  final List<Episode> episodes;

  AnimeDetails({
    required this.title,
    required this.episodes,
    this.description,
    this.posterUrl,
    this.type,
    this.status,
    this.genres = const [],
  });

  @override
  String toString() =>
      'AnimeDetails(title: $title, episodes: ${episodes.length})';
}

/// Represents a single episode
class Episode {
  final int number;
  final String title;
  final String url;

  Episode({
    required this.number,
    required this.title,
    required this.url,
  });

  @override
  String toString() => 'Episode(#$number: $title)';
}

/// Represents a video source from an embedded player
class VideoSource {
  final String serverName;
  final String embedUrl;
  final String quality;
  final String? directUrl; // Resolved later

  VideoSource({
    required this.serverName,
    required this.embedUrl,
    this.quality = 'unknown',
    this.directUrl,
  });

  VideoSource copyWithDirectUrl(String url) => VideoSource(
        serverName: serverName,
        embedUrl: embedUrl,
        quality: quality,
        directUrl: url,
      );

  @override
  String toString() =>
      'VideoSource(server: $serverName, quality: $quality)';
}
