import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:animegrab/core/http_client.dart';
import 'package:animegrab/core/constants.dart';
import 'package:animegrab/providers/witanime_provider.dart';
import 'package:animegrab/resolvers/video_resolver.dart';
import 'package:animegrab/download/download_manager.dart';
import 'package:animegrab/download/download_task.dart';
import 'package:animegrab/models/anime.dart';

/// ╔══════════════════════════════════════════════════╗
/// ║           AnimeGrab CLI — v0.1.0                 ║
/// ║     Anime Episode Scraper & Downloader           ║
/// ╚══════════════════════════════════════════════════╝
///
/// Usage: dart run bin/animegrab.dart [options]
///
/// Workflow:
///   1. Enter anime name → search
///   2. Select anime from results
///   3. Choose episode range
///   4. Auto-resolve video URLs & download sequentially

Future<void> main(List<String> args) async {
  _printBanner();

  // Parse optional base URL from args
  String? customBaseUrl;
  if (args.contains('--url') && args.indexOf('--url') + 1 < args.length) {
    customBaseUrl = args[args.indexOf('--url') + 1];
  }

  // Initialize components
  final client = AppHttpClient();
  final provider = WitanimeProvider(client, baseUrl: customBaseUrl);
  final resolver = VideoResolver(client);
  final downloader = DownloadManager();

  print('📡 Using provider: ${provider.name} (${provider.baseUrl})');
  print('');

  try {
    // ─── Step 1: Search ──────────────────────────────────────────
    final query = _prompt('🔍 Enter anime name');
    if (query.isEmpty) {
      print('❌ No search query provided. Exiting.');
      return;
    }

    print('\nSearching for "$query"...\n');
    final results = await provider.search(query);

    if (results.isEmpty) {
      print('❌ No results found for "$query".');
      print('   Try a different name or check the base URL.');
      return;
    }

    // ─── Step 2: Select Anime ────────────────────────────────────
    print('📋 Search Results:');
    print('${'─' * 50}');
    for (int i = 0; i < results.length; i++) {
      print('  [${i + 1}] ${results[i].title}');
    }
    print('${'─' * 50}');

    final choiceStr = _prompt('Select anime (1-${results.length})');
    final choice = int.tryParse(choiceStr) ?? 1;
    if (choice < 1 || choice > results.length) {
      print('❌ Invalid choice. Exiting.');
      return;
    }
    final selected = results[choice - 1];
    print('\n✅ Selected: ${selected.title}\n');

    // ─── Step 3: Load Episodes ───────────────────────────────────
    print('Loading episode list...\n');
    final details = await provider.loadAnimeDetails(selected.url);

    if (details.episodes.isEmpty) {
      print('❌ No episodes found for "${details.title}".');
      print('   The site structure may have changed.');
      return;
    }

    print('📺 ${details.title}');
    if (details.description != null) {
      final desc = details.description!;
      print('   ${desc.length > 100 ? '${desc.substring(0, 100)}...' : desc}');
    }
    print('   Episodes: ${details.episodes.length}');
    print('   Range: ${details.episodes.first.number} - ${details.episodes.last.number}');
    print('');

    // ─── Step 4: Select Range ────────────────────────────────────
    final rangeStr = _prompt(
      'Download episodes (e.g. "1-12", "5", or "all")',
      defaultValue: 'all',
    );
    final episodesToDownload = _parseEpisodeRange(rangeStr, details.episodes);

    if (episodesToDownload.isEmpty) {
      print('❌ No valid episodes in the specified range.');
      return;
    }

    print('\n📥 Will download ${episodesToDownload.length} episode(s): '
        '${episodesToDownload.map((e) => e.number).join(', ')}\n');

    // ─── Step 5: Resolve & Queue ─────────────────────────────────
    final downloadDir = p.join(kDefaultDownloadDir, _sanitizeFilename(details.title));
    print('📂 Download directory: $downloadDir\n');

    int resolved = 0;
    int failed = 0;

    for (final ep in episodesToDownload) {
      print('🔗 Resolving Episode ${ep.number}...');

      try {
        final sources = await provider.getVideoSources(ep.url);
        if (sources.isEmpty) {
          print('  ⚠️  No video sources found for Episode ${ep.number}');
          failed++;
          continue;
        }

        print('  Found ${sources.length} server(s): '
            '${sources.map((s) => s.serverName).join(', ')}');

        final directUrl = await resolver.resolveFirst(sources);
        if (directUrl != null) {
          final ext = directUrl.contains('.m3u8') ? '.m3u8' : '.mp4';
          final filename = 'Episode_${ep.number.toString().padLeft(3, '0')}$ext';

          downloader.enqueue(DownloadTask(
            episodeNumber: ep.number,
            episodeTitle: ep.title,
            directUrl: directUrl,
            savePath: p.join(downloadDir, filename),
            referer: provider.baseUrl,
          ));
          resolved++;
        } else {
          print('  ❌ Could not resolve any video URL for Episode ${ep.number}');
          failed++;
        }
      } catch (e) {
        print('  ❌ Error resolving Episode ${ep.number}: $e');
        failed++;
      }
    }

    print('\n${'═' * 50}');
    print('📊 Resolution complete: $resolved resolved, $failed failed');
    print('${'═' * 50}\n');

    if (resolved == 0) {
      print('❌ No episodes could be resolved. Nothing to download.');
      return;
    }

    // ─── Step 6: Download ────────────────────────────────────────
    print('🚀 Starting sequential downloads...\n');

    // Set up progress listener
    downloader.progressStream.listen((p) {
      switch (p.status) {
        case DownloadStatus.downloading:
          // Overwrite line with progress
          stdout.write(
            '\r  📥 EP ${p.task.episodeNumber.toString().padLeft(3)} '
            '| ${p.progressPercent.padLeft(6)} '
            '| ${p.sizeInfo.padLeft(20)} ',
          );
          break;
        case DownloadStatus.completed:
          stdout.writeln(
            '\n  ✅ EP ${p.task.episodeNumber} completed',
          );
          break;
        case DownloadStatus.failed:
          stdout.writeln(
            '\n  ❌ EP ${p.task.episodeNumber} failed: ${p.error}',
          );
          break;
        case DownloadStatus.retrying:
          stdout.writeln(
            '\n  🔄 EP ${p.task.episodeNumber}: ${p.error}',
          );
          break;
        default:
          break;
      }
    });

    // Wait for all downloads to complete
    // The queue processing starts automatically via enqueue
    while (downloader.isRunning) {
      await Future.delayed(const Duration(seconds: 1));
    }

    print('\n🎉 All done! Check: $downloadDir');
  } catch (e) {
    print('\n❌ Fatal error: $e');
  } finally {
    client.dispose();
    downloader.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════
// Helper Functions
// ═══════════════════════════════════════════════════════════════════

/// Print the app banner
void _printBanner() {
  print('');
  print('╔══════════════════════════════════════════════════╗');
  print('║         🎬 AnimeGrab CLI v0.1.0                 ║');
  print('║     Anime Episode Scraper & Downloader          ║');
  print('║                                                 ║');
  print('║  Usage: dart run bin/animegrab.dart [--url URL]  ║');
  print('╚══════════════════════════════════════════════════╝');
  print('');
}

/// Read user input with a prompt
String _prompt(String message, {String? defaultValue}) {
  if (defaultValue != null) {
    stdout.write('$message [$defaultValue]: ');
  } else {
    stdout.write('$message: ');
  }
  final input = stdin.readLineSync()?.trim() ?? '';
  return input.isEmpty ? (defaultValue ?? '') : input;
}

/// Parse episode range string into list of episodes
///
/// Supports:
///   "all"   → all episodes
///   "5"     → episode 5
///   "1-12"  → episodes 1 through 12
///   "1,3,5" → episodes 1, 3, and 5
///   "1-5,8" → episodes 1 through 5, plus 8
List<Episode> _parseEpisodeRange(String range, List<Episode> allEpisodes) {
  final trimmed = range.trim().toLowerCase();
  if (trimmed == 'all' || trimmed.isEmpty) return allEpisodes;

  final numbers = <int>{};

  for (final part in trimmed.split(',')) {
    final p = part.trim();
    if (p.contains('-')) {
      final bounds = p.split('-');
      if (bounds.length == 2) {
        final start = int.tryParse(bounds[0].trim());
        final end = int.tryParse(bounds[1].trim());
        if (start != null && end != null) {
          for (int i = start; i <= end; i++) {
            numbers.add(i);
          }
        }
      }
    } else {
      final num = int.tryParse(p);
      if (num != null) numbers.add(num);
    }
  }

  return allEpisodes
      .where((ep) => numbers.contains(ep.number))
      .toList()
    ..sort((a, b) => a.number.compareTo(b.number));
}

/// Sanitize a string for use as a filename/directory name
String _sanitizeFilename(String name) {
  return name
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
