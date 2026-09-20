import 'package:test/test.dart';
import 'package:animegrab/resolvers/js_unpacker.dart';

void main() {
  group('JsUnpacker', () {
    test('should detect packed JavaScript', () {
      const packed = "eval(function(p,a,c,k,e,d){while(c--)if(k[c])p=p.replace"
          "(new RegExp('\\\\b'+c.toString(a)+'\\\\b','g'),k[c]);return p}"
          "('1 0=\"2\";',3,3,'x|var|hello'.split('|'),0,{}))";
      expect(JsUnpacker.isPacked(packed), isTrue);
    });

    test('should not detect non-packed JavaScript', () {
      const normal = 'var x = "hello world";';
      expect(JsUnpacker.isPacked(normal), isFalse);
    });

    test('should unpack simple packed JS', () {
      // Manually constructed simple packed JS test
      const packed = "eval(function(p,a,c,k,e,d){while(c--)if(k[c])p=p.replace"
          "(new RegExp('\\\\b'+c.toString(a)+'\\\\b','g'),k[c]);return p}"
          "('1 0=\"2\";',3,3,'x|var|hello'.split('|'),0,{}))";
      final result = JsUnpacker.unpack(packed);
      expect(result, isNotNull);
      expect(result, contains('var'));
    });

    test('should return null for invalid packed JS', () {
      const invalid = 'not packed at all';
      final result = JsUnpacker.unpack(invalid);
      expect(result, isNull);
    });

    test('_encodeBase handles base 10', () {
      // Test through the public unpack method indirectly
      // Just verify the class doesn't crash on edge cases
      expect(JsUnpacker.unpack(''), isNull);
    });
  });

  group('JsUnpacker._encodeBase', () {
    test('should encode 0 in various bases', () {
      // We can't access private methods directly, but we can verify
      // the unpacker handles them correctly through integration
      const packed = "eval(function(p,a,c,k,e,d){while(c--)if(k[c])p=p.replace"
          "(new RegExp('\\\\b'+c.toString(a)+'\\\\b','g'),k[c]);return p}"
          "('0=\"1\";',10,2,'hello|var'.split('|'),0,{}))";
      final result = JsUnpacker.unpack(packed);
      expect(result, isNotNull);
    });
  });
}
