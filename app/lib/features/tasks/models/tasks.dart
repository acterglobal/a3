import 'package:acter/features/space/providers/space_providers.dart';
import 'package:acter/common/models/profile_data.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

class TaskBrief {
  final Task task;
  final TaskList taskList;
  final SpaceWithProfileData space;
  const TaskBrief({
    required this.task,
    required this.taskList,
    required this.space,
  });
}

Future<TaskBrief> fromTask(TaskList tl, Task task) async {
  final space = tl.space();
  final profile = await getProfileData(space);
  return TaskBrief(
    task: task,
    taskList: tl,
    space: SpaceWithProfileData(space, profile),
  );
}
