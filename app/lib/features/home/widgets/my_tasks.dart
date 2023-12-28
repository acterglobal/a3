import 'dart:core';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/task_providers.dart';
import 'package:acter/features/tasks/widgets/task_entry.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyTasksSection extends ConsumerWidget {
  final int limit;

  const MyTasksSection({super.key, required this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(myOpenTasksProvider);
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
          tasks.when(
            data: (tasks) => tasks.isEmpty
                ? Center(
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
                          child: OutlinedButton(
                            child: Text(
                              'see other open tasks',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onPressed: () =>
                                context.pushNamed(Routes.tasks.name),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: tasks
                        .map(
                          (task) => TaskEntry(
                            task: task,
                            showBreadCrumb: true,
                            onDone: () {
                              EasyLoading.showToast(
                                'marked as done',
                                toastPosition: EasyLoadingToastPosition.bottom,
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
            error: (error, stack) => Text('Loading tasks failed: $error'),
            loading: () => const Text('Loading'),
          ),
        ],
      ),
    );
  }
}
