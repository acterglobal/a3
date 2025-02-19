import 'package:acter/common/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('URL Validation Tests', () {
    test('Valid URL with http', () {
      expect(isValidUrl('http://example.com'), true);
    });

    test('Valid URL with https', () {
      expect(isValidUrl('https://example.com'), true);
    });

    test('Valid URL with custom schema', () {
      expect(isValidUrl('custom://example.com'), true);
    });

    test('Valid URL with subdomains', () {
      expect(isValidUrl('https://sub.example.com'), true);
    });

    test('Valid URL with query parameters', () {
      expect(isValidUrl('https://example.com?query=flutter'), true);
    });

    test('Invalid URL without scheme', () {
      expect(isValidUrl('example.com'), false);
    });

    test('Invalid URL with invalid characters', () {
      expect(isValidUrl('https://example!.com'), false);
    });

    test('Invalid URL with missing domain', () {
      expect(isValidUrl('https://.com'), false);
    });

    test('Empty URL string', () {
      expect(isValidUrl(''), false);
    });
  });
}
