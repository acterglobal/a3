enum MentionType {
  user,
  room;

  static MentionType fromStr(String str) => switch (str) {
        '@' => user,
        '#' => room,
        _ => throw UnimplementedError(),
      };
  static String toStr(MentionType type) => switch (type) {
        MentionType.user => '@',
        MentionType.room => '#',
      };
}
