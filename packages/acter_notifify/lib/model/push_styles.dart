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
  objectInvitation('📨'),

  //General
  titleChange('✏️'),
  descriptionChange('✏️'),
  creation('➕'),
  redaction('🗑️'),
  otherChanges('✏️');

  const PushStyles(this.emoji);

  final String emoji;
}
