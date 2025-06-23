import 'package:acter/common/toolkit/html_editor/html_editor.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActerEditorStateHelpers', () {
    group('intoMarkdown', () {
      test('converts plain text to markdown', () {
        final document =
            Document.blank()..insert([0], [paragraphNode(text: 'Hello World')]);
        final editorState = EditorState(document: document);

        final markdown = editorState.intoMarkdown();

        expect(markdown, equals('Hello World'));
      });

      test('converts heading to markdown', () {
        final document =
            Document.blank()
              ..insert([0], [headingNode(text: 'Hello World', level: 1)]);
        final editorState = EditorState(document: document);

        final markdown = editorState.intoMarkdown();

        expect(markdown, equals('# Hello World'));
      });

      test('converts bulleted list to markdown', () {
        final document =
            Document.blank()..insert(
              [0],
              [
                bulletedListNode(text: 'Item 1'),
                bulletedListNode(text: 'Item 2'),
              ],
            );
        final editorState = EditorState(document: document);

        final markdown = editorState.intoMarkdown();

        expect(markdown, equals('* Item 1\n* Item 2'));
      });

      test('uses custom markdown codec when provided', () {
        final document =
            Document.blank()..insert([0], [paragraphNode(text: 'Hello World')]);
        final editorState = EditorState(document: document);

        // Create a custom codec that adds a prefix
        final customCodec = AppFlowyEditorMarkdownCodec(
          encodeParsers: [TextNodeParser()],
        );

        final markdown = editorState.intoMarkdown(codec: customCodec);

        expect(markdown, equals('Hello World'));
      });

      test('handles empty document', () {
        final editorState = EditorState.blank();

        final markdown = editorState.intoMarkdown();

        expect(markdown, equals(''));
      });
    });

    group('intoHtml', () {
      test('converts plain text to HTML', () {
        final document =
            Document.blank()..insert([0], [paragraphNode(text: 'Hello World')]);
        final editorState = EditorState(document: document);

        final html = editorState.intoHtml();

        expect(html, equals('<p>Hello World</p>'));
      });

      test('converts heading to HTML', () {
        final document =
            Document.blank()
              ..insert([0], [headingNode(text: 'Hello World', level: 1)]);
        final editorState = EditorState(document: document);

        final html = editorState.intoHtml();

        expect(html, equals('<h1>Hello World</h1>'));
      });

      test('uses custom HTML codec when provided', () {
        final document =
            Document.blank()..insert([0], [paragraphNode(text: 'Hello World')]);
        final editorState = EditorState(document: document);

        // Create a custom codec with different parsers
        final customCodec = AppFlowyEditorHTMLCodec(
          encodeParsers: [HTMLTextNodeParser()],
        );

        final html = editorState.intoHtml(codec: customCodec);

        expect(html, equals('<p>Hello World</p>'));
      });

      test('handles empty document', () {
        final editorState = EditorState.blank();

        final html = editorState.intoHtml();

        expect(html, equals('<br>'));
      });
    });

    group('fromContent', () {
      test('creates editor state from HTML content', () {
        final htmlContent = '<p>Hello <strong>World</strong></p>';

        final editorState = ActerEditorStateHelpers.fromContent(
          'Fallback text',
          htmlContent,
        );

        expect(editorState.document.root.children.length, equals(1));
        expect(
          editorState.document.root.children.first.delta?.toPlainText(),
          equals('Hello World'),
        );
      });

      test('creates editor state from fallback text when HTML is null', () {
        final fallbackText = 'Hello World';

        final editorState = ActerEditorStateHelpers.fromContent(
          fallbackText,
          null,
        );

        expect(editorState.document.root.children.length, equals(1));
        expect(
          editorState.document.root.children.first.delta?.toPlainText(),
          equals('Hello World'),
        );
      });

      test('creates editor state from fallback text when HTML is empty', () {
        final fallbackText = 'Hello World';

        final editorState = ActerEditorStateHelpers.fromContent(
          fallbackText,
          '',
        );

        expect(editorState.document.root.children.length, equals(1));
        expect(
          editorState.document.root.children.first.delta?.toPlainText(),
          equals('Hello World'),
        );
      });

      test('handles text with URLs using minimalMarkup', () {
        final textWithUrls =
            'Check out https://example.com and https://test.org';

        final editorState = ActerEditorStateHelpers.fromContent(
          textWithUrls,
          null,
        );

        expect(editorState.document.root.children.length, equals(1));
        // The minimalMarkup should convert URLs to links
        final html = editorState.intoHtml();
        expect(html, contains('<a href="https://example.com">'));
        expect(html, contains('<a href="https://test.org">'));
      });
    });

    group('replaceContent', () {
      test('replaces content with HTML', () {
        final initialDocument =
            Document.blank()
              ..insert([0], [paragraphNode(text: 'Initial content')]);
        final editorState = EditorState(document: initialDocument);

        final newHtml = '<p>New <strong>content</strong></p>';

        editorState.replaceContent('Fallback text', newHtml);

        expect(
          editorState.document.root.children.first.delta?.toPlainText(),
          equals('New content'),
        );
      });

      test('replaces content with fallback text when HTML is null', () {
        final initialDocument =
            Document.blank()
              ..insert([0], [paragraphNode(text: 'Initial content')]);
        final editorState = EditorState(document: initialDocument);

        editorState.replaceContent('New fallback text', null);

        expect(
          editorState.document.root.children.first.delta?.toPlainText(),
          equals('New fallback text'),
        );
      });

      test('replaces content with fallback text when HTML is empty', () {
        final initialDocument =
            Document.blank()
              ..insert([0], [paragraphNode(text: 'Initial content')]);
        final editorState = EditorState(document: initialDocument);

        editorState.replaceContent('New fallback text', '');

        expect(
          editorState.document.root.children.first.delta?.toPlainText(),
          equals('New fallback text'),
        );
      });

      test('replaces complex content with multiple elements', () {
        final initialDocument =
            Document.blank()
              ..insert([0], [paragraphNode(text: 'Initial content')]);
        final editorState = EditorState(document: initialDocument);

        final newHtml = '''
          <h1>New Title</h1>
          <p>New paragraph</p>
          <ul><li>New item</li></ul>
        ''';

        editorState.replaceContent('Fallback text', newHtml);

        expect(editorState.document.root.children.length, equals(3));
        // expect(editorState.intoHtml(), newHtml);
        expect(
          editorState.document.root.children[0].delta?.toPlainText(),
          equals('New Title'),
        );
        expect(
          editorState.document.root.children[1].delta?.toPlainText(),
          equals('New paragraph'),
        );
        expect(
          editorState.document.root.children[2].delta?.toPlainText(),
          equals('New item'),
        );
      });

      test('clears existing content before replacing', () {
        final initialDocument =
            Document.blank()..insert(
              [0],
              [
                paragraphNode(text: 'First paragraph'),
                paragraphNode(text: 'Second paragraph'),
                headingNode(text: 'Heading', level: 1),
              ],
            );
        final editorState = EditorState(document: initialDocument);

        expect(editorState.document.root.children.length, equals(3));

        editorState.replaceContent('Simple replacement', null);

        expect(editorState.document.root.children.length, equals(1));
        expect(
          editorState.document.root.children.first.delta?.toPlainText(),
          equals('Simple replacement'),
        );
      });
    });

    group('replaceContentHTML', () {
      test('replaces content with HTML string', () {
        final initialDocument =
            Document.blank()
              ..insert([0], [paragraphNode(text: 'Initial content')]);
        final editorState = EditorState(document: initialDocument);

        final newHtml = '<p>New <strong>content</strong></p>';

        editorState.replaceContentHTML(newHtml);

        expect(
          editorState.document.root.children.first.delta?.toPlainText(),
          equals('New content'),
        );
      });

      test('handles empty HTML string', () {
        final initialDocument =
            Document.blank()
              ..insert([0], [paragraphNode(text: 'Initial content')]);
        final editorState = EditorState(document: initialDocument);

        editorState.replaceContentHTML('');
        // should only be one empty paragraph
        expect(editorState.document.root.children.length, equals(1));
        expect(editorState.intoHtml(), equals('<br>'));
      });

      test('completely replaces existing content', () {
        final initialDocument =
            Document.blank()..insert(
              [0],
              [
                paragraphNode(text: 'First paragraph'),
                paragraphNode(text: 'Second paragraph'),
                headingNode(text: 'Heading', level: 1),
              ],
            );
        final editorState = EditorState(document: initialDocument);

        expect(editorState.document.root.children.length, equals(3));

        editorState.replaceContentHTML('<p>Single paragraph</p>');

        expect(editorState.document.root.children.length, equals(1));
        expect(
          editorState.document.root.children.first.delta?.toPlainText(),
          equals('Single paragraph'),
        );
      });
    });

    group('clear', () {
      setUpAll(() {
        WidgetsFlutterBinding.ensureInitialized();
      });
      test('clears content from non-empty document', () async {
        final document =
            Document.blank()..insert(
              [0],
              [
                paragraphNode(text: 'First paragraph'),
                paragraphNode(text: 'Second paragraph'),
              ],
            );
        final editorState = EditorState(document: document);

        expect(editorState.document.root.children.length, equals(2));

        editorState.clear();
        // should only be one empty paragraph
        expect(editorState.document.root.children.length, equals(1));
        expect(editorState.intoHtml(), equals('<br>'));
      });

      test('does nothing when document is already empty', () async {
        final editorState = EditorState.blank();

        expect(editorState.document.root.children.length, equals(1));

        editorState.clear();

        expect(editorState.document.root.children.length, equals(1));
      });

      test('handles clearing with complex document structure', () async {
        final document =
            Document.blank()..insert(
              [0],
              [
                headingNode(text: 'Title', level: 1),
                paragraphNode(text: 'Paragraph'),
                bulletedListNode(
                  children: [
                    paragraphNode(text: 'Item 1'),
                    paragraphNode(text: 'Item 2'),
                  ],
                ),
                numberedListNode(
                  children: [
                    paragraphNode(text: 'Numbered 1'),
                    paragraphNode(text: 'Numbered 2'),
                  ],
                ),
              ],
            );
        final editorState = EditorState(document: document);

        expect(editorState.document.root.children.length, equals(4));

        editorState.clear();

        // should only be one empty paragraph
        expect(editorState.document.root.children.length, equals(1));
        expect(editorState.intoHtml(), equals('<br>'));
      });
    });

    group('Integration tests', () {
      setUpAll(() {
        WidgetsFlutterBinding.ensureInitialized();
      });
      test('full cycle: create, modify, convert to markdown and HTML', () {
        // Create editor state with HTML content
        final editorState = ActerEditorStateHelpers.fromContent(
          'Fallback text',
          '<h1>Title</h1><p>Paragraph with <strong>bold</strong> text.</p>',
        );

        // Verify initial content
        expect(editorState.document.root.children.length, equals(2));
        expect(
          editorState.document.root.children[0].delta?.toPlainText(),
          equals('Title'),
        );

        // Convert to markdown
        final markdown = editorState.intoMarkdown();
        expect(markdown, equals('# Title\nParagraph with **bold** text.'));

        // Convert to HTML
        final html = editorState.intoHtml();
        expect(
          html,
          equals(
            '<h1>Title</h1><p>Paragraph with <strong>bold</strong> text.</p>',
          ),
        );

        // Replace content
        editorState.replaceContent('New content', '<p>Updated content</p>');

        // Verify updated content
        expect(
          editorState.document.root.children.first.delta?.toPlainText(),
          equals('Updated content'),
        );

        // Clear content
        editorState.clear();
        // should only be one empty paragraph
        expect(editorState.document.root.children.length, equals(1));
        expect(editorState.intoHtml(), equals('<br>'));
      });
    });
  });
}
