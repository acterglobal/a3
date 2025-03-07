import 'package:acter/features/chat/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

void main() {
  late Document document;

  setUp(() {
    document = Document();
  });

  group('User mention chat message parsing test -', () {
    test('Parse massage with one instance of user mention', () {
      String msg =
          '<p>hello <a href="https://matrix.to/#/@acter1:matrix.org">acter1</a></p>';

      Element aTagElement = document.createElement('a');
      aTagElement.innerHtml = 'acter1';
      final attributes = {'href': 'https://matrix.to/#/@acter1:matrix.org'};
      aTagElement.attributes.addAll(attributes);

      final resultData = parseUserMentionMessage(msg, aTagElement);

      final messageDocument = parse(resultData.parsedMessage);
      final messageBodyText = messageDocument.body?.text ?? '';
      expect(messageBodyText, 'hello acter1');
    });

    test('Parse massage with multiple instances of different user mentions', () {
      String msg =
          '<p>hello <a href="https://matrix.to/#/@acter2:matrix.org">acter2</a> <a href="https://matrix.to/#/@acter1:matrix.org">acter1</a></p>';

      Element aTagElement1 = document.createElement('a');
      aTagElement1.innerHtml = 'acter2';
      final attributes1 = {'href': 'https://matrix.to/#/@acter2:matrix.org'};
      aTagElement1.attributes.addAll(attributes1);

      Element aTagElement2 = document.createElement('a');
      aTagElement2.innerHtml = 'acter1';
      final attributes2 = {'href': 'https://matrix.to/#/@acter1:matrix.org'};
      aTagElement2.attributes.addAll(attributes2);

      document.append(aTagElement1);
      document.append(aTagElement2);

      final aTagElementList = document.getElementsByTagName('a');
      for (final aTagElement in aTagElementList) {
        final resultData = parseUserMentionMessage(msg, aTagElement);
        msg = resultData.parsedMessage;
      }

      final messageDocument = parse(msg);
      final messageBodyText = messageDocument.body?.text ?? '';
      expect(messageBodyText, 'hello acter2 acter1');
    });

    test('Parse massage with duplicate instances of user mentions', () {
      String msg =
          '<p>hello <a href="https://matrix.to/#/@acter2:matrix.org">acter2</a> <a href="https://matrix.to/#/@acter2:matrix.org">acter2</a></p>';

      Element aTagElement1 = document.createElement('a');
      aTagElement1.innerHtml = 'acter2';
      final attributes1 = {'href': 'https://matrix.to/#/@acter2:matrix.org'};
      aTagElement1.attributes.addAll(attributes1);

      document.append(aTagElement1);
      document.append(aTagElement1);

      final aTagElementList = document.getElementsByTagName('a');
      for (final aTagElement in aTagElementList) {
        final resultData = parseUserMentionMessage(msg, aTagElement);
        msg = resultData.parsedMessage;
      }

      final messageDocument = parse(msg);
      final messageBodyText = messageDocument.body?.text ?? '';
      expect(messageBodyText, 'hello acter2 acter2');
    });

    test(
      'Parse massage with multiple instances of user mentions and one duplicate mention',
      () {
        String msg =
            '<p>hello <a href="https://matrix.to/#/@acter2:matrix.org">acter2</a> <a href="https://matrix.to/#/@acter1:matrix.org">acter1</a> <a href="https://matrix.to/#/@acter2:matrix.org">acter2</a></p>';

        Element aTagElement1 = document.createElement('a');
        aTagElement1.innerHtml = 'acter2';
        final attributes1 = {'href': 'https://matrix.to/#/@acter2:matrix.org'};
        aTagElement1.attributes.addAll(attributes1);

        Element aTagElement2 = document.createElement('a');
        aTagElement2.innerHtml = 'acter1';
        final attributes2 = {'href': 'https://matrix.to/#/@acter1:matrix.org'};
        aTagElement2.attributes.addAll(attributes2);

        document.append(aTagElement1);
        document.append(aTagElement2);
        document.append(aTagElement1);

        final aTagElementList = document.getElementsByTagName('a');
        for (final aTagElement in aTagElementList) {
          final resultData = parseUserMentionMessage(msg, aTagElement);
          msg = resultData.parsedMessage;
        }

        final messageDocument = parse(msg);
        final messageBodyText = messageDocument.body?.text ?? '';
        expect(messageBodyText, 'hello acter2 acter1 acter2');
      },
    );

    test(
      'Parse massage with multiple instances of user mentions and multiple duplicate mentions',
      () {
        String msg =
            '<p>hello <a href="https://matrix.to/#/@acter2:matrix.org">acter2</a> <a href="https://matrix.to/#/@acter1:matrix.org">acter1</a> <a href="https://matrix.to/#/@acter2:matrix.org">acter2</a> <a href="https://matrix.to/#/@acter1:matrix.org">acter1</a></p>';

        Element aTagElement1 = document.createElement('a');
        aTagElement1.innerHtml = 'acter2';
        final attributes1 = {'href': 'https://matrix.to/#/@acter2:matrix.org'};
        aTagElement1.attributes.addAll(attributes1);

        Element aTagElement2 = document.createElement('a');
        aTagElement2.innerHtml = 'acter1';
        final attributes2 = {'href': 'https://matrix.to/#/@acter1:matrix.org'};
        aTagElement2.attributes.addAll(attributes2);

        document.append(aTagElement1);
        document.append(aTagElement2);
        document.append(aTagElement1);
        document.append(aTagElement2);

        final aTagElementList = document.getElementsByTagName('a');
        for (final aTagElement in aTagElementList) {
          final resultData = parseUserMentionMessage(msg, aTagElement);
          msg = resultData.parsedMessage;
        }

        final messageDocument = parse(msg);
        final messageBodyText = messageDocument.body?.text ?? '';
        expect(messageBodyText, 'hello acter2 acter1 acter2 acter1');
      },
    );
  });

  group('Matrix room link parsing test -', () {
    test('Parse private room link - With "Via home sever" details', () {
      //Static
      String roodIdLink =
          'https://matrix.to/#/!zxDsxBeywEsePmARgd:m-1.acter.global?via=m-1.acter.global';

      final resultData = getRoomIdFromLink(Uri.parse(roodIdLink));

      expect(resultData, '!zxDsxBeywEsePmARgd:m-1.acter.global');
    });

    test('Parse private room link - Without "Via home sever" details', () {
      String roodIdLink =
          'https://matrix.to/#/!zxDsxBeywEsePmARgd:m-1.acter.global';

      final resultData = getRoomIdFromLink(Uri.parse(roodIdLink));

      expect(resultData, '!zxDsxBeywEsePmARgd:m-1.acter.global');
    });

    test('Parse public room link - With "#" sign at the starting of link', () {
      String roodIdLink = 'https://matrix.to/#/#acterroom2:matrix.org';

      final resultData = getRoomIdFromLink(Uri.parse(roodIdLink));

      expect(resultData, '#acterroom2:matrix.org');
    });

    test(
      'Parse public room link - With "%23" sign at the starting of link',
      () {
        String roodIdLink = 'https://matrix.to/#/%23acterroom123:matrix.org';

        final resultData = getRoomIdFromLink(Uri.parse(roodIdLink));

        expect(resultData, '#acterroom123:matrix.org');
      },
    );

    test('Parse invalid room link', () {
      String roodIdLink = 'https://matrix.to/#/#acterroom2';

      final resultData = getRoomIdFromLink(Uri.parse(roodIdLink));

      expect(resultData, null);
    });

    test('Parse link which is other than room link', () {
      String roodIdLink = 'https://www.google.com';

      final resultData = getRoomIdFromLink(Uri.parse(roodIdLink));

      expect(resultData, null);
    });
  });
}
