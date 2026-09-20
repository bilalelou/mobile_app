import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

/// Utility wrapper around the html parser
class HtmlParser {
  /// Parse an HTML string into a Document
  static Document parse(String htmlContent) {
    return html_parser.parse(htmlContent);
  }

  /// Extract all matching elements via CSS selector
  static List<Element> queryAll(Document doc, String selector) {
    return doc.querySelectorAll(selector);
  }

  /// Extract first matching element via CSS selector
  static Element? query(Document doc, String selector) {
    return doc.querySelector(selector);
  }

  /// Extract text content from first matching element
  static String? textFrom(Document doc, String selector) {
    return doc.querySelector(selector)?.text.trim();
  }

  /// Extract attribute from first matching element
  static String? attrFrom(Document doc, String selector, String attribute) {
    return doc.querySelector(selector)?.attributes[attribute];
  }

  /// Extract all href values from matching links
  static List<String> allHrefs(Document doc, String selector) {
    return doc.querySelectorAll(selector)
        .map((e) => e.attributes['href'] ?? '')
        .where((href) => href.isNotEmpty)
        .toList();
  }

  /// Extract all iframe src values
  static List<String> allIframeSrcs(Document doc) {
    return doc.querySelectorAll('iframe')
        .map((e) => e.attributes['src'] ?? '')
        .where((src) => src.isNotEmpty)
        .toList();
  }
}
