enum Routes {
  // actionAddTask('/actions/addTask');

  // --- Auth
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
  chatroom('/chat/:spaceId([!#][^/]+)'), // !roomId, #roomName

  // -- spaces
  space('/:spaceId([!#][^/]+)'), // !spaceId, #spaceName

  // -- utils
  bugReport('/bug-report'),
  quickJump('/quick-jump');

  const Routes(this.route);
  final String route;
}
