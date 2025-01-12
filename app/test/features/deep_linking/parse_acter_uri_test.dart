import 'dart:convert';

import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/parse_acter_uri.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

typedef UriMaker = Uri Function(String path, String? query);

// re-usable test cases

void acterObjectLinksTests(UriMaker makeUri) {
  test('calendarEvent', () async {
    final result = parseActerUri(
      makeUri('o/somewhere:example.org/calendarEvent/spaceObjectId', null),
    );
    expect(result.type, LinkType.spaceObject);
    expect(result.objectPath!.objectType, ObjectType.calendarEvent);
    expect(result.target, '\$spaceObjectId');
    expect(result.roomId, '!somewhere:example.org');
    expect(result.via, []);
  });
  test('pin', () async {
    final sourceUri =
        makeUri('o/room:acter.global/pin/pinId', 'via=elsewhere.ca');
    final result = parseActerUri(sourceUri);
    expect(result.type, LinkType.spaceObject);
    expect(result.objectPath!.objectType, ObjectType.pin);
    expect(result.target, '\$pinId');
    expect(result.roomId, '!room:acter.global');
    expect(result.via, ['elsewhere.ca']);
  });
  test('boost', () async {
    final result =
        parseActerUri(makeUri('o/another:acter.global/boost/boostId', null));
    expect(result.type, LinkType.spaceObject);
    expect(result.objectPath!.objectType, ObjectType.boost);
    expect(result.target, '\$boostId');
    expect(result.roomId, '!another:acter.global');
    expect(result.via, []);
  });
  test('taskList', () async {
    final result = parseActerUri(
      makeUri(
        'o/room:acter.global/taskList/someEvent',
        'via=acter.global&via=example.org',
      ),
    );
    expect(result.type, LinkType.spaceObject);
    expect(result.objectPath!.objectType, ObjectType.taskList);
    expect(result.target, '\$someEvent');
    expect(result.roomId, '!room:acter.global');
    expect(result.via, ['acter.global', 'example.org']);
  });

  test('task', () async {
    final result = parseActerUri(
      makeUri(
        'o/room:acter.global/taskList/listId/task/taskId',
        'via=acter.global&via=example.org',
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
    final result = parseActerUri(
      makeUri(
        'o/room:acter.global/taskList/someEvent/task/taskId/comment/commentId',
        'via=acter.global&via=example.org',
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
}

void acterInviteLinkTests(UriMaker makeUri) {
  test('simple invite', () async {
    final result = parseActerUri(
      makeUri('i/acter.global/inviteCode', null),
    );
    expect(result.type, LinkType.superInvite);
    expect(result.target, 'inviteCode');
    expect(result.roomId, null);
    expect(result.via, ['acter.global']);
    expect(result.preview.roomDisplayName, null);
  });
  test('with preview', () async {
    final result = parseActerUri(
      makeUri(
        'i/acter.global/inviteCode',
        'roomDisplayName=Room+Name&userId=ben:acter.global&userDisplayName=Ben+From+Acter',
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
}

void acterObjectPreviewTests(UriMaker makeUri) {
  test('calendarEvent', () async {
    final result = parseActerUri(
      makeUri(
        'o/somewhere:example.org/calendarEvent/spaceObjectId',
        'title=Our+Awesome+Event&startUtc=12334567&participants=3',
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
    final result = parseActerUri(
      makeUri(
        'o/room:acter.global/taskList/someEvent/task/taskId/comment/commentId',
        'via=acter.global&via=example.org&roomDisplayName=someRoom+Name',
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
}

void newSpecLinksTests(UriMaker makeUri) {
  test('roomAlias', () async {
    final result = parseActerUri(makeUri('r/somewhere:example.org', null));
    expect(result.type, LinkType.roomAlias);
    expect(result.target, '#somewhere:example.org');
    expect(result.via, []);
  });
  test('roomId', () async {
    final sourceUri = makeUri('roomid/room:acter.global', 'via=elsewhere.ca');
    final result = parseActerUri(sourceUri);
    expect(result.type, LinkType.roomId);
    expect(result.target, '!room:acter.global');
    expect(result.via, ['elsewhere.ca']);
  });
  test('userId', () async {
    final result =
        parseActerUri(makeUri('u/alice:acter.global', 'action=chat'));
    expect(result.type, LinkType.userId);
    expect(result.target, '@alice:acter.global');
  });
  test('eventId', () async {
    final result = parseActerUri(
      makeUri(
        'roomid/room:acter.global/e/someEvent',
        'via=acter.global&via=example.org',
      ),
    );
    expect(result.type, LinkType.chatEvent);
    expect(result.target, '\$someEvent');
    expect(result.roomId, '!room:acter.global');
    expect(result.via, ['acter.global', 'example.org']);
  });
}

UriMaker makeUriMakerForPublicPrefix(String uriPrefix,
    {String? userId = 'test:example.org',}) {
  Uri makeDomainLink(String path, String? query) {
    final finalQuery = query != null
        ? (userId != null ? '?$query&userId=$userId' : '?$query')
        : userId != null
            ? '?userId=$userId'
            : null;
    final hash =
        sha1.convert(utf8.encode('$uriPrefix$finalQuery#$path')).toString();
    return Uri.parse('$uriPrefix/$hash$finalQuery#$path');
  }

  return makeDomainLink;
}

// --- Actual tests start

void main() {
  group(
    'Testing matrix:-links',
    () => newSpecLinksTests((u, q) => Uri.parse('matrix:$u?$q')),
  );

  group(
    'Testing fallback acter:-links',
    () => newSpecLinksTests((u, q) => Uri.parse('acter:$u?$q')),
  );

  group(
    'Testing acter: object-links',
    () => acterObjectLinksTests((u, q) => Uri.parse('acter:$u?$q')),
  );

  group(
    'Testing acter: invite-links',
    () => acterInviteLinkTests((u, q) => Uri.parse('acter:$u?$q')),
  );

  group(
    'Testing acter: preview data',
    () => acterObjectPreviewTests((u, q) => Uri.parse('acter:$u?$q')),
  );

  group(
    'Testing fallback https://app.acter.global/:-links',
    () => newSpecLinksTests(
        makeUriMakerForPublicPrefix('https://app.acter.global/p/'),),
  );

  group(
    'Testing https://app.acter.global/ object-links',
    () => acterObjectLinksTests(
        makeUriMakerForPublicPrefix('https://app.acter.global/p/'),),
  );

  group(
    'Testing https://app.acter.global/ invite-links',
    () => acterInviteLinkTests(
        makeUriMakerForPublicPrefix('https://app.acter.global/p/'),),
  );

  group(
    'Testing https://app.acter.global/ preview data',
    () => acterObjectPreviewTests(
        makeUriMakerForPublicPrefix('https://app.acter.global/p/'),),
  );

  group(
    'Real life confirmation',
    () {
      test('shared boost', () {
        final uriResult = parseActerUri(
          Uri.parse(
            'https://app.m-1.acter.global/p/0fcb879f4102c0576f5b0333e1320ff76ad551c7?roomDisplayName=Social+Media&via=%5B%27m-1.acter.global%27%5D&userId=jackie%3Am-1.acter.global#o/kPrgnBVJkxuYFKTGgH:m-1.acter.global/taskList/SQv20enWPxuf9zSM2jm34lmvXPwYL643SJPfOAGYmv4',
          ),
        );
        expect(uriResult.target, 'SQv20enWPxuf9zSM2jm34lmvXPwYL643SJPfOAGYmv4');
      });
    },
  );

  group('Testing broken https://app.acter.global/ ', () {
    test('faulty hash fails', () async {
      expect(
        () => parseActerUri(
          Uri.parse(
              'http://acter.global/p/faultyHash?via=acter.global&via=example.org#roomid/room:acter.global/e/someEvent',),
        ),
        throwsA(TypeMatcher<IncorrectHashError>()),
      );
    });

    test('missing user fails', () async {
      final makeUri = makeUriMakerForPublicPrefix('https://app.acter.global/',
          userId: null,);

      expect(
        () => parseActerUri(
          makeUri(
            'roomid/room:acter.global/e/someEvent',
            'via=acter.global&via=example.org',
          ),
        ),
        throwsA(TypeMatcher<MissingUserError>()),
      );
    });
  });

  // legacy matrix.to-links (we are not creating anymore but can still read)
  group('Testing legacy https://matrix.to/-links', () {
    test('roomAlias', () async {
      final result = parseActerUri(
          Uri.parse('https://matrix.to/#/%23somewhere%3Aexample.org'),);
      expect(result.type, LinkType.roomAlias);
      expect(result.target, '#somewhere:example.org');
      expect(result.via, []);
    });
    test('roomId', () async {
      final sourceUri = Uri.parse(
        'https://matrix.to/#/!room%3Aacter.global?via=elsewhere.ca',
      );
      final result = parseActerUri(sourceUri);
      expect(result.type, LinkType.roomId);
      expect(result.target, '!room:acter.global');
      expect(result.via, ['elsewhere.ca']);
    });
    test('userId', () async {
      final result = parseActerUri(
          Uri.parse('https://matrix.to/#/%40alice%3Aacter.global'),);
      expect(result.type, LinkType.userId);
      expect(result.target, '@alice:acter.global');
    });
    test('eventId', () async {
      final result = parseActerUri(
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
}
