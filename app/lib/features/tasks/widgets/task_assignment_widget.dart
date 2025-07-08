import 'package:acter/features/tasks/actions/assign_unassign_task.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:atlas_icons/atlas_icons.dart';

class TaskAssignmentWidget extends ConsumerWidget {
  final Task task;

  const TaskAssignmentWidget({
    required this.task,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    final assignees = asDartStringList(task.assigneesStr());
    final hasAssignees = assignees.isNotEmpty;

    return ListTile(
      onTap: () => _showAssignmentSheet(context, ref),
      dense: true,
      leading: const Padding(
        padding: EdgeInsets.only(left: 15),
        child: Icon(Atlas.business_man_thin),
      ),
      title: hasAssignees
          ? Text(lang.assignment, style: textTheme.bodySmall)
          : Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                lang.notAssigned,
                style: textTheme.bodyMedium?.copyWith(
                  decoration: TextDecoration.underline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
      subtitle: hasAssignees
          ? Padding(
              padding: const EdgeInsets.only(top: 5),
              child: _buildAssignees(context, assignees, task.roomIdStr(), ref),
            )
          : null,
      trailing: hasAssignees
          ? InkWell(
              onTap: () => _showAssignmentSheet(context, ref),
              child: const Icon(Icons.more_vert),
            )
          : null,
    );
  }

  Widget _buildAssignees(
    BuildContext context,
    List<String> assignees,
    String roomId,
    WidgetRef ref,
  ) {
    return Wrap(
      direction: Axis.horizontal,
      spacing: 5,
      children: assignees
          .map(
            (memberId) => UserChip(
              roomId: roomId,
              memberId: memberId,
              style: Theme.of(context).textTheme.bodyLarge,
              onTap: (context, {required bool isMe, required VoidCallback defaultOnTap}) =>
                  isMe ? onUnAssign(context, ref, task) : defaultOnTap(),
              trailingBuilder: (context, {bool isMe = false, double fontSize = 12}) =>
                  isMe ? Icon(PhosphorIconsLight.x, size: fontSize) : null,
            ),
          )
          .toList(),
    );
  }

  Future<void> _showAssignmentSheet(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      enableDrag: true,
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: true,
      builder: (context) => Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: Text(L10n.of(context).assignment),
          ),
          if (task.isAssignedToMe())
            MenuItemWidget(
              onTap: () {
                onUnAssign(context, ref, task);
                Navigator.pop(context);
              },
              title: lang.removeYourself,
              titleStyles: Theme.of(context).textTheme.bodyMedium,
              iconData: PhosphorIconsLight.x,
              withMenu: false,
              iconColor: Theme.of(context).colorScheme.error,
            )
          else
            MenuItemWidget(
              onTap: () {
                onAssign(context, ref, task);
                Navigator.pop(context);
              },
              title: lang.assignYourself,
              titleStyles: Theme.of(context).textTheme.bodyMedium,
              iconData: PhosphorIconsLight.plus,
              withMenu: false,
            ),
          MenuItemWidget(
            onTap: () {
              context.pushNamed(
                Routes.inviteIndividual.name,
                queryParameters: {
                  'roomId': task.roomIdStr(),
                },
                extra: task,
              );
              Navigator.pop(context);
            },
            title: lang.inviteSomeoneElse,
            withMenu: false,
            iconData: Icons.send,
            titleStyles: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
} 