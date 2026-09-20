import 'dart:math';
import 'package:http/http.dart' as http;
import 'constants.dart';

/// HTTP client wrapper with anti-ban features:
/// - Random User-Agent rotation
/// - Random delays between requests
/// - Automatic retry on 429 (rate limit)
/// - Arabic + English Accept-Language
class AppHttpClient {
  final _random = Random();
  final http.Client _client;
  String? _cachedCookie;

  AppHttpClient() : _client = http.Client();

  /// Fetch HTML content from a URL with anti-ban protections
  Future<String> getHtml(String url, {Map<String, String>? extraHeaders}) async {
    // Random delay to mimic human browsing
    await Future.delayed(Duration(
      milliseconds: kMinRequestDelayMs + _random.nextInt(kMaxRandomDelayMs),
    ));

    final headers = <String, String>{
      'User-Agent': getRandomUserAgent(),
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'ar,en;q=0.9,en-US;q=0.8',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Referer': _extractOrigin(url),
      if (_cachedCookie != null) 'Cookie': _cachedCookie!,
      ...?extraHeaders,
    };

    final proxiedUrl = 'https://corsproxy.io/?url=' + Uri.encodeComponent(url);
    final response = await _client.get(Uri.parse(proxiedUrl), headers: headers);

    // Cache cookies for session persistence
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      _cachedCookie = setCookie.split(';').first;
    }

    if (response.statusCode == 429) {
      // Rate limited — exponential backoff
      print('⚠️  Rate limited (429). Waiting 30 seconds...');
      await Future.delayed(const Duration(seconds: 30));
      return getHtml(url, extraHeaders: extraHeaders);
    }

    if (response.statusCode == 403) {
      print('⚠️  Forbidden (403). The site may be using Cloudflare protection.');
      print('   Try updating the base URL or using a VPN.');
      throw HttpException(
        'Access forbidden (403) for $url. Possible Cloudflare block.',
        statusCode: 403,
      );
    }

    if (response.statusCode != 200) {
      throw HttpException(
        'HTTP ${response.statusCode} for $url',
        statusCode: response.statusCode,
      );
    }

    return response.body;
  }

  /// Fetch response with headers (for resolving redirects, getting content type)
  Future<http.Response> getResponse(String url, {Map<String, String>? extraHeaders}) async {
    await Future.delayed(Duration(
      milliseconds: kMinRequestDelayMs + _random.nextInt(kMaxRandomDelayMs),
    ));

    final headers = <String, String>{
      'User-Agent': getRandomUserAgent(),
      'Accept': '*/*',
      'Referer': _extractOrigin(url),
      if (_cachedCookie != null) 'Cookie': _cachedCookie!,
      ...?extraHeaders,
    };

    final proxiedUrl = 'https://corsproxy.io/?url=' + Uri.encodeComponent(url);
    return await _client.get(Uri.parse(proxiedUrl), headers: headers);
  }

  /// Extract origin (scheme + host) from URL for Referer header
  String _extractOrigin(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}';
    } catch (_) {
      return '';
    }
  }

  /// Set a cookie manually (e.g., from Cloudflare bypass)
  void setCookie(String cookie) {
    _cachedCookie = cookie;
  }

  void dispose() {
    _client.close();
  }
}

/// Custom HTTP exception with status code
class HttpException implements Exception {
  final String message;
  final int statusCode;

  HttpException(this.message, {required this.statusCode});

  @override
  String toString() => 'HttpException($statusCode): $message';
}
