enum Routes {
  // primary & quickjump actions
  // actionAddTask('/actions/addTask'),
  actionAddTaskList('/actions/addTaskList'),
  actionAddPin('/actions/addPin'),
  actionAddEvent('/actions/addEvent'),
  actionCreateSuperInvite('/actions/createSuperInvite'),

  // --- Auth
  intro('/intro'),
  start('/start'),
  introProfile('/introProfile'),
  authLogin('/login'),
  forgotPassword('/forgotPassword'),
  authRegister('/register'),
  saveUsername('/saveUsername'),
  linkEmail('/linkEmail'),
  uploadAvatar('/uploadAvatar'),

  // --- profile
  myProfile('/profile'),

  // --- generic nav
  main('/'),
  dashboard('/dashboard'),
  search('/search'),
  activities('/activities'),

  // --- Updates
  updates('/updates'),
  actionAddUpdate('/actions/addUpdate'),

  // --- search
  searchPublicDirectory('/search/public'),

  // --- chat
  chat('/chat'),
  // show as dialog
  createChat('/chat/create'),
  chatroom('/chat/:roomId([!#][^/]+)'), // !roomId, #roomName
  chatProfile('/chat/:roomId([!#][^/]+)/profile'),
  chatInvite('/:roomId([!#][^/]+)/invite'),

  // --- tasks
  tasks('/tasks'),
  task('/tasks/:taskListId([^/]+)/:taskId([^/]+)'),
  taskList('/tasks/:taskListId([^/]+)'),

  // -- spaces
  spaces('/spaces'),
  createSpace('/spaces/create'),
  linkSubspace('/:spaceId([!#][^/]+)/linkSubspace'),
  linkChat('/:spaceId([!#][^/]+)/linkChat'),
  linkRecommended('/:spaceId([!#][^/]+)/linkRecommended'),
  editSpace('/:spaceId([!#][^/]+)/edit'),
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
  spaceSettingsNotifications('/:spaceId([!#][^/]+)/settings/notifications'),

  // -- pins
  pins('/pins'),
  pin('/pins/:pinId'),

  // -- events
  calendarEvents('/events'),
  createEvent('/events/create'),
  calendarEvent('/events/:calendarId'),
  editCalendarEvent('/events/:calendarId/edit'),

  // -- settings
  settings('/settings'),
  settingsLabs('/settings/labs'),
  settingsChat('/settings/chat'),
  settingSessions('/settings/sessions'),
  settingBackup('/settings/backup'),
  settingLanguage('/settings/language'),
  settingNotifications('/settings/notifications'),
  blockedUsers('/settings/blockedUsers'),
  emailAddresses('/settings/emailAddresses'),
  info('/info'),
  licenses('/info/licenses'),

  // -- super invites
  settingsSuperInvites('/settings/super_invites'),
  settingsSuperInvitesUpdate('/settings/super_invites/:token/update'),
  // -- utils
  bugReport('/bug-report'),
  quickJump('/quick-jump'),
  // -- coming in from a push notification
  forward('/forward'),
  // -- fatal failure
  fatalFail('/error');

  const Routes(this.route);
  final String route;
}
