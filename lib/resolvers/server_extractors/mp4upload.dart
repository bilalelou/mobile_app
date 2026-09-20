import '../../core/http_client.dart';
import '../server_extractor.dart';
import '../js_unpacker.dart';

/// Extractor for Mp4Upload embedded player
///
/// Mp4Upload typically uses packed JavaScript (eval/p,a,c,k,e,d)
/// that contains the direct mp4 URL when unpacked.
class Mp4UploadExtractor extends ServerExtractor {
  Mp4UploadExtractor(AppHttpClient client) : super(client);

  @override
  List<String> get hostPatterns => ['mp4upload', 'mp4up'];

  @override
  Future<String?> extract(String embedUrl) async {
    try {
      final html = await client.getHtml(embedUrl);

      // Strategy 1: Look for packed JS and unpack it
      final packedMatch = RegExp(
        r"eval\(function\(p,a,c,k,e,d\)\{.*?\}\('(.*?)',(\d+),(\d+),'(.*?)'\.split",
        dotAll: true,
      ).firstMatch(html);

      if (packedMatch != null) {
        final unpacked = JsUnpacker.unpack(packedMatch.group(0)!);
        if (unpacked != null) {
          // Find the video URL in unpacked JS
          final urlMatch = RegExp(
            r'''(?:src|file|player\.src)\s*(?:\(|\=)\s*["']?(https?://[^"'>\s]+\.mp4[^"'>\s]*)["']?''',
          ).firstMatch(unpacked);
          if (urlMatch != null) return urlMatch.group(1);
        }
      }

      // Strategy 2: Direct source tag
      final sourceMatch = RegExp(
        r'<source\s+[^>]*src=["' + "'" + r']([^"' + "'" + r']+\.mp4[^"' + "'" + r']*)["' + "'" + r']',
      ).firstMatch(html);
      if (sourceMatch != null) return sourceMatch.group(1);

      // Strategy 3: player.src("url")
      final playerMatch = RegExp(
        r'''player\.src\(\s*["']([^"']+\.mp4[^"']*)["']''',
      ).firstMatch(html);
      if (playerMatch != null) return playerMatch.group(1);

      return null;
    } catch (e) {
      print('  ⚠️  Mp4Upload extraction failed: $e');
      return null;
    }
  }
}
