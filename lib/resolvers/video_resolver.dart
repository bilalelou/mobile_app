import '../core/http_client.dart';
import '../models/anime.dart';
import 'server_extractor.dart';
import 'server_extractors/mp4upload.dart';
import 'server_extractors/streamwish.dart';
import 'server_extractors/vidhide.dart';
import 'js_unpacker.dart';

/// Resolves embed URLs to direct video download URLs
///
/// Uses a registry of server-specific extractors, with a
/// generic fallback for unknown servers.
class VideoResolver {
  final AppHttpClient _client;
  final List<ServerExtractor> _extractors = [];

  VideoResolver(this._client) {
    // Register known server extractors
    _extractors.add(Mp4UploadExtractor(_client));
    _extractors.add(StreamWishExtractor(_client));
    _extractors.add(VidHideExtractor(_client));
  }

  /// Resolve a VideoSource's embed URL to a direct download URL
  /// Returns the direct URL, or null if all extraction methods fail
  Future<String?> resolve(VideoSource source) async {
    final embedUrl = source.embedUrl;

    // Skip obviously non-video URLs
    if (embedUrl.isEmpty ||
        embedUrl.startsWith('#') ||
        embedUrl.startsWith('javascript:')) {
      return null;
    }

    // Check if it's already a direct video URL
    if (_isDirectVideoUrl(embedUrl)) {
      return embedUrl;
    }

    // 1. Try matching a known server extractor
    for (final extractor in _extractors) {
      if (extractor.canHandle(embedUrl)) {
        print('  🔧 Using ${extractor.runtimeType} for $embedUrl');
        final result = await extractor.extract(embedUrl);
        if (result != null) return result;
      }
    }

    // 2. Fallback: generic extraction
    print('  🔧 Using generic extractor for $embedUrl');
    return await _genericExtract(embedUrl);
  }

  /// Try to resolve the first working source from a list
  Future<String?> resolveFirst(List<VideoSource> sources) async {
    for (final source in sources) {
      final directUrl = await resolve(source);
      if (directUrl != null) {
        print('  ✅ Resolved via ${source.serverName}: $directUrl');
        return directUrl;
      }
      print('  ❌ Failed to resolve: ${source.serverName}');
    }
    return null;
  }

  /// Generic extraction — works for many simple servers
  Future<String?> _genericExtract(String embedUrl) async {
    try {
      final html = await _client.getHtml(embedUrl);

      // Pattern 1: Direct <source> tag with mp4
      final sourceMatch = RegExp(
        r'<source[^>]+src=["' + "'" + r']([^"' + "'" + r']+\.mp4[^"' + "'" + r']*)["' + "'" + r']',
      ).firstMatch(html);
      if (sourceMatch != null) return sourceMatch.group(1);

      // Pattern 2: file/src/source = "url" in JavaScript
      final fileMatch = RegExp(
        r'''(?:file|src|source|video_url)\s*[:=]\s*["']([^"']+\.(?:mp4|m3u8)[^"']*)["']''',
      ).firstMatch(html);
      if (fileMatch != null) return fileMatch.group(1);

      // Pattern 3: <video> tag src
      final videoMatch = RegExp(
        r'<video[^>]+src=["' + "'" + r']([^"' + "'" + r']+)["' + "'" + r']',
      ).firstMatch(html);
      if (videoMatch != null) return videoMatch.group(1);

      // Pattern 4: Packed JavaScript
      if (JsUnpacker.isPacked(html)) {
        final packedMatch = RegExp(
          r"eval\(function\(p,a,c,k,e,d\)\{.*?\}\('(.*?)',(\d+),(\d+),'(.*?)'\.split",
          dotAll: true,
        ).firstMatch(html);

        if (packedMatch != null) {
          final unpacked = JsUnpacker.unpack(packedMatch.group(0)!);
          if (unpacked != null) {
            final urlMatch = RegExp(
              r'''(?:src|file|source)\s*[:=]\s*["']?(https?://[^"'>\s]+\.(?:mp4|m3u8)[^"'>\s]*)["']?''',
            ).firstMatch(unpacked);
            if (urlMatch != null) return urlMatch.group(1);
          }
        }
      }

      // Pattern 5: JSON-like sources array
      final jsonMatch = RegExp(
        r'''["'](?:file|src|url)["']\s*:\s*["'](https?://[^"']+\.(?:mp4|m3u8)[^"']*)["']''',
      ).firstMatch(html);
      if (jsonMatch != null) return jsonMatch.group(1);

      // Pattern 6: Any URL ending in .mp4 or .m3u8
      final anyVideoMatch = RegExp(
        r'(https?://[^\s"' + "'" + r'<>]+\.(?:mp4|m3u8)(?:\?[^\s"' + "'" + r'<>]*)?)',
      ).firstMatch(html);
      if (anyVideoMatch != null) return anyVideoMatch.group(1);

      return null;
    } catch (e) {
      print('  ⚠️  Generic extraction failed for $embedUrl: $e');
      return null;
    }
  }

  /// Check if a URL is already a direct video URL
  bool _isDirectVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.m3u8') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.contains('.mp4?') ||
        lower.contains('.m3u8?');
  }
}
