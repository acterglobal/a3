enum LinkType { roomId, roomAlias, userId, chatEvent, spaceObject, superInvite }

enum ObjectType {
  pin,
  calendarEvent,
  taskList,
  task,
  boost,
  space,
  chat,
  // reference types
  comment,
  attachment,
}

class ObjectPreview {
  final String? roomDisplayName;
  final String? userDisplayName;
  final String? userId;
  final String? title;
  final String? description;
  final String? image;
  final Map<String, List<String>> extra;

  const ObjectPreview({
    this.roomDisplayName,
    this.title,
    this.description,
    this.image,
    this.userId,
    this.userDisplayName,
    this.extra = const {},
  });

  factory ObjectPreview.fromUri(Uri uri) {
    final extra = uri.queryParametersAll;
    final userId = extra['userId']?.firstOrNull;
    return ObjectPreview(
      description: extra['description']?.firstOrNull,
      title: extra['title']?.firstOrNull,
      roomDisplayName: extra['roomDisplayName']?.firstOrNull,
      image: extra['image']?.firstOrNull,
      userId: userId != null ? '@$userId' : null,
      userDisplayName: extra['userDisplayName']?.firstOrNull,
      extra: extra,
    );
  }
}

class ObjectRef {
  final ObjectRef? child;
  final ObjectType objectType;
  final String objectId;

  const ObjectRef({
    required this.child,
    required this.objectType,
    required this.objectId,
  });
}

class UriParseResult {
  final LinkType type;
  final List<String> via;
  final String target;
  final ObjectRef? objectPath;
  final String? roomId;
  final String? parentId;
  final ObjectPreview preview;

  const UriParseResult({
    required this.type,
    required this.via,
    required this.target,
    this.roomId,
    this.parentId,
    this.objectPath,
    this.preview = const ObjectPreview(),
  });

  ObjectType? finalType() {
    ObjectRef? cur = objectPath;
    while (cur?.child != null) {
      cur = cur?.child; // find the deepest object
    }
    return cur?.objectType;
  }
}
