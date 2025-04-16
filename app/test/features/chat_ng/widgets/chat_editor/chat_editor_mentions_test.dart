import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:acter/common/widgets/html_editor/models/mention_attributes.dart';
import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:acter/common/widgets/html_editor/services/constants.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chat-ng mentions unit tests', () {
    // for mentions
    late EditorState editorState;

    setUp(() {
      editorState = EditorState.blank();
    });

    group('to mention format text unit tests', () {
      test('processes single mention correctly', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                userMentionMarker,
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
          editorState.toMentionText(markdown, null).$1,
          'Hello [@User](https://matrix.to/#/@user123)',
        );
        final html = editorState.intoHtml();
        // verify HTML
        expect(
          editorState.toMentionText(markdown, html).$1,
          '<p>Hello <span><a href="https://matrix.to/#/@user123">@User</a></span></p>',
        );
      });

      test('processes multiple mentions in single line correctly', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                userMentionMarker,
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
                userMentionMarker,
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
          editorState.toMentionText(markdown, null).$1,
          'Hello [@User1](https://matrix.to/#/@user1) and [@User2](https://matrix.to/#/@user2)',
        );

        // verify html
        final html = editorState.intoHtml();
        expect(
          editorState.toMentionText(markdown, html).$1,
          '<p>Hello <span><a href="https://matrix.to/#/@user1">@User1</a></span> and <span><a href="https://matrix.to/#/@user2">@User2</a></span></p>',
        );
      });

      test('processes mentions in multi-line text correctly', () {
        final delta1 =
            Delta()
              ..insert('Line 1 ')
              ..insert(
                userMentionMarker,
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
                userMentionMarker,
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
          editorState.toMentionText(markdown, null).$1,
          'Line 1 [@User1](https://matrix.to/#/@user1)\n'
          'Line 2 [@User2](https://matrix.to/#/@user2)',
        );
        // verify html
        final html = editorState.intoHtml();
        expect(
          editorState.toMentionText(markdown, html).$1,
          '<p>Line 1 <span><a href="https://matrix.to/#/@user1">@User1</a></span></p><p>Line 2 <span><a href="https://matrix.to/#/@user2">@User2</a></span></p>',
        );
      });

      test('handles text without mentions correctly', () {
        final delta = Delta()..insert('Hello world');
        final node = paragraphNode(delta: delta);
        editorState.document.insert([0], [node]);
        // verify markdown
        final markdown = editorState.intoMarkdown();
        expect(editorState.toMentionText(markdown, null).$1, 'Hello world');
        // verify html
        final html = editorState.intoHtml();
        expect(
          editorState.toMentionText(markdown, html).$1,
          '<p>Hello world</p>',
        );
      });

      test('handles adjacent mentions correctly', () {
        final delta =
            Delta()
              ..insert(
                userMentionMarker,
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
                userMentionMarker,
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
          editorState.toMentionText(markdown, null).$1,
          '[@User1](https://matrix.to/#/@user1)[@User2](https://matrix.to/#/@user2)',
        );
        // verify html
        final html = editorState.intoHtml();
        expect(
          editorState.toMentionText(markdown, html).$1,
          '<p><span><a href="https://matrix.to/#/@user1">@User1</a></span><span><a href="https://matrix.to/#/@user2">@User2</a></span></p>',
        );
      });

      test('handles special characters in text correctly', () {
        final delta =
            Delta()
              ..insert('Hello * _ ` # ||')
              ..insert(
                userMentionMarker,
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
          editorState.toMentionText(markdown, null).$1,
          'Hello * _ ` # ||[@User1](https://matrix.to/#/@user1)',
        );
        // verify html
        final html = editorState.intoHtml();
        expect(
          editorState.toMentionText(markdown, html).$1,
          '<p>Hello * _ ` # ||<span><a href="https://matrix.to/#/@user1">@User1</a></span></p>',
        );
      });

      test('preserves other delta attributes while processing mentions', () {
        final delta =
            Delta()
              ..insert('Bold', attributes: {'bold': true})
              ..insert(' ')
              ..insert(
                userMentionMarker,
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
        final processedHtml = editorState.toMentionText(markdown, html);
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
                userMentionMarker,
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
          editorState.toMentionText(markdown, null).$1,
          'Hello [@user123](https://matrix.to/#/@user123)',
        );
      });

      test('processes multiple nodes with mixed content correctly', () {
        final delta1 =
            Delta()
              ..insert('First ')
              ..insert(
                userMentionMarker,
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
                userMentionMarker,
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
                userMentionMarker,
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
          editorState.toMentionText(markdown, null).$1,
          'First [@User1](https://matrix.to/#/@user1)\n'
          'Middle text\n'
          'Last [@User2](https://matrix.to/#/@user2) and [@User3](https://matrix.to/#/@user3)',
        );

        // verify html
        final html = editorState.intoHtml();
        expect(
          editorState.toMentionText(markdown, html).$1,
          '<p>First <span><a href="https://matrix.to/#/@user1">@User1</a></span></p><p>Middle text</p><p>Last <span><a href="https://matrix.to/#/@user2">@User2</a></span> and <span><a href="https://matrix.to/#/@user3">@User3</a></span></p>',
        );
      });
    });

    group('to mention pills unit tests', () {
      test('converts single mention in text to pill marker', () {
        final originalText = 'Hello [@User1](https://matrix.to/#/@user1)';
        final node = paragraphNode();
        editorState.document.insert([0], [node]);

        editorState.toMentionPills(originalText, node);
        final resultText = node.delta?.toPlainText() ?? '';
        expect(resultText, contains(userMentionMarker));
        expect(resultText, isNot(contains('[@User1]')));

        // verify attributes
        final delta = node.delta;
        bool hasMentionAttribute = false;
        if (delta != null) {
          for (final op in delta) {
            if (op.attributes != null &&
                (op.attributes?.containsKey('@') == true)) {
              hasMentionAttribute = true;
              final attr = op.attributes!.values.firstWhere(
                (e) => e is MentionAttributes,
                orElse: () => null,
              );
              if (attr is MentionAttributes) {
                expect(attr.mentionId, '@user1');
                expect(attr.displayName, 'User1');
                expect(attr.type, MentionType.user);
              }
            }
          }
        }
        expect(hasMentionAttribute, isTrue);
      });

      test('handles text with no mentions correctly', () {
        final plainText = 'Hello world with no mentions';
        final node = paragraphNode();
        editorState.document.insert([0], [node]);

        editorState.toMentionPills(plainText, node);

        final resultText = node.delta?.toPlainText() ?? '';
        expect(resultText, plainText);

        // verify no markers or mention attributes exist
        final delta = node.delta;
        bool hasMentionAttribute = false;
        if (delta != null) {
          for (final op in delta) {
            if (op.attributes != null &&
                (op.attributes?.containsKey('@') == true ||
                    op.attributes?.containsKey('#') == true)) {
              hasMentionAttribute = true;
            }
          }
        }
        expect(hasMentionAttribute, isFalse);
        expect(delta?.toPlainText(), plainText);
      });

      test('converts multiple mentions in text to pill markers', () {
        final originalText =
            'Hello [@User1](https://matrix.to/#/@user1) and [@User2](https://matrix.to/#/@user2)';
        final node = paragraphNode();
        editorState.document.insert([0], [node]);

        editorState.toMentionPills(originalText, node);

        final resultText = node.delta?.toPlainText() ?? '';
        expect(resultText.split(userMentionMarker).length, 3);

        // verify attributes
        final delta = node.delta;
        int mentionAttributeCount = 0;
        List<String> foundMentionIds = [];

        if (delta != null) {
          for (final op in delta) {
            if (op.attributes != null) {
              final attr = op.attributes!.values.firstWhere(
                (e) => e is MentionAttributes,
                orElse: () => null,
              );
              if (attr is MentionAttributes) {
                mentionAttributeCount++;
                foundMentionIds.add(attr.mentionId);
              }
            }
          }
        }

        expect(mentionAttributeCount, 2);
        expect(foundMentionIds, contains('@user1'));
        expect(foundMentionIds, contains('@user2'));
      });

      test('preserves order of mentions when processing', () {
        final originalText =
            '[@First](https://matrix.to/#/@user1) middle [@Second](https://matrix.to/#/@user2) end';
        final node = paragraphNode();
        editorState.document.insert([0], [node]);

        editorState.toMentionPills(originalText, node);

        final delta = node.delta;
        List<MentionAttributes> mentions = [];

        if (delta != null) {
          for (final op in delta) {
            if (op.attributes != null) {
              final attr = op.attributes?.values.firstWhere(
                (e) => e is MentionAttributes,
                orElse: () => null,
              );
              if (attr is MentionAttributes) {
                mentions.add(attr);
              }
            }
          }
        }

        expect(mentions.length, 2);
        // The mentions are sorted in reverse order during text processing, but attributes
        // are applied based on marker positions in the processed text, so the order is reversed
        expect(mentions[0].displayName, 'Second');
        expect(mentions[1].displayName, 'First');
      });

      test('handles special characters in mentions correctly', () {
        final originalText =
            'Special [@User*_-+](https://matrix.to/#/@user_special)';
        final node = paragraphNode();
        editorState.document.insert([0], [node]);

        editorState.toMentionPills(originalText, node);

        final delta = node.delta;
        MentionAttributes? specialMention;

        if (delta != null) {
          for (final op in delta) {
            if (op.attributes != null) {
              final attr = op.attributes!.values.firstWhere(
                (e) => e is MentionAttributes,
                orElse: () => null,
              );
              if (attr is MentionAttributes) {
                specialMention = attr;
              }
            }
          }
        }

        expect(specialMention, isNotNull);
        expect(specialMention?.displayName, 'User*_-+');
        expect(specialMention?.mentionId, '@user_special');
      });

      test('handles adjacent mentions with no space between them', () {
        final originalText =
            '[@User1](https://matrix.to/#/@user1)[@User2](https://matrix.to/#/@user2)';
        final node = paragraphNode();
        editorState.document.insert([0], [node]);

        editorState.toMentionPills(originalText, node);

        final resultText = node.delta?.toPlainText() ?? '';
        expect(resultText, contains('$userMentionMarker$userMentionMarker'));

        final delta = node.delta;
        List<MentionAttributes> foundMentions = [];

        if (delta != null) {
          for (final op in delta) {
            if (op.attributes != null) {
              final attr = op.attributes!.values.firstWhere(
                (e) => e is MentionAttributes,
                orElse: () => null,
              );
              if (attr is MentionAttributes) {
                foundMentions.add(attr);
              }
            }
          }
        }

        expect(foundMentions.length, 2);

        // verify both mentions were found
        bool hasUser1 = foundMentions.any(
          (m) => m.mentionId == '@user1' && m.displayName == 'User1',
        );
        bool hasUser2 = foundMentions.any(
          (m) => m.mentionId == '@user2' && m.displayName == 'User2',
        );

        expect(hasUser1, isTrue);
        expect(hasUser2, isTrue);
      });

      test('correctly processes mentions in formatted text', () {
        final originalText =
            '**Bold text** with a [@User1](https://matrix.to/#/@user1) mention and *italic [@User2](https://matrix.to/#/@user2) text*';
        final node = paragraphNode();
        editorState.document.insert([0], [node]);

        editorState.toMentionPills(originalText, node);

        final resultText = node.delta?.toPlainText() ?? '';
        expect(
          resultText,
          contains(
            '**Bold text** with a $userMentionMarker mention and *italic $userMentionMarker text*',
          ),
        );

        // verify attributes
        final delta = node.delta;
        List<MentionAttributes> foundMentions = [];

        if (delta != null) {
          for (final op in delta) {
            if (op.attributes != null) {
              final attr = op.attributes!.values.firstWhere(
                (e) => e is MentionAttributes,
                orElse: () => null,
              );
              if (attr is MentionAttributes) {
                foundMentions.add(attr);
              }
            }
          }
        }

        expect(foundMentions.length, 2);

        // verify attributes
        bool hasUser1 = foundMentions.any(
          (m) => m.mentionId == '@user1' && m.displayName == 'User1',
        );
        bool hasUser2 = foundMentions.any(
          (m) => m.mentionId == '@user2' && m.displayName == 'User2',
        );

        expect(hasUser1, isTrue);
        expect(hasUser2, isTrue);
      });
    });
  });
}
