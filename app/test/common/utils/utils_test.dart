import 'package:acter/common/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Editor Content Validation', () {
    test('returns false for empty plain text', () {
      expect(
        hasValidEditorContent(plainText: '', html: '<p>Some content</p>'),
        false,
      );
    });

    test('returns false for empty HTML', () {
      expect(hasValidEditorContent(plainText: 'Some text', html: ''), false);
    });

    test('returns false for whitespace-only plain text', () {
      expect(
        hasValidEditorContent(plainText: '   ', html: '<p>Some content</p>'),
        false,
      );
    });

    test('returns false for HTML with only <br> tag', () {
      expect(
        hasValidEditorContent(plainText: 'Some text', html: '<br>'),
        false,
      );
    });

    test('returns false for HTML with only empty paragraph', () {
      expect(
        hasValidEditorContent(plainText: 'Some text', html: '<p></p>'),
        false,
      );
    });

    test('returns false for HTML with only whitespace in paragraph', () {
      expect(
        hasValidEditorContent(plainText: 'Some text', html: '<p>   </p>'),
        false,
      );
    });

    test('returns false for HTML with only &nbsp;', () {
      expect(
        hasValidEditorContent(plainText: 'Some text', html: '<p>&nbsp;</p>'),
        false,
      );
    });

    test('returns true for valid plain text and HTML content', () {
      expect(
        hasValidEditorContent(
          plainText: 'Hello World',
          html: '<p>Hello World</p>',
        ),
        true,
      );
    });

    test('returns true for HTML with formatting but valid content', () {
      expect(
        hasValidEditorContent(
          plainText: 'Hello World',
          html: '<p><strong>Hello</strong> <em>World</em></p>',
        ),
        true,
      );
    });

    test('returns true for HTML with multiple paragraphs', () {
      expect(
        hasValidEditorContent(
          plainText: 'Hello\nWorld',
          html: '<p>Hello</p><p>World</p>',
        ),
        true,
      );
    });

    test('returns true for HTML with line breaks and content', () {
      expect(
        hasValidEditorContent(
          plainText: 'Hello\nWorld',
          html: '<p>Hello<br>World</p>',
        ),
        true,
      );
    });
  });
}
