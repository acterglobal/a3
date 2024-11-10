import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Testing matrix://-links', () {
    test('roomAlias', () async {
      final result = parseUri(Uri.parse('matrix:r/somewhere:example.org'));
      expect(result!.type, LinkType.roomAlias);
      expect(result.target, '#somewhere:example.org');
      expect(result.via, []);
    });
    test('roomId', () async {
      final sourceUri =
          Uri.parse('matrix:roomid/room:acter.global?via=elsewhere.ca');
      final result = parseUri(sourceUri);
      expect(result!.type, LinkType.roomId);
      expect(result.target, '!room:acter.global');
      expect(result.via, ['elsewhere.ca']);
    });
    test('userId', () async {
      final result =
          parseUri(Uri.parse('matrix:u/alice:acter.global?action=chat'));
      expect(result!.type, LinkType.userId);
      expect(result.target, '@alice:acter.global');
    });
    test('eventId', () async {
      final result = parseUri(
        Uri.parse(
          'matrix:roomid/room:acter.global/e/someEvent?via=acter.global&via=example.org',
        ),
      );
      expect(result!.type, LinkType.chatEvent);
      expect(result.target, '\$someEvent');
      expect(result.roomId, '!room:acter.global');
      expect(result.via, ['acter.global', 'example.org']);
    });
  });
}
