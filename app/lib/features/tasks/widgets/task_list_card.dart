import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/features/tasks/widgets/task_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';

@immutable
class TasksOverview {
  final List<Task> openTasks;
  final List<Task> doneTasks;
  const TasksOverview({required this.openTasks, required this.doneTasks});
}

class TasksNotifier extends FamilyAsyncNotifier<TasksOverview, TaskList> {
  late Stream<void> subscriber;

  Future<TasksOverview> _refresh(TaskList taskList) async {
    final tasks = (await taskList.tasks()).toList();
    List<Task> openTasks = [];
    List<Task> doneTasks = [];
    for (final task in tasks) {
      if (task.isDone()) {
        doneTasks.add(task);
      } else {
        openTasks.add(task);
      }
    }

    // FIXME: ordering?

    return TasksOverview(openTasks: openTasks, doneTasks: doneTasks);
  }

  @override
  Future<TasksOverview> build(TaskList arg) async {
    // Load initial todo list from the remote repository
    final taskList = arg;
    final retState = _refresh(taskList);
    subscriber = taskList.subscribeStream();
    subscriber.forEach((element) async {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        return await _refresh(taskList);
      });
    });
    return retState;
  }
}

final tasksProvider =
    AsyncNotifierProvider.family<TasksNotifier, TasksOverview, TaskList>(() {
  return TasksNotifier();
});

class TaskListCard extends ConsumerWidget {
  final TaskList taskList;
  const TaskListCard({Key? key, required this.taskList}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider(taskList));
    final space = taskList.space();
    final spaceInfo = ref.watch(spaceProfileDataProvider(space));
    final description = taskList.descriptionText();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: spaceInfo.when(
                  data: (spaceInfo) => ActerAvatar(
                    mode: DisplayMode.Space,
                    displayName: spaceInfo.displayName,
                    uniqueId: space.getRoomId().toString(),
                    avatar: spaceInfo.getAvatarImage(),
                    size: 24,
                  ),
                  loading: () => null,
                  error: (error, stackTrace) => null,
                ),
                title: Text(
                  taskList.name(),
                ),
                subtitle: description != null ? Text(description) : null,
              ),
              tasks.when(
                data: (overview) {
                  List<Widget> children = [];
                  final int total =
                      overview.doneTasks.length + overview.openTasks.length;

                  if (total > 3) {
                    children.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${overview.doneTasks.length} / $total Tasks done',
                        ),
                      ),
                    );
                  }

                  for (final task in overview.openTasks) {
                    children.add(TaskEntry(task: task));
                  }
                  children.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: OutlinedButton(
                        onPressed: () => {
                          customMsgSnackbar(
                            context,
                            'Inline task creation not yet implemented',
                          )
                        },
                        child: const Text('Add Task'),
                      ),
                    ),
                  );

                  for (final task in overview.doneTasks) {
                    children.add(TaskEntry(task: task));
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  );
                },
                error: (error, stack) => Text('error loading tasks: $error'),
                loading: () => const Text('loading'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
