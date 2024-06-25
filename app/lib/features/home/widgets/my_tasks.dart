import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/task_providers.dart';
import 'package:acter/features/tasks/widgets/task_item.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyTasksSection extends ConsumerWidget {
  final int limit;

  const MyTasksSection({super.key, required this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(myOpenTasksProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              L10n.of(context).myTasks,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            ActerInlineTextButton(
              onPressed: () => context.pushNamed(Routes.tasks.name),
              child: Text(L10n.of(context).seeAll),
            ),
          ],
        ),
        const SizedBox(height: 10),
        tasks.when(
          data: (tasks) => tasks.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Text(
                        L10n.of(context).congrats,
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
                        L10n.of(context).youAreDoneWithAllYourTasks,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: OutlinedButton(
                          child: Text(
                            L10n.of(context).seeOtherOpenTasks,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onPressed: () => context.pushNamed(Routes.tasks.name),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) =>
                      const Divider(color: Colors.white24, indent: 30),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return TaskItem(
                      task: tasks[index],
                      showBreadCrumb: true,
                      onDone: () => EasyLoading.showToast(
                        L10n.of(context).markedAsDone,
                      ),
                    );
                  },
                ),
          error: (error, stack) =>
              Text(L10n.of(context).loadingTasksFailed(error)),
          loading: () => Text(L10n.of(context).loading),
        ),
      ],
    );
  }
}
