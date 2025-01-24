//LIST OF PUSH STYLE EMOJIS
enum PushStyles {
  //Related things
  comment('💬'),
  reaction('❤️'),
  attachment('📎'),
  references('🔗'),

  //Event Change
  eventDateChange('🕒'),
  rsvpYes('✅'),
  rsvpMaybe('✔️'),
  rsvpNo('✖️'),

  //Task-list
  taskAdd('➕'),

  //Task
  taskComplete('🟢'),
  taskReOpen('  ⃝ '),
  taskAccept('🤝'),
  taskDecline('✖️'),
  taskDueDateChange('🕒'),

  //General
  titleChange('✏️'),
  descriptionChange('✏️'),
  creation('➕'),
  redaction('🗑️'),
  otherChange('✏️');

  const PushStyles(this.emoji);

  final String emoji;
}
