import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:acter/common/widgets/html_editor/models/mention_attributes.dart';
import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chat-ng mentions unit tests', () {
    // for mentions
    final uniqueMarker = '‖';
    late EditorState editorState;

    setUp(() {
      editorState = EditorState.blank();
    });

    test('processes single mention correctly', () {
      final delta =
          Delta()
            ..insert('Hello ')
            ..insert(
              uniqueMarker,
              attributes: {
                '@': MentionAttributes(
                  type: MentionType.user,
                  mentionId: '@user123',
                  displayName: 'User',
                ),
                'inline': true,
              },
            );
      final node = paragraphNode(delta: delta);
      editorState.document.insert([0], [node]);
      final markdown = editorState.intoMarkdown();
      // verify markdown
      expect(
        editorState.mentionsParsedText(markdown, null).$1,
        'Hello [@User](https://matrix.to/#/@user123)',
      );
      final html = editorState.intoHtml();
      // verify HTML
      expect(
        editorState.mentionsParsedText(markdown, html).$1,
        '<p>Hello <span><a href="https://matrix.to/#/@user123">@User</a></span></p>',
      );
    });

    test('processes multiple mentions in single line correctly', () {
      final delta =
          Delta()
            ..insert('Hello ')
            ..insert(
              uniqueMarker,
              attributes: {
                '@': MentionAttributes(
                  type: MentionType.user,
                  mentionId: '@user1',
                  displayName: 'User1',
                ),
                'inline': true,
              },
            )
            ..insert(' and ')
            ..insert(
              uniqueMarker,
              attributes: {
                '@': MentionAttributes(
                  type: MentionType.user,
                  mentionId: '@user2',
                  displayName: 'User2',
                ),
                'inline': true,
              },
            );

      final node = paragraphNode(delta: delta);

      editorState.document.insert([0], [node]);
      // verify markdown
      final markdown = editorState.intoMarkdown();
      expect(
        editorState.mentionsParsedText(markdown, null).$1,
        'Hello [@User1](https://matrix.to/#/@user1) and [@User2](https://matrix.to/#/@user2)',
      );

      // verify html
      final html = editorState.intoHtml();
      expect(
        editorState.mentionsParsedText(markdown, html).$1,
        '<p>Hello <span><a href="https://matrix.to/#/@user1">@User1</a></span> and <span><a href="https://matrix.to/#/@user2">@User2</a></span></p>',
      );
    });

    test('processes mentions in multi-line text correctly', () {
      final delta1 =
          Delta()
            ..insert('Line 1 ')
            ..insert(
              uniqueMarker,
              attributes: {
                '@': MentionAttributes(
                  type: MentionType.user,
                  mentionId: '@user1',
                  displayName: 'User1',
                ),
                'inline': true,
              },
            );
      // First line
      final node1 = paragraphNode(delta: delta1);
      // Second line
      final delta2 =
          Delta()
            ..insert('Line 2 ')
            ..insert(
              uniqueMarker,
              attributes: {
                '@': MentionAttributes(
                  type: MentionType.user,
                  mentionId: '@user2',
                  displayName: 'User2',
                ),
                'inline': true,
              },
            );
      final node2 = paragraphNode(delta: delta2);
      editorState.document.insert([0], [node1]);
      editorState.document.insert([1], [node2]);
      // verify markdown
      final markdown = editorState.intoMarkdown();
      expect(
        editorState.mentionsParsedText(markdown, null).$1,
        'Line 1 [@User1](https://matrix.to/#/@user1)\n'
        'Line 2 [@User2](https://matrix.to/#/@user2)',
      );
      // verify html
      final html = editorState.intoHtml();
      expect(
        editorState.mentionsParsedText(markdown, html).$1,
        '<p>Line 1 <span><a href="https://matrix.to/#/@user1">@User1</a></span></p><p>Line 2 <span><a href="https://matrix.to/#/@user2">@User2</a></span></p>',
      );
    });

    test('handles text without mentions correctly', () {
      final delta = Delta()..insert('Hello world');
      final node = paragraphNode(delta: delta);
      editorState.document.insert([0], [node]);
      // verify markdown
      final markdown = editorState.intoMarkdown();
      expect(editorState.mentionsParsedText(markdown, null).$1, 'Hello world');
      // verify html
      final html = editorState.intoHtml();
      expect(
        editorState.mentionsParsedText(markdown, html).$1,
        '<p>Hello world</p>',
      );
    });

    test('handles adjacent mentions correctly', () {
      final delta =
          Delta()
            ..insert(
              uniqueMarker,
              attributes: {
                '@': MentionAttributes(
                  type: MentionType.user,
                  mentionId: '@user1',
                  displayName: 'User1',
                ),
                'inline': true,
              },
            )
            ..insert(
              uniqueMarker,
              attributes: {
                '@': MentionAttributes(
                  type: MentionType.user,
                  mentionId: '@user2',
                  displayName: 'User2',
                ),
                'inline': true,
              },
            );
      final node = paragraphNode(delta: delta);
      editorState.document.insert([0], [node]);
      // verify markdown
      final markdown = editorState.intoMarkdown();
      expect(
        editorState.mentionsParsedText(markdown, null).$1,
        '[@User1](https://matrix.to/#/@user1)[@User2](https://matrix.to/#/@user2)',
      );
      // verify html
      final html = editorState.intoHtml();
      expect(
        editorState.mentionsParsedText(markdown, html).$1,
        '<p><span><a href="https://matrix.to/#/@user1">@User1</a></span><span><a href="https://matrix.to/#/@user2">@User2</a></span></p>',
      );
    });

    test('handles special characters in text correctly', () {
      final delta =
          Delta()
            ..insert('Hello * _ ` # ||')
            ..insert(
              uniqueMarker,
              attributes: {
                '@': MentionAttributes(
                  type: MentionType.user,
                  mentionId: '@user1',
                  displayName: 'User1',
                ),
                'inline': true,
              },
            );
      final node = paragraphNode(delta: delta);

      editorState.document.insert([0], [node]);
      // verify markdown
      final markdown = editorState.intoMarkdown();
      expect(
        editorState.mentionsParsedText(markdown, null).$1,
        'Hello * _ ` # ||[@User1](https://matrix.to/#/@user1)',
      );
      // verify html
      final html = editorState.intoHtml();
      expect(
        editorState.mentionsParsedText(markdown, html).$1,
        '<p>Hello * _ ` # ||<span><a href="https://matrix.to/#/@user1">@User1</a></span></p>',
      );
    });

    test('preserves other delta attributes while processing mentions', () {
      final delta =
          Delta()
            ..insert('Bold', attributes: {'bold': true})
            ..insert(' ')
            ..insert(
              uniqueMarker,
              attributes: {
                '@': MentionAttributes(
                  type: MentionType.user,
                  mentionId: '@user1',
                  displayName: 'User1',
                ),
                'inline': true,
              },
            )
            ..insert(' italic', attributes: {'italic': true});
      final node = paragraphNode(delta: delta);

      editorState.document.insert([0], [node]);
      // verify markdown and html
      final markdown = editorState.intoMarkdown();
      final html = editorState.intoHtml();
      final processedHtml = editorState.mentionsParsedText(markdown, html);
      expect(processedHtml.$1.contains('<strong>'), true);
      expect(processedHtml.$1.contains('<i>'), true);
      expect(
        processedHtml.$1.contains(
          '<span><a href="https://matrix.to/#/@user1">@User1</a></span>',
        ),
        true,
      );
    });

    test('handles mentions with missing displayName correctly', () {
      final delta =
          Delta()
            ..insert('Hello ')
            ..insert(
              uniqueMarker,
              attributes: {
                '@': MentionAttributes(
                  type: MentionType.user,
                  mentionId: '@user123',
                  displayName: null,
                ),
              },
            );
      final node = paragraphNode(delta: delta);
      editorState.document.insert([0], [node]);
      // verify markdown
      final markdown = editorState.intoMarkdown();
      expect(
        editorState.mentionsParsedText(markdown, null).$1,
        'Hello [@user123](https://matrix.to/#/@user123)',
      );
    });

    test('processes multiple nodes with mixed content correctly', () {
      final delta1 =
          Delta()
            ..insert('First ')
            ..insert(
              uniqueMarker,
              attributes: {
                '@': MentionAttributes(
                  type: MentionType.user,
                  mentionId: '@user1',
                  displayName: 'User1',
                ),
                'inline': true,
              },
            );

      // node 1: text with mention
      final node1 = paragraphNode(delta: delta1);

      final delta2 = Delta()..insert('Middle text');
      // node 2: plain text
      final node2 = paragraphNode(delta: delta2);

      final delta3 =
          Delta()
            ..insert('Last ')
            ..insert(
              uniqueMarker,
              attributes: {
                '@': MentionAttributes(
                  type: MentionType.user,
                  mentionId: '@user2',
                  displayName: 'User2',
                ),
                'inline': true,
              },
            )
            ..insert(' and ')
            ..insert(
              uniqueMarker,
              attributes: {
                '@': MentionAttributes(
                  type: MentionType.user,
                  mentionId: '@user3',
                  displayName: 'User3',
                ),
                'inline': true,
              },
            );
      // node 3: Multiple mentions
      final node3 = paragraphNode(delta: delta3);

      editorState.document.insert([0], [node1]);
      editorState.document.insert([1], [node2]);
      editorState.document.insert([2], [node3]);
      // verify markdown
      final markdown = editorState.intoMarkdown();
      expect(
        editorState.mentionsParsedText(markdown, null).$1,
        'First [@User1](https://matrix.to/#/@user1)\n'
        'Middle text\n'
        'Last [@User2](https://matrix.to/#/@user2) and [@User3](https://matrix.to/#/@user3)',
      );

      // verify html
      final html = editorState.intoHtml();
      expect(
        editorState.mentionsParsedText(markdown, html).$1,
        '<p>First <span><a href="https://matrix.to/#/@user1">@User1</a></span></p><p>Middle text</p><p>Last <span><a href="https://matrix.to/#/@user2">@User2</a></span> and <span><a href="https://matrix.to/#/@user3">@User3</a></span></p>',
      );
    });
  });
}
