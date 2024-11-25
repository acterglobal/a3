const String userMentionChar = '@';
const String roomMentionChar = '#';

enum MentionType {
  user,
  room;

  static String toStr(MentionType type) => switch (type) {
        MentionType.user => '@',
        MentionType.room => '#',
      };
}
