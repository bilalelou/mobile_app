import 'dart:math';

/// User-Agent strings to rotate for anti-ban
const List<String> kUserAgents = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:127.0) Gecko/20100101 Firefox/127.0',
];

/// Minimum delay between HTTP requests (ms)
const int kMinRequestDelayMs = 1000;

/// Maximum additional random delay (ms)
const int kMaxRandomDelayMs = 3000;

/// Delay between consecutive downloads (seconds)
const int kBetweenDownloadDelaySec = 2;

/// Max retries for a failed download
const int kMaxDownloadRetries = 3;

/// Default download directory
const String kDefaultDownloadDir = './downloads';

/// Get a random User-Agent
String getRandomUserAgent() {
  final random = Random();
  return kUserAgents[random.nextInt(kUserAgents.length)];
}
