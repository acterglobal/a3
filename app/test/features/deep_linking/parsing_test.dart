import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Testing matrix://-links', () {
    test('roomAlias', () async {
      final result = parseUri(Uri.parse('matrix:r/somewhere:example.org'));
      expect(result.type, LinkType.roomAlias);
      expect(result.target, '#somewhere:example.org');
      expect(result.via, []);
    });
    test('roomId', () async {
      final sourceUri =
          Uri.parse('matrix:roomid/room:acter.global?via=elsewhere.ca');
      final result = parseUri(sourceUri);
      expect(result.type, LinkType.roomId);
      expect(result.target, '!room:acter.global');
      expect(result.via, ['elsewhere.ca']);
    });
    test('userId', () async {
      final result =
          parseUri(Uri.parse('matrix:u/alice:acter.global?action=chat'));
      expect(result.type, LinkType.userId);
      expect(result.target, '@alice:acter.global');
    });
    test('eventId', () async {
      final result = parseUri(
        Uri.parse(
          'matrix:roomid/room:acter.global/e/someEvent?via=acter.global&via=example.org',
        ),
      );
      expect(result.type, LinkType.chatEvent);
      expect(result.target, '\$someEvent');
      expect(result.roomId, '!room:acter.global');
      expect(result.via, ['acter.global', 'example.org']);
    });
  });

  group('Testing https://matrix.to/-links', () {
    test('roomAlias', () async {
      final result =
          parseUri(Uri.parse('https://matrix.to/#/%23somewhere%3Aexample.org'));
      expect(result.type, LinkType.roomAlias);
      expect(result.target, '#somewhere:example.org');
      expect(result.via, []);
    });
    test('roomId', () async {
      final sourceUri = Uri.parse(
        'https://matrix.to/#/!room%3Aacter.global?via=elsewhere.ca',
      );
      final result = parseUri(sourceUri);
      expect(result.type, LinkType.roomId);
      expect(result.target, '!room:acter.global');
      expect(result.via, ['elsewhere.ca']);
    });
    test('userId', () async {
      final result =
          parseUri(Uri.parse('https://matrix.to/#/%40alice%3Aacter.global'));
      expect(result.type, LinkType.userId);
      expect(result.target, '@alice:acter.global');
    });
    test('eventId', () async {
      final result = parseUri(
        Uri.parse(
          'https://matrix.to/#/!room%3Aacter.global/%24someEvent%3Aexample.org?via=acter.global&via=example.org',
        ),
      );
      expect(result.type, LinkType.chatEvent);
      expect(result.target, '\$someEvent:example.org');
      expect(result.roomId, '!room:acter.global');
      expect(result.via, ['acter.global', 'example.org']);
    });
  });
  group('Testing fallback acter://-links', () {
    test('roomAlias', () async {
      final result = parseUri(Uri.parse('acter:r/somewhere:example.org'));
      expect(result.type, LinkType.roomAlias);
      expect(result.target, '#somewhere:example.org');
      expect(result.via, []);
    });
    test('roomId', () async {
      final sourceUri =
          Uri.parse('acter:roomid/room:acter.global?via=elsewhere.ca');
      final result = parseUri(sourceUri);
      expect(result.type, LinkType.roomId);
      expect(result.target, '!room:acter.global');
      expect(result.via, ['elsewhere.ca']);
    });
    test('userId', () async {
      final result =
          parseUri(Uri.parse('acter:u/alice:acter.global?action=chat'));
      expect(result.type, LinkType.userId);
      expect(result.target, '@alice:acter.global');
    });
    test('eventId', () async {
      final result = parseUri(
        Uri.parse(
          'acter:roomid/room:acter.global/e/someEvent?via=acter.global&via=example.org',
        ),
      );
      expect(result.type, LinkType.chatEvent);
      expect(result.target, '\$someEvent');
      expect(result.roomId, '!room:acter.global');
      expect(result.via, ['acter.global', 'example.org']);
    });
  });

  group('Testing acter:// object-links', () {
    test('calendarEvent', () async {
      final result = parseUri(
        Uri.parse('acter:o/somewhere:example.org/calendarEvent/spaceObjectId'),
      );
      expect(result.type, LinkType.spaceObject);
      expect(result.objectPath!.objectType, ObjectType.calendarEvent);
      expect(result.target, '\$spaceObjectId');
      expect(result.roomId, '!somewhere:example.org');
      expect(result.via, []);
    });
    test('pin', () async {
      final sourceUri =
          Uri.parse('acter:o/room:acter.global/pin/pinId?via=elsewhere.ca');
      final result = parseUri(sourceUri);
      expect(result.type, LinkType.spaceObject);
      expect(result.objectPath!.objectType, ObjectType.pin);
      expect(result.target, '\$pinId');
      expect(result.roomId, '!room:acter.global');
      expect(result.via, ['elsewhere.ca']);
    });
    test('boost', () async {
      final result =
          parseUri(Uri.parse('acter:o/another:acter.global/boost/boostId'));
      expect(result.type, LinkType.spaceObject);
      expect(result.objectPath!.objectType, ObjectType.boost);
      expect(result.target, '\$boostId');
      expect(result.roomId, '!another:acter.global');
      expect(result.via, []);
    });
    test('taskList', () async {
      final result = parseUri(
        Uri.parse(
          'acter:o/room:acter.global/taskList/someEvent?via=acter.global&via=example.org',
        ),
      );
      expect(result.type, LinkType.spaceObject);
      expect(result.objectPath!.objectType, ObjectType.taskList);
      expect(result.target, '\$someEvent');
      expect(result.roomId, '!room:acter.global');
      expect(result.via, ['acter.global', 'example.org']);
    });

    test('task', () async {
      final result = parseUri(
        Uri.parse(
          'acter:o/room:acter.global/taskList/listId/task/taskId?via=acter.global&via=example.org',
        ),
      );
      expect(result.type, LinkType.spaceObject);
      expect(result.objectPath!.objectType, ObjectType.taskList);
      expect(result.objectPath!.objectId, '\$listId');
      expect(result.objectPath!.child!.objectType, ObjectType.task);
      expect(result.objectPath!.child!.objectId, '\$taskId');
      expect(result.objectPath!.child!.child, null);
      expect(result.target, '\$listId');
      expect(result.roomId, '!room:acter.global');
      expect(result.via, ['acter.global', 'example.org']);
    });

    test('comment on task', () async {
      final result = parseUri(
        Uri.parse(
          'acter:o/room:acter.global/taskList/someEvent/task/taskId/comment/commentId?via=acter.global&via=example.org',
        ),
      );
      expect(result.type, LinkType.spaceObject);
      expect(result.objectPath!.objectType, ObjectType.taskList);
      expect(result.objectPath!.objectId, '\$someEvent');
      expect(result.objectPath!.child!.objectType, ObjectType.task);
      expect(result.objectPath!.child!.objectId, '\$taskId');
      expect(result.objectPath!.child!.child!.objectType, ObjectType.comment);
      expect(result.objectPath!.child!.child!.objectId, '\$commentId');
      expect(result.target, '\$someEvent');
      expect(result.roomId, '!room:acter.global');
      expect(result.via, ['acter.global', 'example.org']);
    });
  });

  group('Testing acter:// invite-links', () {
    test('simple invite', () async {
      final result = parseUri(
        Uri.parse('acter://acter.global/i/inviteCode'),
      );
      expect(result.type, LinkType.superInvite);
      expect(result.target, 'inviteCode');
      expect(result.roomId, null);
      expect(result.via, ['acter.global']);
      expect(result.preview.roomDisplayName, null);
    });
    test('with preview', () async {
      final result = parseUri(
        Uri.parse(
          'acter://acter.global/i/inviteCode?roomDisplayName=Room+Name&userId=ben:acter.global&userDisplayName=Ben+From+Acter',
        ),
      );
      expect(result.type, LinkType.superInvite);
      expect(result.target, 'inviteCode');
      expect(result.roomId, null);
      expect(result.via, ['acter.global']);
      expect(result.preview.roomDisplayName, 'Room Name');
      expect(result.preview.userDisplayName, 'Ben From Acter');
      expect(result.preview.userId, '@ben:acter.global');
    });
  });

  group('Testing acter:// preview data', () {
    test('calendarEvent', () async {
      final result = parseUri(
        Uri.parse(
          'acter:o/somewhere:example.org/calendarEvent/spaceObjectId?title=Our+Awesome+Event&startUtc=12334567&participants=3',
        ),
      );
      expect(result.type, LinkType.spaceObject);
      expect(result.objectPath!.objectType, ObjectType.calendarEvent);
      expect(result.target, '\$spaceObjectId');
      expect(result.roomId, '!somewhere:example.org');
      expect(result.preview.title, 'Our Awesome Event');
      expect(result.preview.extra['startUtc']?.firstOrNull, '12334567');
      expect(result.preview.extra['participants']?.firstOrNull, '3');
      expect(result.via, []);
    });

    test('comment on task', () async {
      final result = parseUri(
        Uri.parse(
          'acter:o/room:acter.global/taskList/someEvent/task/taskId/comment/commentId?via=acter.global&via=example.org&roomDisplayName=someRoom+Name',
        ),
      );
      expect(result.type, LinkType.spaceObject);
      expect(result.objectPath!.objectType, ObjectType.taskList);
      expect(result.objectPath!.objectId, '\$someEvent');
      expect(result.objectPath!.child!.objectType, ObjectType.task);
      expect(result.objectPath!.child!.objectId, '\$taskId');
      expect(result.objectPath!.child!.child!.objectType, ObjectType.comment);
      expect(result.objectPath!.child!.child!.objectId, '\$commentId');
      expect(result.target, '\$someEvent');
      expect(result.roomId, '!room:acter.global');
      expect(result.via, ['acter.global', 'example.org']);
      expect(result.preview.roomDisplayName, 'someRoom Name');
    });
  });
}
