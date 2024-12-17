import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/events/widgets/skeletons/event_item_skeleton_widget.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item_widget.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/skeleton/tasks_list_skeleton.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::news::add');

class SelectedActionButton extends ConsumerWidget {
  final RefDetails? refDetails;

  const SelectedActionButton({
    super.key,
    this.refDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (refDetails == null) return SizedBox();
    final refObjectId = refDetails!.targetIdStr();
    final refObjectType = refDetails!.typeStr();
    if (refObjectId == null) return SizedBox();

    return switch (refObjectType) {
      'pin' => pinActionButton(context, ref, refObjectId),
      'calendar-event' => calendarActionButton(context, ref, refObjectId),
      'task-list' => taskListActionButton(context, ref, refObjectId),
      _ => const SizedBox(),
    };
  }

  Widget calendarActionButton(BuildContext context, WidgetRef ref, String id) {
    return ref.watch(calendarEventProvider(id)).when(
          data: (calendarEvent) {
            return SizedBox(
              width: 300,
              child: EventItem(
                event: calendarEvent,
                isShowRsvp: false,
                onTapEventItem: (event) async {
                  final notifier = ref.read(newsStateProvider.notifier);
                  await notifier.selectEventToShare(context);
                },
              ),
            );
          },
          loading: () => const SizedBox(
            width: 300,
            child: EventItemSkeleton(),
          ),
          error: (e, s) {
            _log.severe('Failed to load cal event', e, s);
            return Center(
              child: Text(L10n.of(context).failedToLoadEvent(e)),
            );
          },
        );
  }

  Widget pinActionButton(BuildContext context, WidgetRef ref, String id) {
    return ref.watch(pinProvider(id)).when(
          data: (pin) {
            return SizedBox(
              width: 300,
              child: PinListItemWidget(
                pinId: pin.eventIdStr(),
                showPinIndication: true,
                onTaPinItem: (pinId) async {
                  final notifier = ref.read(newsStateProvider.notifier);
                  await notifier.selectPinToShare(context);
                },
              ),
            );
          },
          loading: () => const SizedBox(
            width: 300,
            child: EventItemSkeleton(),
          ),
          error: (e, s) {
            _log.severe('Failed to load cal event', e, s);
            return Center(
              child: Text(L10n.of(context).failedToLoadEvent(e)),
            );
          },
        );
  }

  Widget taskListActionButton(BuildContext context, WidgetRef ref, String id) {
    return ref.watch(taskListProvider(id)).when(
          data: (taskList) {
            return SizedBox(
              width: 300,
              child: TaskListItemCard(
                showOnlyTaskList: true,
                canExpand: false,
                showTaskListIndication: true,
                taskListId: taskList.eventIdStr(),
                onTitleTap: () async {
                  final notifier = ref.read(newsStateProvider.notifier);
                  await notifier.selectTaskListToShare(context);
                },
              ),
            );
          },
          loading: () => const SizedBox(
            width: 300,
            child: TasksListSkeleton(),
          ),
          error: (e, s) {
            _log.severe('Failed to load task list', e, s);
            return Center(
              child: Text(L10n.of(context).errorLoadingTasks(e)),
            );
          },
        );
  }
}
