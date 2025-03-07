const String userMentionChar = '@';
const String roomMentionChar = '#';

enum MentionType {
  user,
  room;

  static String toStr(MentionType type) => switch (type) {
    MentionType.user => userMentionChar,
    MentionType.room => roomMentionChar,
  };
  static MentionType fromStr(String str) => switch (str) {
    userMentionChar => MentionType.user,
    roomMentionChar => MentionType.room,
    _ => throw UnsupportedError('invalid string'),
  };
}
