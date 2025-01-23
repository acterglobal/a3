//PUSH STYLES
enum PushStyles { comment, reaction }

//Object Emoji
enum PushStylesEmoji {
  //LIST OF PUSH STYLE EMOJIS
  comment('💬'),
  reactionLike('❤️'),
  attachment('📎'),
  rsvpYes('✅'),
  rsvpMayBe('✔️'),
  rsvpNo('✖️'),
  taskComplete('🟢'),
  taskReOpen('🔁'),
  taskAccept('🤝'),
  taskDecline('✖️');

  const PushStylesEmoji(this.data);

  final String data;
}

//Object Type
enum ObjectType { news, pin }

//Object Emoji
enum ObjectEmoji {
  //LIST OF OBJECT EMOJIS
  news('🚀'),
  pin('📌'),
  event('🗓️ '),
  taskList('📋'),
  taskItem('☑️');

  const ObjectEmoji(this.data);

  final String data;
}
