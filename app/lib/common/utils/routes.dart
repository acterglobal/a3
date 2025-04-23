enum Routes {
  // pre
  intro('/intro'),
  introProfile('/introProfile'),

  // --- Auth
  authLogin('/login'),
  forgotPassword('/forgotPassword'),
  authRegister('/register'),

  // -- onboarding
  onboarding('/onboarding'),

  // --- profile
  myProfile('/profile'),

  // --- generic nav
  main('/'),
  dashboard('/dashboard'),
  search('/search'),
  activities('/activities'),

  // --- Updates
  updates('/updates'),
  update('/updates/:updateId([^/]+)'),
  updateList('/updateList'),
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

  // -- Activities sub pages
  myOpenInvitations('/activities/invites'),

  // -- spaces
  spaces('/spaces'),
  createSpace('/spaces/create'),
  linkSpace('/:spaceId([!#][^/]+)/linkSpace'),
  linkChat('/:spaceId([!#][^/]+)/linkChat'),
  spaceInvite('/:spaceId([!#][^/]+)/invite'),
  space('/:spaceId([!#][^/]+)'), // !spaceId, #spaceName
  subSpaces('/:spaceId([!#][^/]+)/subSpaces'),
  subChats('/:spaceId([!#][^/]+)/subChats'),
  organizeCategories(
    '/organizeCategories/:spaceId([^/]+)/:categoriesFor([^/]+)',
  ),
  spaceMembers('/:spaceId([!#][^/]+)/members'),
  spacePins('/:spaceId([!#][^/]+)/pins'),
  spaceEvents('/:spaceId([!#][^/]+)/events'),
  spaceTasks('/:spaceId([!#][^/]+)/tasks'),
  spaceUpdates('/:spaceId([!#][^/]+)/updates'),
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
  chatListShowcase('/settings/chat/chat-showcase'),
  chatMessageShowcase('/settings/chat/chat-showcase/:roomId([^/]+)'),
  settingsCalendar('/settings/calendar'),
  settingsCustomizations('/settings/customizations'),
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
  actionCreateSuperInvite('/actions/createSuperInvite'),
  createSuperInvite('/settings/super_invites/create'),
  // -- utils
  bugReport('/bug-report'),
  scanQrCode('/scan-qr-code'),
  // -- coming in from a push notification
  forward('/forward'),
  // -- fatal failure
  fatalFail('/error');

  const Routes(this.route);

  final String route;
}
