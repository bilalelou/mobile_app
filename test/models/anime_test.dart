import 'package:test/test.dart';
import 'package:animegrab/models/anime.dart';

void main() {
  group('AnimeSearchResult', () {
    test('should create with required fields', () {
      final result = AnimeSearchResult(
        title: 'One Piece',
        url: 'https://example.com/anime/one-piece',
      );
      expect(result.title, equals('One Piece'));
      expect(result.url, equals('https://example.com/anime/one-piece'));
      expect(result.posterUrl, equals(''));
    });

    test('should create with all fields', () {
      final result = AnimeSearchResult(
        title: 'Naruto',
        url: 'https://example.com/anime/naruto',
        posterUrl: 'https://example.com/poster.jpg',
        type: 'TV',
        status: 'Completed',
      );
      expect(result.type, equals('TV'));
      expect(result.status, equals('Completed'));
    });
  });

  group('Episode', () {
    test('should create with fields', () {
      final ep = Episode(number: 1, title: 'الحلقة 1', url: '/episode/1');
      expect(ep.number, equals(1));
      expect(ep.title, equals('الحلقة 1'));
    });

    test('toString should include number', () {
      final ep = Episode(number: 42, title: 'Test', url: '/ep/42');
      expect(ep.toString(), contains('42'));
    });
  });

  group('VideoSource', () {
    test('should create with required fields', () {
      final src = VideoSource(
        serverName: 'Mp4Upload',
        embedUrl: 'https://mp4upload.com/embed/abc123',
      );
      expect(src.serverName, equals('Mp4Upload'));
      expect(src.quality, equals('unknown'));
    });

    test('copyWithDirectUrl should preserve other fields', () {
      final src = VideoSource(
        serverName: 'StreamWish',
        embedUrl: 'https://streamwish.com/e/abc',
        quality: '720p',
      );
      final updated = src.copyWithDirectUrl('https://cdn.example.com/video.mp4');
      expect(updated.serverName, equals('StreamWish'));
      expect(updated.quality, equals('720p'));
      expect(updated.directUrl, equals('https://cdn.example.com/video.mp4'));
    });
  });

  group('AnimeDetails', () {
    test('should create with episodes', () {
      final details = AnimeDetails(
        title: 'Attack on Titan',
        episodes: [
          Episode(number: 1, title: 'EP 1', url: '/ep/1'),
          Episode(number: 2, title: 'EP 2', url: '/ep/2'),
        ],
      );
      expect(details.episodes.length, equals(2));
      expect(details.genres, isEmpty);
    });
  });
}
