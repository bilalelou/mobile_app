import 'package:html/dom.dart';
import '../core/http_client.dart';
import '../core/html_parser.dart';
import '../models/anime.dart';
import 'base_provider.dart';

/// Witanime provider — scrapes witanime for Arabic-subtitled anime
///
/// Site structure (WordPress-based):
/// - Search:    /?search_param=animes&s=<query>
/// - Anime:     /anime/<slug>/
/// - Episode:   /episode/<slug>/
///
/// NOTE: CSS selectors are calibrated against the live site structure.
/// If the site updates its theme, these may need adjusting.
class WitanimeProvider extends BaseProvider {
  @override
  String get name => 'Witanime';

  String _baseUrl;
  @override
  String get baseUrl => _baseUrl;
  @override
  set baseUrl(String url) => _baseUrl = url;

  final AppHttpClient _client;

  WitanimeProvider(this._client, {String? baseUrl})
      : _baseUrl = baseUrl ?? 'https://witanime.cool';

  // ─── Search ──────────────────────────────────────────────────────────

  @override
  Future<List<AnimeSearchResult>> search(String query) async {
    final url =
        '$_baseUrl/?search_param=animes&s=${Uri.encodeComponent(query)}';
    final html = await _client.getHtml(url);
    final doc = HtmlParser.parse(html);

    final results = <AnimeSearchResult>[];

    // Try multiple possible selectors (site may use different themes)
    final cards = _findSearchCards(doc);

    for (final card in cards) {
      final linkEl = card.querySelector('a');
      final imgEl = card.querySelector('img');

      if (linkEl == null) continue;

      final title = linkEl.attributes['title']?.trim() ??
          linkEl.text.trim();
      final href = linkEl.attributes['href'] ?? '';
      final poster = imgEl?.attributes['src'] ??
          imgEl?.attributes['data-src'] ??
          '';

      if (title.isNotEmpty && href.isNotEmpty) {
        results.add(AnimeSearchResult(
          title: title,
          url: _absoluteUrl(href),
          posterUrl: poster,
        ));
      }
    }

    return results;
  }

  /// Try multiple CSS selectors for the search results grid
  List<Element> _findSearchCards(Document doc) {
    // Selectors ordered by likelihood
    final selectors = [
      '.anime-card-container .hover',
      '.anime-card-container',
      '.anime-card-details',
      '.col-lg-2.col-md-4.col-sm-6.col-6', // Bootstrap grid cards
      'article.post',
      '.search-result-item',
      '.result-item',
    ];

    for (final selector in selectors) {
      final cards = doc.querySelectorAll(selector);
      if (cards.isNotEmpty) return cards;
    }

    // Last resort: find any container that has links to /anime/ paths
    return doc.querySelectorAll('a')
        .where((a) {
          final href = a.attributes['href'] ?? '';
          return href.contains('/anime/') && a.querySelector('img') != null;
        })
        .toList();
  }

  // ─── Load Anime Details ──────────────────────────────────────────────

  @override
  Future<AnimeDetails> loadAnimeDetails(String animeUrl) async {
    final html = await _client.getHtml(_absoluteUrl(animeUrl));
    final doc = HtmlParser.parse(html);

    // Extract title
    final title = HtmlParser.textFrom(doc, '.anime-details h1') ??
        HtmlParser.textFrom(doc, 'h1.title') ??
        HtmlParser.textFrom(doc, 'h1') ??
        'Unknown Anime';

    // Extract description
    final description =
        HtmlParser.textFrom(doc, '.anime-story') ??
        HtmlParser.textFrom(doc, '.anime-description') ??
        HtmlParser.textFrom(doc, '.synopsis');

    // Extract poster
    final posterUrl =
        HtmlParser.attrFrom(doc, '.anime-thumbnail img', 'src') ??
        HtmlParser.attrFrom(doc, '.poster img', 'src') ??
        '';

    // Extract episodes — this is the critical part
    final episodes = _extractEpisodes(doc);

    // Extract genres
    final genres = doc
        .querySelectorAll('.anime-genres a, .genres a')
        .map((e) => e.text.trim())
        .where((g) => g.isNotEmpty)
        .toList();

    return AnimeDetails(
      title: title,
      description: description,
      posterUrl: posterUrl ?? '',
      genres: genres,
      episodes: episodes,
    );
  }

  /// Extract episode list from the anime details page
  List<Episode> _extractEpisodes(Document doc) {
    final episodes = <Episode>[];

    // Try multiple selectors for the episode list
    final episodeSelectors = [
      '.episodes-card-title a',
      '.episodes-list a',
      '.episode-link a',
      'a[href*="/episode/"]',
      '.DivEpisodesList a',
      'ul.episodes-list li a',
      '.ep-list a',
    ];

    List<Element> episodeLinks = [];
    for (final selector in episodeSelectors) {
      episodeLinks = doc.querySelectorAll(selector);
      if (episodeLinks.isNotEmpty) break;
    }

    // If still empty, try a broad search for links containing "episode"
    if (episodeLinks.isEmpty) {
      episodeLinks = doc.querySelectorAll('a').where((a) {
        final href = (a.attributes['href'] ?? '').toLowerCase();
        return href.contains('episode') || href.contains('حلقة');
      }).toList();
    }

    // Deduplicate by URL
    final seenUrls = <String>{};
    int counter = 1;

    for (final el in episodeLinks) {
      final href = el.attributes['href'] ?? '';
      if (href.isEmpty || seenUrls.contains(href)) continue;
      seenUrls.add(href);

      final text = el.text.trim();
      final epNumber = _extractEpisodeNumber(text, href) ?? counter;

      episodes.add(Episode(
        number: epNumber,
        title: text.isNotEmpty ? text : 'الحلقة $epNumber',
        url: _absoluteUrl(href),
      ));
      counter++;
    }

    // Sort by episode number
    episodes.sort((a, b) => a.number.compareTo(b.number));
    return episodes;
  }

  /// Try to extract episode number from text or URL
  int? _extractEpisodeNumber(String text, String href) {
    // Try to find number in the link text
    final textMatch = RegExp(r'(\d+)').firstMatch(text);
    if (textMatch != null) return int.tryParse(textMatch.group(1)!);

    // Try to find number in the URL
    final urlMatch = RegExp(r'episode[/-](\d+)', caseSensitive: false)
        .firstMatch(href);
    if (urlMatch != null) return int.tryParse(urlMatch.group(1)!);

    return null;
  }

  // ─── Get Video Sources ───────────────────────────────────────────────

  @override
  Future<List<VideoSource>> getVideoSources(String episodeUrl) async {
    final html = await _client.getHtml(_absoluteUrl(episodeUrl));
    final doc = HtmlParser.parse(html);

    final sources = <VideoSource>[];

    // Strategy 1: Look for server tabs/buttons with data attributes
    final serverButtons = doc.querySelectorAll(
      '.tab-content a, .server-list a, ul.quality-list li a, '
      'a[data-url], a[data-ep-url], li[data-url] a, '
      '.download-links a, .Quality a',
    );

    for (final btn in serverButtons) {
      final serverName = btn.text.trim();
      final serverUrl = btn.attributes['data-url'] ??
          btn.attributes['data-ep-url'] ??
          btn.attributes['href'] ??
          '';

      if (serverUrl.isNotEmpty &&
          !serverUrl.startsWith('#') &&
          !serverUrl.startsWith('javascript:')) {
        sources.add(VideoSource(
          serverName: serverName.isNotEmpty ? serverName : 'Server',
          embedUrl: _absoluteUrl(serverUrl),
          quality: _inferQuality(serverName),
        ));
      }
    }

    // Strategy 2: Look for iframes (embedded players)
    if (sources.isEmpty) {
      final iframes = HtmlParser.allIframeSrcs(doc);
      for (int i = 0; i < iframes.length; i++) {
        sources.add(VideoSource(
          serverName: 'Server ${i + 1}',
          embedUrl: _absoluteUrl(iframes[i]),
          quality: 'unknown',
        ));
      }
    }

    // Strategy 3: Look for direct download links
    final downloadLinks = doc.querySelectorAll(
      'a[href*=".mp4"], a[href*="download"], '
      '.download-section a, a.download-btn',
    );
    for (final dl in downloadLinks) {
      final href = dl.attributes['href'] ?? '';
      final text = dl.text.trim();
      if (href.isNotEmpty) {
        sources.add(VideoSource(
          serverName: text.isNotEmpty ? text : 'Direct Download',
          embedUrl: _absoluteUrl(href),
          quality: _inferQuality(text),
        ));
      }
    }

    return sources;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  /// Infer video quality from server name text
  String _inferQuality(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('1080') || lower.contains('fhd')) return '1080p';
    if (lower.contains('720') || lower.contains('hd')) return '720p';
    if (lower.contains('480') || lower.contains('sd')) return '480p';
    if (lower.contains('360')) return '360p';
    return 'unknown';
  }

  /// Ensure URL is absolute
  String _absoluteUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('//')) return 'https:$url';
    if (url.startsWith('/')) return '$_baseUrl$url';
    return '$_baseUrl/$url';
  }
}
