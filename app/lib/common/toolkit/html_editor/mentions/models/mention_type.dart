import 'package:acter/common/toolkit/html_editor/services/constants.dart';

enum MentionType {
  user,
  room;

  String get character => switch (this) {
    MentionType.user => userMentionChar,
    MentionType.room => roomMentionChar,
  };
  static MentionType fromStr(String str) => switch (str) {
    userMentionChar => MentionType.user,
    roomMentionChar => MentionType.room,
    _ => throw UnsupportedError('invalid string'),
  };
}

typedef MentionSelectedFn =
    void Function(MentionType type, String id, String? displayName);
