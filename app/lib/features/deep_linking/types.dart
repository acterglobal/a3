enum LinkType { roomId, roomAlias, userId, chatEvent, spaceObject, superInvite }

enum ObjectType {
  pin,
  calendarEvent,
  taskList,
  task,
  boost,
  story,
  space,
  chat,
  // reference types
  comment,
  attachment;

  String emoji() => switch (this) {
    ObjectType.pin => '📌', // pin
    ObjectType.calendarEvent => '🗓️', // calendar
    ObjectType.taskList => '📋', // clipboard
    ObjectType.task => '☑️', // checkoff
    ObjectType.boost => '🚀', // boost rocket
    ObjectType.space => '🌐', // globe
    ObjectType.chat => '💬', // chat
    ObjectType.comment => '💬', // speech bubble
    ObjectType.attachment => '📎', // paperclip icon
    ObjectType.story => '📰', // newspaper icon
  };
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

  String previewTitle() {
    final emoji = finalType()?.emoji();
    if (preview.title == null || emoji == null) {
      return target;
    }
    return '$emoji ${preview.title}';
  }

  bool titleMatches(String text) {
    if (text.trim().isEmpty) {
      return true; // we match on all empty links
    }
    // formats are a bit more complicated for other
    final cases = [];
    if (type == LinkType.userId) {
      if (preview.userDisplayName != null) {
        cases.addAll([preview.userDisplayName, '@${preview.userDisplayName}']);
      }
      final username = target.split(':').first;
      cases.addAll([target, '@$target', username, '@$username']);
    } else if (type == LinkType.roomId) {
      if (preview.roomDisplayName != null) {
        cases.addAll([preview.roomDisplayName, '#${preview.roomDisplayName}']);
      }
      if (preview.title != null) {
        cases.addAll([preview.title, '#${preview.title}']);
      }
      cases.addAll([target, '!$target', '#$target']);
    } else if (type == LinkType.spaceObject) {
      if (preview.title != null) {
        cases.addAll([preview.title, '#${preview.title}']);
      }
      cases.add(previewTitle());
    }

    final loweredText = text.toLowerCase();
    return cases.any((e) => e == text || e.toLowerCase() == loweredText);
  }
}
