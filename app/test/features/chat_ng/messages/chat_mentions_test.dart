import 'package:acter/common/widgets/html_editor/models/mention_attributes.dart';
import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

typedef ParsedContent = ({
  List<String> mentions,
  List<String> textPieces,
  List<Map<String, dynamic>> attributes
});

ParsedContent parseDocumentContent(Document document) {
  final mentions = <String>[];
  final textPieces = <String>[];
  final attributes = <Map<String, dynamic>>[];

  for (final node in document.root.children) {
    if (node.delta != null) {
      final operations = node.delta!.toList();
      for (final op in operations) {
        final mentionAttr = op.attributes?.entries
            .firstWhereOrNull((e) => e.value is MentionAttributes)
            ?.value as MentionAttributes?;

        if (mentionAttr != null && mentionAttr.type == MentionType.user) {
          mentions.add(mentionAttr.mentionId);
          textPieces.add('@${mentionAttr.displayName}');
          attributes.add(op.attributes ?? {});
        } else if (op is TextInsert) {
          textPieces.add(op.text);
          attributes.add(op.attributes ?? {});
        }
      }
    }
  }

  return (mentions: mentions, textPieces: textPieces, attributes: attributes);
}

void main() {
  group('mentions parsing', () {
    final editorState = EditorState.blank();
    final node = paragraphNode(delta: Delta()..insert(''));
    editorState.document.insert([0], [node]);
    test(
      'verify multiple mentions with simple plain text',
      () async {
        final transaction = editorState.transaction;
        transaction.replaceText(node, 0, 0, 'Hello ');

        // First mention
        transaction.replaceText(
          node,
          6,
          0,
          ' ',
          attributes: {
            '@': MentionAttributes(
              type: MentionType.user,
              mentionId: '@user1:acter.global',
              displayName: 'User1',
            ),
          },
        );

        transaction.replaceText(node, 7, 0, ' and ');

        // Second mention
        transaction.replaceText(
          node,
          12,
          0,
          ' ',
          attributes: {
            '@': MentionAttributes(
              type: MentionType.user,
              mentionId: '@user2:acter.global',
              displayName: 'User2',
            ),
          },
        );

        transaction.replaceText(node, 13, 0, ', how are you?');

        await editorState.apply(transaction);

        final result = parseDocumentContent(editorState.document);
        // verify mentions
        expect(result.mentions, ['@user1:acter.global', '@user2:acter.global']);

        // verify order
        expect(
          result.textPieces,
          ['Hello ', '@User1', ' and ', '@User2', ', how are you?'],
        );
      },
    );

    test('verify multiple mentions with markdown/rich text', () {
      final transaction = editorState.transaction;

      // Bold text
      transaction.replaceText(
        node,
        0,
        0,
        'Important:',
        attributes: {'bold': true},
      );

      // First mention
      transaction.replaceText(
        node,
        10,
        0,
        ' ',
        attributes: {
          '@': MentionAttributes(
            type: MentionType.user,
            mentionId: '@user1:acter.global',
            displayName: 'User1',
          ),
        },
      );

      transaction.replaceText(node, 11, 0, ' needs review from ');

      // Second mention
      transaction.replaceText(
        node,
        30,
        0,
        ' ',
        attributes: {
          '@': MentionAttributes(
            type: MentionType.user,
            mentionId: '@user2:acter.global',
            displayName: 'User2',
          ),
        },
      );

      // italic text
      transaction.replaceText(
        node,
        31,
        0,
        ' for the project.',
        attributes: {'italic': true},
      );

      editorState.apply(transaction);

      final result = parseDocumentContent(editorState.document);

      // verify mentions
      expect(
        result.mentions,
        ['@user1:acter.global', '@user2:acter.global'],
      );

      // verify order
      expect(result.textPieces, [
        'Important:',
        '@User1',
        ' needs review from ',
        '@User2',
        ' for the project.',
      ]);

      // verify rich attributes
      expect(result.attributes[0]['bold'], isTrue);
      expect(result.attributes[4]['italic'], isTrue);
    });
  });
}
