import 'package:flutter/foundation.dart';

class QuickJumpKeys {
  static const profile = Key('quick-jump-profile');
  static const settings = Key('quick-jump-settings');
  static const tasks = Key('quick-jump-task');
  static const pins = Key('quick-jump-pins');
  static const bugReport = Key('quick-jump-bug-report');
  static const createUpdateAction = Key('quick-jump-create-update');
  static const createTaskListAction = Key('quick-jump-create-tasklist');
  static const createPinAction = Key('quick-jump-create-pin');
  static const createEventAction = Key('quick-jump-create-event');
}

//EVENT FILTERS
enum QuickSearchFilters {
  all,
  spaces,
  chats,
  pins,
  events,
  tasks,
}
