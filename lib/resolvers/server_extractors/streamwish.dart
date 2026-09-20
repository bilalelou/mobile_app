import '../../core/http_client.dart';
import '../server_extractor.dart';
import '../js_unpacker.dart';

/// Extractor for StreamWish / Filelions embedded player
///
/// StreamWish typically serves HLS (m3u8) streams.
/// The m3u8 URL is usually hidden in packed JavaScript.
class StreamWishExtractor extends ServerExtractor {
  StreamWishExtractor(AppHttpClient client) : super(client);

  @override
  List<String> get hostPatterns => [
        'streamwish',
        'filelions',
        'swdyu',
        'awish',
        'obeywish',
        'sfastwish',
      ];

  @override
  Future<String?> extract(String embedUrl) async {
    try {
      final html = await client.getHtml(embedUrl);

      // Strategy 1: Unpack eval'd JS
      final packedMatch = RegExp(
        r"eval\(function\(p,a,c,k,e,d\)\{.*?\}\('(.*?)',(\d+),(\d+),'(.*?)'\.split",
        dotAll: true,
      ).firstMatch(html);

      if (packedMatch != null) {
        final unpacked = JsUnpacker.unpack(packedMatch.group(0)!);
        if (unpacked != null) {
          // Look for m3u8 URL
          final m3u8Match = RegExp(
            r'''(?:src|file|source)\s*[:=]\s*["\']?(https?://[^"\'>\s]+\.m3u8[^"\'>\s]*)["\']?''',
          ).firstMatch(unpacked);
          if (m3u8Match != null) return m3u8Match.group(1);

          // Fallback: look for mp4
          final mp4Match = RegExp(
            r'''(?:src|file|source)\s*[:=]\s*["\']?(https?://[^"\'>\s]+\.mp4[^"\'>\s]*)["\']?''',
          ).firstMatch(unpacked);
          if (mp4Match != null) return mp4Match.group(1);
        }
      }

      // Strategy 2: Direct regex in raw HTML
      final directMatch = RegExp(
        r'''(?:file|src|source)\s*[:=]\s*["\']?(https?://[^"\'>\s]+\.(?:m3u8|mp4)[^"\'>\s]*)["\']?''',
      ).firstMatch(html);
      if (directMatch != null) return directMatch.group(1);

      return null;
    } catch (e) {
      print('  ⚠️  StreamWish extraction failed: $e');
      return null;
    }
  }
}
