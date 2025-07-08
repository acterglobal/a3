import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/tasks/actions/assign_unassign_task.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AcceptDeclineTaskInvitationWidget extends ConsumerWidget {
  final Task task;
  const AcceptDeclineTaskInvitationWidget({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final roomId = task.roomIdStr();
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: '')),
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerLowest),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                avatarInfo.displayName != null ? ActerAvatar(options: AvatarOptions.DM(avatarInfo, size: 16)) : const Icon(Icons.person),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                  lang.invitedYouToTakeOverThisTask,
                ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ActerPrimaryActionButton.icon(
                  onPressed: () {onAssign(context, ref, task);},
                  icon: const Icon(Icons.check),
                  label: Text(lang.accept),
                ),
                ActerInlineTextButton(
                  onPressed: () {onUnAssign(context, ref, task);},
                  child: Text(lang.decline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
