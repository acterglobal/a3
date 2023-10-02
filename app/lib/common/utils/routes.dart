enum Routes {
  // primary & quickjump actions
  // actionAddTask('/actions/addTask'),
  actionAddTaskList('/actions/addTaskList'),
  actionAddPin('/actions/addPin'),
  actionAddEvent('/actions/addEvent'),
  actionAddUpdate('/actions/addUpdate'),
  actionCreateChat('/actions/createChat'),
  actionChatInvite('/actions/chatInvite/:roomId([!#][^/]+)'),

  // --- Auth
  intro('/intro'),
  start('/start'),
  introProfile('/introProfile'),
  authLogin('/login'),
  authRegister('/register'),

  // --- profile
  myProfile('/profile'),

  // --- generic nav
  main('/'),
  dashboard('/dashboard'),
  updates('/updates'),
  search('/search'),
  activities('/activities'),

  // --- chat
  chat('/chat'),
  chatroom(':roomId([!#][^/]+)'), // !roomId, #roomName
  chatProfile(':roomId([!#][^/]+)/profile'),

  tasks('/tasks'),
  task('/tasks/:taskListId([!#][^/]+)/:taskId([!#][^/]+)'),
  taskList('/tasks/:taskListId([!#][^/]+)'),

  // -- spaces
  spaces('/spaces'),
  joinSpace('/spaces/join'),
  createSpace('/spaces/create'),
  editSpace('/:spaceId([!#][^/]+)/edit'),
  spaceInvite('/:spaceId([!#][^/]+)/invite'),
  // -- space Settings
  spaceSettings('/:spaceId([!#][^/]+)/settings'),
  spaceSettingsApps('/:spaceId([!#][^/]+)/settings/app'),
  space('/:spaceId([!#][^/]+)'), // !spaceId, #spaceName
  spaceRelatedSpaces('spaces'),
  spaceMembers('members'),
  spacePins('pins'),
  spaceEvents('events'),
  spaceChats('chats'),
  spaceTasks('tasks'),

  // -- pins

  pins('/pins'),
  pin('/pins/:pinId'),
  editPin('/pins/:pinId/edit'),

  // -- events
  calendarEvents('/events'),
  createEvent('/events/create'),
  calendarEvent('/events/:calendarId'),
  editCalendarEvent('/events/:calendarId/edit'),

  // -- settings
  settings('/settings'),
  settingsLabs('/settings/labs'),
  settingSessions('/settings/sessions'),
  blockedUsers('/settings/blockedUsers'),
  info('/info'),
  licenses('/info/licenses'),

  // -- utils
  bugReport('/bug-report'),
  quickJump('/quick-jump');

  const Routes(this.route);
  final String route;
}
