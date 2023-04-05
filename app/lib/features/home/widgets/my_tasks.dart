import 'package:acter/common/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:acter/features/home/controllers/tasks_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'dart:core';

class MyTasksSection extends ConsumerWidget {
  final int limit;
  const MyTasksSection({super.key, required this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(myTasksProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Tasks',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          ...tasks.when(
            data: (tasks) {
              if (tasks.isNotEmpty) {
                return [
                  ...tasks
                      .sublist(0, tasks.length > limit ? limit : tasks.length)
                      .map(
                        (brief) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: ListTile(
                            // onTap: () => context.go('/$roomId'),
                            title: Text(
                              brief.task.title(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            subtitle: Wrap(
                              direction: Axis.horizontal,
                              children: [
                                Text(
                                  brief.taskList.name(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .apply(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .neutral5,
                                      ),
                                ),
                                Text(
                                  ' in ',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  brief.space.profile.displayName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .apply(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                ),
                              ],
                            ),
                            leading: brief.task.isDone()
                                ? const Icon(Atlas.check_circle_thin)
                                : const Icon(
                                    Icons.check_box_outline_blank_outlined,
                                  ),
                          ),
                        ),
                      ),
                  tasks.length > limit
                      ? Padding(
                          padding: const EdgeInsets.only(
                            left: 30,
                          ),
                          child: Text(
                            'see all my ${tasks.length} tasks',
                          ),
                        ) // FIXME: click and where?
                      : const Text(''),
                ];
              }
              return [
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Congrats!',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Icon(
                          Atlas.check_circle_thin,
                          size: 50.0,
                          color: Theme.of(context).colorScheme.success,
                        ),
                      ),
                      Text(
                        'you are done with all your tasks!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'see open tasks',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
            error: (error, stack) => [Text('Loading tasks failed: $error')],
            loading: () => [const Text('Loading')],
          )
        ],
      ),
    );
  }
}
