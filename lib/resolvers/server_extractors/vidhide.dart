import '../../core/http_client.dart';
import '../server_extractor.dart';
import '../js_unpacker.dart';

/// Extractor for VidHide / VidHD embedded player
///
/// VidHide uses a combination of packed JS and sometimes
/// requires a POST request to resolve the final video URL.
class VidHideExtractor extends ServerExtractor {
  VidHideExtractor(AppHttpClient client) : super(client);

  @override
  List<String> get hostPatterns => [
        'vidhide',
        'vidhd',
        'vid-hide',
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
          // Look for m3u8 or mp4 URL
          final urlMatch = RegExp(
            r'''(?:src|file|source)\s*[:=]\s*["\']?(https?://[^"\'>\s]+\.(?:m3u8|mp4)[^"\'>\s]*)["\']?''',
          ).firstMatch(unpacked);
          if (urlMatch != null) return urlMatch.group(1);
        }
      }

      // Strategy 2: Direct source/file in HTML
      final directMatch = RegExp(
        r'''<source\s+[^>]*src=["\']([^"\']+\.(?:mp4|m3u8)[^"\']*)["\']''',
      ).firstMatch(html);
      if (directMatch != null) return directMatch.group(1);

      // Strategy 3: sources array in JS
      final sourcesMatch = RegExp(
        r'''sources\s*[:=]\s*\[\s*\{\s*(?:file|src)\s*:\s*["\']([^"\']+)["\']''',
      ).firstMatch(html);
      if (sourcesMatch != null) return sourcesMatch.group(1);

      return null;
    } catch (e) {
      print('  ⚠️  VidHide extraction failed: $e');
      return null;
    }
  }
}
