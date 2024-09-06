enum Routes {
  // primary & quickjump actions
  // actionAddTask('/actions/addTask'),
  actionCreateSuperInvite('/actions/createSuperInvite'),

  // pre
  intro('/intro'),
  introProfile('/introProfile'),

  // --- Auth
  authLogin('/login'),
  forgotPassword('/forgotPassword'),
  authRegister('/register'),

  // -- onboarding
  saveUsername('/saveUsername'),
  linkEmail('/linkEmail'),
  uploadAvatar('/uploadAvatar'),
  analyticsOptIn('/analyticsOptIn'),

  // --- profile
  myProfile('/profile'),

  // --- generic nav
  dashboard('/dashboard'),
  search('/search'),
  activities('/activities'),

  // --- Updates
  updates('/updates'),
  actionAddUpdate('/actions/addUpdate'),

  // --- search
  searchPublicDirectory('/search/public'),

  // --- Full Screen Avatar
  fullScreenAvatar('/fullScreenAvatar'),

  // --- chat
  chat('/chat'),
  // show as dialog
  createChat('/chat/create'),
  chatroom('/chat/:roomId([!#][^/]+)'), // !roomId, #roomName
  chatProfile('/chat/:roomId([!#][^/]+)/profile'),
  chatSettingsVisibility('/chat/:roomId([!#][^/]+)/access'),
  chatInvite('/:roomId([!#][^/]+)/invite'),

  // --- tasks
  tasks('/tasks'),
  taskListDetails('/tasks/:taskListId([^/]+)'),
  taskItemDetails('/tasks/:taskListId([^/]+)/:taskId([^/]+)'),

  // --- Invite
  inviteIndividual('/inviteIndividual'),
  shareInviteCode('/shareInviteCode'),
  inviteSpaceMembers('/inviteSpaceMembers'),
  invitePending('/invitePending'),

  // -- spaces
  spaces('/spaces'),
  createSpace('/spaces/create'),
  linkSubspace('/:spaceId([!#][^/]+)/linkSubspace'),
  linkChat('/:spaceId([!#][^/]+)/linkChat'),
  linkRecommended('/:spaceId([!#][^/]+)/linkRecommended'),
  spaceInvite('/:spaceId([!#][^/]+)/invite'),
  space('/:spaceId([!#][^/]+)'), // !spaceId, #spaceName
  spaceRelatedSpaces('/:spaceId([!#][^/]+)/spaces'),
  spaceMembers('/:spaceId([!#][^/]+)/members'),
  spacePins('/:spaceId([!#][^/]+)/pins'),
  spaceEvents('/:spaceId([!#][^/]+)/events'),
  spaceChats('/:spaceId([!#][^/]+)/chats'),
  spaceTasks('/:spaceId([!#][^/]+)/tasks'),
  // -- space Settings
  spaceSettings('/:spaceId([!#][^/]+)/settings'),
  spaceSettingsApps('/:spaceId([!#][^/]+)/settings/app'),
  spaceSettingsVisibility('/:spaceId([!#][^/]+)/settings/access'),
  spaceSettingsNotifications('/:spaceId([!#][^/]+)/settings/notifications'),

  // -- pins
  pins('/pins'),
  pin('/pins/:pinId'),
  createPin('/pins/create'),

  // -- events
  calendarEvents('/events'),
  createEvent('/events/create'),
  calendarEvent('/events/:calendarId'),

  // -- settings
  settings('/settings'),
  settingsLabs('/settings/labs'),
  settingsChat('/settings/chat'),
  settingSessions('/settings/sessions'),
  settingBackup('/settings/backup'),
  settingLanguage('/settings/language'),
  settingNotifications('/settings/notifications'),
  blockedUsers('/settings/blockedUsers'),
  changePassword('/settings/changePassword'),
  emailAddresses('/settings/emailAddresses'),
  info('/info'),
  licenses('/info/licenses'),

  // -- super invites
  settingsSuperInvites('/settings/super_invites'),
  // -- utils
  main('/'),
  initial('/__init__'),
  bugReport('/bug-report'),
  quickJump('/quick-jump'),
  // -- coming in from a push notification
  forward('/forward'),
  // -- fatal failure
  fatalFail('/error');

  const Routes(this.route);
  final String route;
}
