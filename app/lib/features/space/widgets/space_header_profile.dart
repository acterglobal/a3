import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/spaces/space_info.dart';
import 'package:acter/features/space/widgets/member_avatar.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceHeaderProfile extends ConsumerWidget {
  static const headerKey = Key('space-header');

  final String spaceId;

  const SpaceHeaderProfile(this.spaceId, {super.key = headerKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileData = ref.watch(spaceProfileDataForSpaceIdProvider(spaceId));
    final canonicalParent = ref.watch(canonicalParentProvider(spaceId));
    return profileData.when(
      data: (spaceProfile) {
        return Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: <Widget>[
              ActerAvatar(
                mode: DisplayMode.Space,
                avatarInfo: AvatarInfo(
                  uniqueId: spaceId,
                  displayName: spaceProfile.profile.displayName,
                  avatar: spaceProfile.profile.getAvatarImage(),
                ),
                avatarsInfo: canonicalParent.valueOrNull != null
                    ? [
                        AvatarInfo(
                          uniqueId:
                              canonicalParent.valueOrNull!.space.getRoomIdStr(),
                          displayName:
                              canonicalParent.valueOrNull!.profile.displayName,
                          avatar: canonicalParent.valueOrNull!.profile
                              .getAvatarImage(),
                        ),
                      ]
                    : [],
                onAvatarTap: () => goToSpace(context, spaceId),
                onParentBadgeTap: () => goToSpace(
                  context,
                  canonicalParent.valueOrNull!.space.getRoomIdStr(),
                ),
                badgeSize: 30,
                size: 80,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      spaceProfile.profile.displayName ?? spaceId,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, left: 10),
                    child: SpaceInfo(spaceId: spaceId),
                  ),
                  Consumer(builder: spaceMembersBuilder),
                ],
              ),
            ],
          ),
        );
      },
      error: (error, stack) => Text(
        L10n.of(context).loadingFailed(error),
      ),
      loading: () => Text(L10n.of(context).loading),
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
            onTap: () => context.goNamed(
              Routes.spaceMembers.name,
              pathParameters: {'spaceId': spaceId},
            ),
            child: Wrap(
              direction: Axis.horizontal,
              spacing: -12,
              children: [
                ...members.map(
                  (a) => MemberAvatar(memberId: a, roomId: spaceId),
                ),
                if (membersCount > 5)
                  CircleAvatar(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
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
