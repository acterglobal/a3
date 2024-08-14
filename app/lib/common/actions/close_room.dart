import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/room/room_profile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::close');

Future<bool> openCloseRoomDialog({
  required BuildContext context,
  required final String roomId,
  final Key? cancelBtnKey,
  final Key? confirmBtnKey,
}) async {
  final removedRoom = await showAdaptiveDialog(
    context: context,
    useRootNavigator: false,
    builder: (context) => _CloseRoomConfirmation(
      roomId: roomId,
      cancelBtnKey: cancelBtnKey,
      confirmBtnKey: confirmBtnKey,
    ),
  );
  if (removedRoom && context.mounted) {
    // redirect the user after the process is done
    context.goNamed(Routes.main.name);
  }
  return removedRoom;
}

class _CloseRoomConfirmation extends ConsumerStatefulWidget {
  final String roomId;
  final Key? cancelBtnKey;
  final Key? confirmBtnKey;
  const _CloseRoomConfirmation({
    required this.roomId,
    this.cancelBtnKey,
    this.confirmBtnKey,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CloseRoomConfirmationState();
}

class _CloseRoomConfirmationState
    extends ConsumerState<_CloseRoomConfirmation> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.5,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            minHeight: 0.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                _buildHeader(context, ref),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      key: widget.cancelBtnKey,
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(L10n.of(context).cancel),
                    ),
                    const SizedBox(width: 5),
                    ActerDangerActionButton(
                      key: widget.confirmBtnKey,
                      onPressed: () {
                        EasyLoading.showToast(
                          L10n.of(context).longPressToActivate,
                        );
                      },
                      onLongPress: () => _closeRoom(context, ref),
                      child: Text(L10n.of(context).close),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RoomProfileHeader(roomId: widget.roomId),
        const SizedBox(height: 10),
        Text(
          L10n.of(context).closingRoomTitle,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 5),
        Text(
          L10n.of(context).closingRoomTitleDescription,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  void _closeRoom(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.closingRoom);
    try {
      final myUserId = ref.read(myUserIdStrProvider);
      final room = await ref.read(maybeRoomProvider(widget.roomId).future);
      final myMembership =
          await ref.read(roomMembershipProvider(widget.roomId).future);
      if (room == null || myMembership == null) {
        throw RoomNotFound();
      }

      final myPowerLevel = myMembership.powerLevel();
      final memberIds =
          await ref.read(membersIdsProvider(widget.roomId).future);
      final total = memberIds.length;
      var kicked = 0;
      var skipped = 0;

      if (total > 1) {
        final actualMembers = [];
        for (final memberId in memberIds) {
          if (memberId == myUserId) {
            // we will leave at the end.
            continue;
          }
          final member = await ref.read(
            memberProvider((roomId: widget.roomId, userId: memberId)).future,
          );
          if (member.powerLevel() >= myPowerLevel) {
            // we can't kick them if they are the same level or higher than ours.
            skipped += 1;
            continue;
          }
          actualMembers.add(member);
        }
        for (final member in actualMembers) {
          EasyLoading.showProgress(
            (kicked + skipped) / total,
            status: lang.closingRoomRemovingMembers(kicked, total),
          );
          await member.kick(lang.closingRoomMatrixMsg);
          kicked += 1;
        }
      }

      // removing from parents
      final parents = await ref.read(parentIdsProvider(widget.roomId).future);

      var skippedParents = 0;
      if (parents.isNotEmpty) {
        var currentParent = 0;
        final totalParents = parents.length;
        for (final parentId in parents) {
          currentParent += 1;
          EasyLoading.showProgress(
            currentParent / totalParents,
            status: lang.closingRoomRemovingFromParents(
              currentParent,
              totalParents,
            ),
          );
          final parent = await ref.read(maybeSpaceProvider(parentId).future);

          if (parent == null) {
            skippedParents += 1;
            continue;
          }
          final myParentMembership =
              await ref.read(roomMembershipProvider(parentId).future);

          if (myParentMembership?.canString('CanLinkSpaces') != true) {
            skippedParents += 1;
            continue;
          }

          await parent.removeChildRoom(
            widget.roomId,
            lang.closingRoomMatrixMsg,
          );

          ref.invalidate(spaceRelationsProvider(parentId));
        }
      }

      EasyLoading.show(status: lang.closingRoom);
      final sdk = await ref.read(sdkProvider.future);
      final update = sdk.api.newJoinRuleBuilder();
      update.joinRule('invite');
      await room.setJoinRule(update);

      await room.leave();

      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      if (skippedParents < 0 || skipped > 0) {
        EasyLoading.showToast(lang.closingRoomDoneBut(skipped, skippedParents));
      } else {
        EasyLoading.showToast(lang.closingRoomDone);
      }
      Navigator.pop(context, true);
    } catch (error, stack) {
      _log.severe('Failure in closing room', error, stack);
      EasyLoading.showError(
        L10n.of(context).closingRoomFailed(error),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
