import '../core/http_client.dart';

/// Base class for server-specific video URL extractors
abstract class ServerExtractor {
  final AppHttpClient client;
  ServerExtractor(this.client);

  /// The hostname patterns this extractor handles
  List<String> get hostPatterns;

  /// Extract a direct video URL from an embed page URL
  /// Returns null if extraction fails
  Future<String?> extract(String embedUrl);

  /// Check if this extractor can handle the given URL
  bool canHandle(String url) {
    final lower = url.toLowerCase();
    return hostPatterns.any((pattern) => lower.contains(pattern));
  }
}
