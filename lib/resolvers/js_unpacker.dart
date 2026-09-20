/// JavaScript unpacker for eval(function(p,a,c,k,e,d)) packed code
///
/// Many anime streaming servers obfuscate their video URLs using
/// Dean Edwards' JavaScript packer. This class reverses that packing.
///
/// The packed format is:
/// eval(function(p,a,c,k,e,d){...}('payload',radix,count,'keywords'.split('|'),0,{}))
class JsUnpacker {
  /// Unpack a packed JavaScript string
  /// Returns the unpacked JavaScript code, or null if unpacking fails
  static String? unpack(String packed) {
    try {
      // Extract the components from the packed string
      final match = RegExp(
        r"\}\('(.*?)',\s*(\d+),\s*(\d+),\s*'(.*?)'\.split\('\|'\)",
        dotAll: true,
      ).firstMatch(packed);

      if (match == null) return null;

      final payload = match.group(1)!;
      final radix = int.parse(match.group(2)!);
      final count = int.parse(match.group(3)!);
      final keywords = match.group(4)!.split('|');

      if (keywords.length != count) {
        // Mismatch but try anyway — some packers have this bug
      }

      // Replace each encoded word in the payload with its keyword
      String result = payload;

      // Process in reverse order of word length to avoid partial replacements
      // Build a replacement map: base-N encoded index → keyword
      for (int i = count - 1; i >= 0; i--) {
        final encoded = _encodeBase(i, radix);
        final keyword = i < keywords.length && keywords[i].isNotEmpty
            ? keywords[i]
            : encoded;

        // Replace word boundaries: \b<encoded>\b
        result = result.replaceAllMapped(
          RegExp('\\b${RegExp.escape(encoded)}\\b'),
          (m) => keyword,
        );
      }

      return result;
    } catch (e) {
      return null;
    }
  }

  /// Check if a string contains packed JavaScript
  static bool isPacked(String js) {
    return RegExp(
      r"eval\(function\(p,a,c,k,e,d\)\{",
    ).hasMatch(js);
  }

  /// Encode a number in the given base (up to 62)
  static String _encodeBase(int number, int base) {
    if (number < 0) return '';
    if (base <= 10) return number.toRadixString(base);
    if (base <= 36) return number.toRadixString(base);

    // For base 37-62, use custom encoding
    const chars =
        '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

    if (number == 0) return '0';

    String result = '';
    int n = number;
    while (n > 0) {
      result = chars[n % base] + result;
      n ~/= base;
    }
    return result;
  }
}
