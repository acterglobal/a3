import 'package:flutter_test/flutter_test.dart';
import 'package:acter/common/toolkit/html/utils.dart';

void main() {
  group('minimalMarkup', () {
    group('URL replacement', () {
      test('should replace http URLs with anchor tags', () {
        const input = 'Check out http://example.com for more info';
        const expected =
            'Check out <a href="http://example.com">example.com</a> for more info';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should replace https URLs with anchor tags', () {
        const input = 'Visit https://secure.example.com for secure browsing';
        const expected =
            'Visit <a href="https://secure.example.com">secure.example.com</a> for secure browsing';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should replace matrix URLs with anchor tags', () {
        const input = 'Join our room: matrix:r/acter:acter.chat';
        const expected =
            'Join our room: <a href="matrix:r/acter:acter.chat">r/acter:acter.chat</a>';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should replace acter URLs with anchor tags', () {
        const input = 'Check this out: acter:user/123';
        const expected =
            'Check this out: <a href="acter:user/123">user/123</a>';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle URLs with query parameters', () {
        const input = 'Search at https://google.com?q=test&lang=en';
        const expected =
            'Search at <a href="https://google.com?q=test&lang=en">google.com?q=test&lang=en</a>';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle URLs with fragments', () {
        const input = 'Go to https://example.com/page#section';
        const expected =
            'Go to <a href="https://example.com/page#section">example.com/page#section</a>';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle URLs with special characters', () {
        const input = 'Visit https://example.com/path/with/special-chars_123';
        const expected =
            'Visit <a href="https://example.com/path/with/special-chars_123">example.com/path/with/special-chars_123</a>';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle multiple URLs in the same text', () {
        const input = 'Check http://example1.com and https://example2.com';
        const expected =
            'Check <a href="http://example1.com">example1.com</a> and <a href="https://example2.com">example2.com</a>';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle URLs at the beginning of text', () {
        const input = 'https://example.com is a great website';
        const expected =
            '<a href="https://example.com">example.com</a> is a great website';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle URLs at the end of text', () {
        const input = 'Visit our website at https://example.com';
        const expected =
            'Visit our website at <a href="https://example.com">example.com</a>';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle URLs with trailing punctuation', () {
        const input = 'Check out https://example.com!';
        const expected =
            'Check out <a href="https://example.com">example.com</a>!';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should not replace text that looks like URLs but is not', () {
        const input = 'This is not a URL: example.com';
        const expected = 'This is not a URL: example.com';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle URLs with unicode characters', () {
        const input = 'Visit https://example.com/path/with/unicode/测试';
        const expected =
            'Visit <a href="https://example.com/path/with/unicode/测试">example.com/path/with/unicode/测试</a>';

        expect(minimalMarkup(input), equals(expected));
      });
    });

    group('line break replacement', () {
      test('should replace single newline with br tag', () {
        const input = 'Line 1\nLine 2';
        const expected = 'Line 1<br>Line 2';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should replace multiple consecutive newlines with br tags', () {
        const input = 'Line 1\n\n\nLine 2';
        const expected = 'Line 1<br><br><br>Line 2';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle newline at the beginning', () {
        const input = '\nLine 1';
        const expected = '<br>Line 1';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle newline at the end', () {
        const input = 'Line 1\n';
        const expected = 'Line 1<br>';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle only newlines', () {
        const input = '\n\n\n';
        const expected = '<br><br><br>';

        expect(minimalMarkup(input), equals(expected));
      });
    });

    group('combined URL and line break replacement', () {
      test('should handle URLs and newlines together', () {
        const input =
            'Check this out:\nhttps://example.com\nAnd this: http://test.com';
        const expected =
            'Check this out:<br><a href="https://example.com">example.com</a><br>And this: <a href="http://test.com">test.com</a>';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle URL followed by newline', () {
        const input = 'Visit https://example.com\nfor more information';
        const expected =
            'Visit <a href="https://example.com">example.com</a><br>for more information';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle newline followed by URL', () {
        const input = 'More info:\nhttps://example.com';
        const expected =
            'More info:<br><a href="https://example.com">example.com</a>';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle complex mixed content', () {
        const input =
            'Welcome!\n\nCheck out our website: https://example.com\n\nAnd join our matrix room: matrix:r/acter:acter.chat';
        const expected =
            'Welcome!<br><br>Check out our website: <a href="https://example.com">example.com</a><br><br>And join our matrix room: <a href="matrix:r/acter:acter.chat">r/acter:acter.chat</a>';

        expect(minimalMarkup(input), equals(expected));
      });
    });

    group('edge cases', () {
      test('should handle empty string', () {
        const input = '';
        const expected = '';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle string with only whitespace', () {
        const input = '   \n  \n  ';
        const expected = '   <br>  <br>  ';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle very long URLs', () {
        final longUrl = 'https://example.com/${"a" * 1000}';
        final input = 'Visit $longUrl for details';
        final expected =
            'Visit <a href="$longUrl">${longUrl.replaceFirst('https://', '')}</a> for details';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle URLs with spaces in query parameters', () {
        const input = 'Search at https://example.com?q=hello%20world';
        const expected =
            'Search at <a href="https://example.com?q=hello%20world">example.com?q=hello%20world</a>';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle mixed case URLs', () {
        const input = 'Check HTTP://EXAMPLE.COM and HttPs://Test.Com';
        const expected =
            'Check <a href="HTTP://EXAMPLE.COM">EXAMPLE.COM</a> and <a href="HttPs://Test.Com">Test.Com</a>';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle URLs with ports', () {
        const input = 'Connect to https://example.com:8080';
        const expected =
            'Connect to <a href="https://example.com:8080">example.com:8080</a>';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle URLs with authentication', () {
        const input = 'Access https://user:pass@example.com';
        const expected =
            'Access <a href="https://user:pass@example.com">user:pass@example.com</a>';

        expect(minimalMarkup(input), equals(expected));
      });
    });

    group('regression tests', () {
      test('should not break with malformed URLs', () {
        const input = 'This is not a URL: http://';
        const expected = 'This is not a URL: http://';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should handle URLs with dots at the end', () {
        const input = 'Visit https://example.com. for more info.';
        const expected =
            'Visit <a href="https://example.com">example.com</a>. for more info.';

        expect(minimalMarkup(input), equals(expected));
      });

      test('should preserve existing HTML-like content', () {
        const input = 'Text with <b>bold</b> and https://example.com';
        const expected =
            'Text with <b>bold</b> and <a href="https://example.com">example.com</a>';

        expect(minimalMarkup(input), equals(expected));
      });
    });
  });
}
