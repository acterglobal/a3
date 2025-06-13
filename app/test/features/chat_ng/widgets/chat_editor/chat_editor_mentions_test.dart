import 'package:acter/common/toolkit/html_editor/html_editor.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chat-ng mentions tests', () {
    // for mentions
    late EditorState editorState;

    setUp(() {
      editorState = EditorState.blank();
    });

    test('handles text without user mentions correctly', () {
      final delta = Delta()..insert('Hello world');
      final node = paragraphNode(delta: delta);
      editorState.document.insert([0], [node]);

      final mentions = editorState.getMentions('', null);
      expect(mentions.length, 0);
    });

    group('user mention detection unit tests', () {
      test('detects user single mention correctly', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                'User',
                attributes: {'href': 'matrix:u/user123', 'inline': true},
              );
        final node = paragraphNode(delta: delta);
        editorState.document.insert([0], [node]);

        final mentions = editorState.getMentions('', null);
        expect(mentions.length, 1);
        expect(mentions[0], '@user123');
      });

      test('detects user multiple mentions correctly', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                'User1',
                attributes: {'href': 'matrix:u/user1', 'inline': true},
              )
              ..insert(' and ')
              ..insert(
                'User2',
                attributes: {'href': 'matrix:u/user2', 'inline': true},
              );
        final node = paragraphNode(delta: delta);
        editorState.document.insert([0], [node]);

        final mentions = editorState.getMentions('', null);
        expect(mentions.length, 2);
        expect(mentions, contains('@user1'));
        expect(mentions, contains('@user2'));
      });
    });

    group('room mention detection unit tests', () {
      test('detects room single mention correctly', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                'Room',
                attributes: {'href': 'matrix:roomid/room123', 'inline': true},
              );
        final node = paragraphNode(delta: delta);
        editorState.document.insert([0], [node]);

        final mentions = editorState.getMentions('', null);
        expect(mentions.length, 1);
        expect(mentions[0], '!room123');
      });

      test('detects room multiple mentions correctly', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                'Room1',
                attributes: {'href': 'matrix:roomid/room1', 'inline': true},
              )
              ..insert(' and ')
              ..insert(
                'Room2',
                attributes: {'href': 'matrix:roomid/room2', 'inline': true},
              );
        final node = paragraphNode(delta: delta);
        editorState.document.insert([0], [node]);

        final mentions = editorState.getMentions('', null);
        expect(mentions.length, 2);
        expect(mentions, contains('!room1'));
        expect(mentions, contains('!room2'));
      });
    });

    group('mention format plain and html tests', () {
      late EditorState editorState;
      setUp(() {
        editorState = EditorState.blank();
      });

      test('plain text with single user mention', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                'User1',
                attributes: {'href': 'matrix:u/user1', 'inline': true},
              );
        final node = paragraphNode(delta: delta);
        final transaction = editorState.transaction;
        transaction.insertNode([0], node);
        editorState.apply(transaction, withUpdateSelection: false);
        final plainText = editorState.intoMarkdown().trimRight();
        expect(plainText, 'Hello [User1](matrix:u/user1)');
      });

      test('html text with single user mention', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                'User1',
                attributes: {'href': 'matrix:u/user1', 'inline': true},
              );
        final node = paragraphNode(delta: delta);
        final transaction = editorState.transaction;
        transaction.insertNode([0], node);
        editorState.apply(transaction, withUpdateSelection: false);
        // <null> is mention chip placeholder, remove it for testing
        final html = editorState
            .intoHtml()
            .replaceAll(RegExp(r'<null>|</null>'), '')
            .replaceAll('<br>', '');
        expect(html, '<p>Hello <a href="matrix:u/user1">User1</a></p>');
      });

      test('plain text with multiple user mentions', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                'User1',
                attributes: {'href': 'matrix:u/user1', 'inline': true},
              )
              ..insert(' and ')
              ..insert(
                'User2',
                attributes: {'href': 'matrix:u/user2', 'inline': true},
              );
        final node = paragraphNode(delta: delta);
        final transaction = editorState.transaction;
        transaction.insertNode([0], node);
        editorState.apply(transaction, withUpdateSelection: false);
        final plainText = editorState.intoMarkdown().trimRight();
        expect(
          plainText,
          'Hello [User1](matrix:u/user1) and [User2](matrix:u/user2)',
        );
      });

      test('html text with multiple user mentions', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                'User1',
                attributes: {'href': 'matrix:u/user1', 'inline': true},
              )
              ..insert(' and ')
              ..insert(
                'User2',
                attributes: {'href': 'matrix:u/user2', 'inline': true},
              );
        final node = paragraphNode(delta: delta);
        final transaction = editorState.transaction;
        transaction.insertNode([0], node);
        editorState.apply(transaction, withUpdateSelection: false);
        // <null> is mention chip placeholder, remove it for testing
        final html = editorState
            .intoHtml()
            .replaceAll(RegExp(r'<null>|</null>'), '')
            .replaceAll('<br>', '');
        expect(
          html,
          '<p>Hello <a href="matrix:u/user1">User1</a> and <a href="matrix:u/user2">User2</a></p>',
        );
      });

      test('plain text with single room mention', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                'Room1',
                attributes: {'href': 'matrix:roomid/room1', 'inline': true},
              );
        final node = paragraphNode(delta: delta);
        final transaction = editorState.transaction;
        transaction.insertNode([0], node);
        editorState.apply(transaction, withUpdateSelection: false);
        final plainText = editorState.intoMarkdown().trimRight();
        expect(plainText, 'Hello [Room1](matrix:roomid/room1)');
      });

      test('html text with single room mention', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                'Room1',
                attributes: {'href': 'matrix:roomid/room1', 'inline': true},
              );
        final node = paragraphNode(delta: delta);
        final transaction = editorState.transaction;
        transaction.insertNode([0], node);
        editorState.apply(transaction, withUpdateSelection: false);
        // <null> is mention chip placeholder, remove it for testing
        final html = editorState
            .intoHtml()
            .replaceAll(RegExp(r'<null>|</null>'), '')
            .replaceAll('<br>', '');
        expect(html, '<p>Hello <a href="matrix:roomid/room1">Room1</a></p>');
      });

      test('plain text with multiple room mentions', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                'Room1',
                attributes: {'href': 'matrix:roomid/room1', 'inline': true},
              )
              ..insert(' and ')
              ..insert(
                'Room2',
                attributes: {'href': 'matrix:roomid/room2', 'inline': true},
              );
        final node = paragraphNode(delta: delta);
        final transaction = editorState.transaction;
        transaction.insertNode([0], node);
        editorState.apply(transaction, withUpdateSelection: false);
        final plainText = editorState.intoMarkdown().trimRight();
        expect(
          plainText,
          'Hello [Room1](matrix:roomid/room1) and [Room2](matrix:roomid/room2)',
        );
      });

      test('html text with multiple room mentions', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                'Room1',
                attributes: {'href': 'matrix:roomid/room1', 'inline': true},
              )
              ..insert(' and ')
              ..insert(
                'Room2',
                attributes: {'href': 'matrix:roomid/room2', 'inline': true},
              );
        final node = paragraphNode(delta: delta);
        final transaction = editorState.transaction;
        transaction.insertNode([0], node);
        editorState.apply(transaction, withUpdateSelection: false);
        // <null> is mention chip placeholder, remove it for testing
        final html = editorState
            .intoHtml()
            .replaceAll(RegExp(r'<null>|</null>'), '')
            .replaceAll('<br>', '');
        expect(
          html,
          '<p>Hello <a href="matrix:roomid/room1">Room1</a> and <a href="matrix:roomid/room2">Room2</a></p>',
        );
      });

      test('plain text with user and room mentions', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                'User1',
                attributes: {'href': 'matrix:u/user1', 'inline': true},
              )
              ..insert(' and ')
              ..insert(
                'Room1',
                attributes: {'href': 'matrix:roomid/room1', 'inline': true},
              );
        final node = paragraphNode(delta: delta);
        final transaction = editorState.transaction;
        transaction.insertNode([0], node);
        editorState.apply(transaction, withUpdateSelection: false);
        final plainText = editorState.intoMarkdown().trimRight();
        expect(
          plainText,
          'Hello [User1](matrix:u/user1) and [Room1](matrix:roomid/room1)',
        );
      });

      test('html text with user and room mentions', () {
        final delta =
            Delta()
              ..insert('Hello ')
              ..insert(
                'User1',
                attributes: {'href': 'matrix:u/user1', 'inline': true},
              )
              ..insert(' and ')
              ..insert(
                'Room1',
                attributes: {'href': 'matrix:roomid/room1', 'inline': true},
              );
        final node = paragraphNode(delta: delta);
        final transaction = editorState.transaction;
        transaction.insertNode([0], node);
        editorState.apply(transaction, withUpdateSelection: false);
        // <null> is mention chip placeholder, remove it for testing
        final html = editorState
            .intoHtml()
            .replaceAll(RegExp(r'<null>|</null>'), '')
            .replaceAll('<br>', '');
        expect(
          html,
          '<p>Hello <a href="matrix:u/user1">User1</a> and <a href="matrix:roomid/room1">Room1</a></p>',
        );
      });
    });
  });
}
