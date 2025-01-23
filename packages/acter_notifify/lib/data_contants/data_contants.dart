//Object Emoji
enum PushStyles {
  //LIST OF PUSH STYLE EMOJIS
  comment('💬'),
  reaction('❤️'),
  attachment('📎'),
  rsvpYes('✅'),
  rsvpMayBe('✔️'),
  rsvpNo('✖️'),
  taskComplete('🟢'),
  taskReOpen('🔁'),
  taskAccept('🤝'),
  taskDecline('✖️');

  const PushStyles(this.emoji);

  final String emoji;
}

//Object Emoji
enum ActerObject {
  //LIST OF OBJECT EMOJIS
  news('🚀'),
  pin('📌'),
  event('🗓️'),
  taskList('📋'),
  taskItem('☑️');

  const ActerObject(this.emoji);

  final String emoji;
}
