enum Routes {
  // primary & quickjump actions
  actionAddTask('/actions/addTask'),
  actionAddPin('/actions/addPin'),

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
  chatroom(r'/chat/(?<roomId>([!#][^/]+)'), // !roomId, #roomName

  // --- updates
  updatesEdit('updates_edit'),
  updatesPost('updates_post'),
  updatesPostSearch('post_search'),

  // -- spaces
  spaces('/spaces'),
  createSpace('/spaces/create'),
  editSpace('/:spaceId([!#][^/]+)/edit'),
  space('/:spaceId([!#][^/]+)'), // !spaceId, #spaceName
  spaceRelatedSpaces('/:spaceId([!#][^/]+)/spaces'),
  spacePins('/:spaceId([!#][^/]+)/pins'),

  // -- pins

  pins('/pins'),
  pin('/pins/:pinId'),

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
