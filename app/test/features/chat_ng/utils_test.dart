import 'package:flutter_test/flutter_test.dart';
import 'package:acter/features/chat_ng/utils.dart';

void main() {
  group('isOnlyEmojis', () {
    test('should return true for single emoji', () {
      expect(isOnlyEmojis('😊'), true);
      expect(isOnlyEmojis('👍'), true);
      expect(isOnlyEmojis('🎉'), true);
    });

    test('should return true for multiple emojis', () {
      expect(isOnlyEmojis('😊👍🎉'), true);
      expect(isOnlyEmojis('👋👋👋'), true);
      expect(isOnlyEmojis('❤️💕💖'), true);
    });

    test('should return true for emojis with variation selectors', () {
      expect(isOnlyEmojis('👋🏽'), true); // Emoji with skin tone modifier
      expect(isOnlyEmojis('❤️'), true); // Emoji with variation selector
      expect(isOnlyEmojis('👨‍👩‍👧‍👦'), true); // Family emoji with ZWJ
    });

    test('should return false for text with emojis', () {
      expect(isOnlyEmojis('Hello 😊'), false);
      expect(isOnlyEmojis('😊 World'), false);
      expect(isOnlyEmojis('Hello 😊 World'), false);
    });

    test(
      'should return false for mulitline text with emojis and plaintext',
      () {
        expect(isOnlyEmojis('Hello \n😊'), false);
        expect(isOnlyEmojis('😊\n World'), false);
        expect(isOnlyEmojis('Hello\n😊👍🎉\nWorld'), false);
      },
    );

    test('should return true for mulitline with only emojis', () {
      expect(isOnlyEmojis('👍🎉 \n😊'), true);
      expect(isOnlyEmojis('😊\n 👍🎉'), true);
      expect(isOnlyEmojis('👍🎉\n😊👍🎉\n\r\t  👍🎉'), true);
    });

    test('should return false for plain text', () {
      expect(isOnlyEmojis('Hello'), false);
      expect(isOnlyEmojis('123'), false);
      expect(isOnlyEmojis(''), false);
      expect(isOnlyEmojis('   '), false);
    });

    test('should handle whitespace correctly', () {
      expect(isOnlyEmojis(' 😊 '), true); // Emoji with spaces
      expect(isOnlyEmojis('\n😊\n'), true); // Emoji with newlines
      expect(isOnlyEmojis('\t😊\t'), true); // Emoji with tabs
    });

    test('should handle special emoji cases', () {
      expect(isOnlyEmojis('🏳️‍🌈'), true); // Rainbow flag
      expect(isOnlyEmojis('👨‍💻'), true); // Person with profession
      expect(isOnlyEmojis('🏴󠁧󠁢󠁥󠁮󠁧󠁿'), true); // Regional indicator
    });

    test(
      'should return false for multiline text with multiple whitespace characters',
      () {
        expect(
          isOnlyEmojis('Weekly Product Update 🚀 \n\r\nHello dear community!'),
          false,
        );
        expect(
          isOnlyEmojis('Line 1\n\r\nLine 2\r\n\tIndented line\n\r\nFinal line'),
          false,
        );
        expect(
          isOnlyEmojis('\n\r\t  Text with various whitespace  \t\r\n'),
          false,
        );
        expect(
          isOnlyEmojis('🚀\n\r\nActual text content\r\n\t- Bullet point'),
          false,
        );
      },
    );
  });
}
