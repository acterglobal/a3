//LIST OF PUSH STYLE EMOJIS
enum PushStyles {
  //Related things
  comment('💬'),
  reaction('❤️'),
  attachment('📎'),
  link('🔗'),

  //Event Change
  eventDateChange('🕒'),
  rsvpYes('✅'),
  rsvpMaybe('✔️'),
  rsvpNo('✖️'),

  //Task Style
  taskComplete('🟢'),
  taskReOpen('  ⃝ '),
  taskAccept('🤝'),
  taskDecline('✖️'),
  taskDueDateChange('🕒'),

  //General
  creation('➕'),
  redaction('🗑️'),
  titleChange('✏️'),
  descriptionChange('✏️'),
  otherChange('✏️');

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
