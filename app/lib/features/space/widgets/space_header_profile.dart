import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/common/widgets/spaces/space_info.dart';
import 'package:acter/features/space/widgets/member_avatar.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::space::space_header');

class SpaceHeaderProfile extends ConsumerWidget {
  static const headerKey = Key('space-header');

  final String spaceId;

  const SpaceHeaderProfile(this.spaceId, {super.key = headerKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceAvatarInfo = ref.watch(roomAvatarInfoProvider(spaceId));
    final parentBadges =
        ref.watch(parentAvatarInfosProvider(spaceId)).valueOrNull;
    final membership = ref.watch(roomMembershipProvider(spaceId)).valueOrNull;

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        children: <Widget>[
          ActerAvatar(
            options: AvatarOptions(
              AvatarInfo(
                uniqueId: spaceId,
                displayName: spaceAvatarInfo.displayName,
                avatar: spaceAvatarInfo.avatar,
                onAvatarTap: () => openAvatar(context, ref, spaceId),
              ),
              parentBadges: parentBadges,
              size: 100,
              badgesSize: 30,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SelectionArea(
                  child: GestureDetector(
                    onTap: () {
                      if (membership?.canString('CanSetName') == true) {
                        showEditSpaceNameBottomSheet(
                          context: context,
                          titleValue: spaceAvatarInfo.displayName ?? '',
                          spaceId: spaceId,
                          ref: ref,
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        spaceAvatarInfo.displayName ?? spaceId,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 10),
                  child: SpaceInfo(spaceId: spaceId),
                ),
                Consumer(builder: spaceMembersBuilder),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showEditSpaceNameBottomSheet({
    required BuildContext context,
    required String titleValue,
    required String spaceId,
    required WidgetRef ref,
  }) {
    showEditTitleBottomSheet(
      context: context,
      bottomSheetTitle: L10n.of(context).editName,
      titleValue: titleValue,
      onSave: (newName) async {
        try {
          EasyLoading.show(status: L10n.of(context).updateName);
          final space = await ref.read(spaceProvider(spaceId).future);
          await space.setName(newName);
          EasyLoading.dismiss();
          if (!context.mounted) return;
          context.pop();
        } catch (e, st) {
          _log.severe('Failed to edit space name', e, st);
          EasyLoading.dismiss();
          if (!context.mounted) return;
          EasyLoading.showError(L10n.of(context).updateNameFailed(e));
        }
      },
    );
  }

  Widget spaceMembersBuilder(
    BuildContext context,
    WidgetRef ref,
    Widget? child,
  ) {
    final spaceMembers = ref.watch(membersIdsProvider(spaceId));
    return spaceMembers.when(
      data: (members) {
        final membersCount = members.length;
        if (membersCount > 5) {
          // too many to display, means we limit to 5
          members = members.sublist(0, 5);
        }
        return Padding(
          padding: const EdgeInsets.only(left: 10),
          child: GestureDetector(
            onTap: () => context.pushNamed(
              Routes.spaceMembers.name,
              pathParameters: {'spaceId': spaceId},
            ),
            child: Wrap(
              direction: Axis.horizontal,
              spacing: -8,
              children: [
                ...members.map(
                  (a) => MemberAvatar(memberId: a, roomId: spaceId),
                ),
                if (membersCount > 5)
                  SizedBox(
                    height: 30,
                    width: 30,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: Text(
                        '+${membersCount - 5}',
                        textAlign: TextAlign.center,
                        textScaler: const TextScaler.linear(0.8),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      error: (error, stack) => Text(
        L10n.of(context).loadingMembersFailed(error),
      ),
      loading: () => const Skeletonizer(
        child: Wrap(
          direction: Axis.horizontal,
          spacing: -12,
          children: [
            CircleAvatar(child: Text('0')),
            CircleAvatar(child: Text('1')),
            CircleAvatar(child: Text('2')),
            CircleAvatar(child: Text('3')),
            CircleAvatar(child: Text('4')),
            CircleAvatar(child: Text('5')),
          ],
        ),
      ),
    );
  }
}
