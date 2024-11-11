enum LinkType {
  roomId,
  roomAlias,
  userId,
  chatEvent,
  spaceObject,
  superInvite,
}

enum ObjectType {
  pin,
  calendarEvent,
  taskList,
  task,
  boost,

  // reference types
  comment,
  attachment,
}

class ObjectRef {
  final ObjectRef? child;
  final ObjectType objectType;
  final String objectId;

  ObjectRef({
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

  UriParseResult({
    required this.type,
    required this.via,
    required this.target,
    this.roomId,
    this.parentId,
    this.objectPath,
  });
}
