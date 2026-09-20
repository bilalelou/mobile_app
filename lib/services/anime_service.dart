import 'package:flutter/foundation.dart';
import '../core/http_client.dart';
import '../models/anime.dart';
import '../providers/base_provider.dart';
import '../providers/witanime_provider.dart';
import '../resolvers/video_resolver.dart';
import '../download/download_manager.dart';
import '../download/download_task.dart';

/// ─── Anime Service ─────────────────────────────────────────────────
///
/// Facade layer that connects the UI to the backend scraping,
/// resolving, and download systems. Manages state via ChangeNotifier
/// so Flutter widgets can reactively rebuild.
class AnimeService extends ChangeNotifier {
  late final AppHttpClient _client;
  late final BaseProvider _provider;
  late final VideoResolver _resolver;
  late final DownloadManager _downloader;

  // ─── State ──────────────────────────────────────────────────────
  List<AnimeSearchResult> searchResults = [];
  AnimeDetails? currentAnime;
  List<VideoSource> currentSources = [];
  bool isSearching = false;
  bool isLoadingDetails = false;
  bool isResolvingVideo = false;
  String? errorMessage;

  AnimeService() {
    _client = AppHttpClient();
    _provider = WitanimeProvider(_client);
    _resolver = VideoResolver(_client);
    _downloader = DownloadManager();
  }

  // ─── Accessors ──────────────────────────────────────────────────

  String get providerName => _provider.name;
  String get providerBaseUrl => _provider.baseUrl;
  DownloadManager get downloader => _downloader;
  Stream<DownloadProgress> get downloadProgress => _downloader.progressStream;

  // ─── Search ─────────────────────────────────────────────────────

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    isSearching = true;
    errorMessage = null;
    searchResults = [];
    notifyListeners();

    try {
      searchResults = await _provider.search(query);
      if (searchResults.isEmpty) {
        errorMessage = 'لا توجد نتائج لـ "$query"';
      }
    } catch (e) {
      errorMessage = 'فشل البحث: ${_friendlyError(e)}';
      searchResults = [];
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  // ─── Anime Details ──────────────────────────────────────────────

  Future<void> loadAnimeDetails(String animeUrl) async {
    isLoadingDetails = true;
    errorMessage = null;
    currentAnime = null;
    currentSources = [];
    notifyListeners();

    try {
      currentAnime = await _provider.loadAnimeDetails(animeUrl);
    } catch (e) {
      errorMessage = 'فشل تحميل التفاصيل: ${_friendlyError(e)}';
    } finally {
      isLoadingDetails = false;
      notifyListeners();
    }
  }

  // ─── Video Sources ──────────────────────────────────────────────

  Future<List<VideoSource>> getVideoSources(String episodeUrl) async {
    isResolvingVideo = true;
    errorMessage = null;
    currentSources = [];
    notifyListeners();

    try {
      currentSources = await _provider.getVideoSources(episodeUrl);
    } catch (e) {
      errorMessage = 'فشل جلب السيرفرات: ${_friendlyError(e)}';
    } finally {
      isResolvingVideo = false;
      notifyListeners();
    }
    return currentSources;
  }

  // ─── Resolve Video URL ──────────────────────────────────────────

  Future<String?> resolveVideoUrl(VideoSource source) async {
    try {
      return await _resolver.resolve(source);
    } catch (e) {
      debugPrint('⚠️ Failed to resolve ${source.serverName}: $e');
      return null;
    }
  }

  /// Resolve first working source from a list
  Future<String?> resolveFirstWorking(List<VideoSource> sources) async {
    return await _resolver.resolveFirst(sources);
  }

  // ─── Downloads ──────────────────────────────────────────────────

  void startDownload({
    required int episodeNumber,
    required String episodeTitle,
    required String directUrl,
    required String savePath,
    String? referer,
  }) {
    _downloader.enqueue(DownloadTask(
      episodeNumber: episodeNumber,
      episodeTitle: episodeTitle,
      directUrl: directUrl,
      savePath: savePath,
      referer: referer,
    ));
  }

  void cancelAllDownloads() {
    _downloader.cancelAll();
  }

  // ─── Provider Config ────────────────────────────────────────────

  void updateBaseUrl(String url) {
    _provider.baseUrl = url;
    notifyListeners();
  }

  // ─── Helpers ────────────────────────────────────────────────────

  String _friendlyError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('HandshakeException')) {
      return 'تعذر الاتصال بالإنترنت. تحقق من اتصالك.';
    }
    if (msg.contains('403')) {
      return 'الموقع محجوب. جرب VPN أو رابط بديل.';
    }
    if (msg.contains('429')) {
      return 'طلبات كثيرة. انتظر قليلاً ثم حاول مرة أخرى.';
    }
    if (msg.contains('TimeoutException')) {
      return 'انتهت مهلة الاتصال. حاول مرة أخرى.';
    }
    return msg.length > 100 ? '${msg.substring(0, 100)}...' : msg;
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _client.dispose();
    _downloader.dispose();
    super.dispose();
  }
}
