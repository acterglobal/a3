import 'package:acter/features/deep_linking/types.dart';

class UriParseError extends Error {}

class SchemeNotSupported extends UriParseError {
  final String scheme;

  SchemeNotSupported({required this.scheme});
}

class ObjectNotSupported extends UriParseError {
  final String objectType;

  ObjectNotSupported({required this.objectType});
}

class ParsingFailed extends UriParseError {}

UriParseResult parseUri(Uri uri) => switch (uri.scheme) {
      'acter' => _parseActerUri(uri),
      'matrix' => _parseMatrixUri(uri),
      'https' || 'http' => _parseMatrixHttpsUri(uri),
      _ => throw SchemeNotSupported(scheme: uri.scheme),
    };

UriParseResult _parseActerUri(Uri uri) {
  final path = uri.pathSegments.first;
  return switch (path) {
    'o' => _parseActerEvent(uri),
    _ => _parseMatrixUri(uri)
  };
}

ObjectRef? _parseActerObjectPath(List<String> remainingPath) {
  if (remainingPath.length < 2) {
    return null;
  }
  final objectType = switch (remainingPath.first) {
    'boost' => ObjectType.boost,
    'calendarEvent' => ObjectType.calendarEvent,
    'pin' => ObjectType.pin,
    'taskList' => ObjectType.taskList,
    'task' => ObjectType.task,
    'comment' => ObjectType.comment,
    'attachment' => ObjectType.attachment,
    _ => throw ObjectNotSupported(objectType: remainingPath.first),
  };
  return ObjectRef(
    child: _parseActerObjectPath(remainingPath.sublist(2)),
    objectType: objectType,
    objectId: '\$${remainingPath[1]}',
  );
}

UriParseResult _parseActerEvent(Uri uri) {
  final path = uri.pathSegments;
  final objectPath = _parseActerObjectPath(path.sublist(2));
  if (objectPath == null) {
    throw ParsingFailed();
  }

  return UriParseResult(
    type: LinkType.spaceObject,
    objectPath: objectPath,
    target: objectPath.objectId,
    via: uri.queryParametersAll['via'] ?? [],
    roomId: '!${path[1]}',
  );
}

UriParseResult _parseMatrixHttpsUri(Uri uri) {
  String end = Uri.decodeComponent(uri.fragment);
  final split = end.split('?');
  final path = split.first;
  final prefix = switch (path[1]) {
    '#' => 'r',
    '!' => 'roomid',
    '@' => 'u',
    _ => throw ParsingFailed(),
  };
  uri = uri.replace(
    path: '$prefix/${path.substring(2).replaceFirst('/\$', '/e/')}',
    query: split.lastOrNull,
  );
  return _parseMatrixUri(uri);
}

UriParseResult _parseMatrixUri(Uri uri) {
  final path = uri.pathSegments.first;
  return switch (path) {
    'r' => UriParseResult(
        type: LinkType.roomAlias,
        via: uri.queryParametersAll['via'] ?? [],
        target: '#${uri.pathSegments.last}',
      ),
    'u' => UriParseResult(
        type: LinkType.userId,
        via: uri.queryParametersAll['via'] ?? [],
        target: '@${uri.pathSegments.last}',
      ),
    'roomid' => _parseMatrixUriRoomId(uri),
    _ => throw ParsingFailed(),
  };
}

UriParseResult _parseMatrixUriRoomId(Uri uri) {
  final path = uri.pathSegments;
  if (path.length == 4) {
    final roomId = path[1];
    final eventId = path[3];
    return UriParseResult(
      type: LinkType.chatEvent,
      via: uri.queryParametersAll['via'] ?? [],
      target: '\$$eventId',
      roomId: '!$roomId',
    );
  } else {
    return UriParseResult(
      type: LinkType.roomId,
      via: uri.queryParametersAll['via'] ?? [],
      target: '!${uri.pathSegments.last}',
    );
  }
}
