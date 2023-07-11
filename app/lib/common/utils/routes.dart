enum Routes {
  // primary & quickjump actions
  actionAddTask('/actions/addTask'),
  actionAddPin('/actions/addPin'),
  actionAddUpdate('/actions/addUpdate'),

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
  tasks('/tasks'),

  // --- chat
  chat('/chat'),
  createChat('/chat/create'),
  chatroom('/chat/:roomId([!#][^/]+)'), // !roomId, #roomName

  // -- spaces
  spaces('/spaces'),
  joinSpace('/spaces/join'),
  createSpace('/spaces/create'),
  editSpace('/:spaceId([!#][^/]+)/edit'),
  space('/:spaceId([!#][^/]+)'), // !spaceId, #spaceName
  spaceRelatedSpaces('/:spaceId([!#][^/]+)/spaces'),
  spacePins('/:spaceId([!#][^/]+)/pins'),
  spaceEvents('/:spaceId([!#][^/]+)/events'),

  // -- pins

  pins('/pins'),
  pin('/pins/:pinId'),

  // -- events
  createEvent('/events/create'),
  calendarEvent('/events/:calendarId'),
  editCalendarEvent('/events/:calendarId/edit'),

  // -- settings
  settings('/settings'),
  settingsLabs('/settings/labs'),
  info('/info'),
  licenses('/info/licenses'),

  // -- utils
  bugReport('/bug-report'),
  quickJump('/quick-jump');

  const Routes(this.route);
  final String route;
}
