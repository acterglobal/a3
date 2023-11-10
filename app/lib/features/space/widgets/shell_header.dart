import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/spaces/space_info.dart';
import 'package:acter/common/widgets/spaces/space_parent_badge.dart';
import 'package:acter/features/space/widgets/member_avatar.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ShellHeader extends ConsumerWidget {
  final String spaceId;

  const ShellHeader(this.spaceId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileData = ref.watch(spaceProfileDataForSpaceIdProvider(spaceId));
    return profileData.when(
      data: (spaceProfile) {
        return Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: <Widget>[
              SpaceParentBadge(
                roomId: spaceId,
                badgeSize: 40,
                child: ActerAvatar(
                  mode: DisplayMode.Space,
                  displayName: spaceProfile.profile.displayName,
                  tooltip: TooltipStyle.None,
                  uniqueId: spaceId,
                  avatar: spaceProfile.profile.getAvatarImage(),
                  size: 80,
                ),
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
      error: (error, stack) => Text('Loading failed: $error'),
      loading: () => const Text('Loading'),
    );
  }

  Widget spaceMembersBuilder(
    BuildContext context,
    WidgetRef ref,
    Widget? child,
  ) {
    final spaceMembers = ref.watch(spaceMembersProvider(spaceId));
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
                  (a) => MemberAvatar(member: a),
                ),
                if (membersCount > 5)
                  CircleAvatar(
                    child: Text(
                      '+${membersCount - 5}',
                      textAlign: TextAlign.center,
                      textScaleFactor: 0.8,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      error: (error, stack) => Text('Loading members failed: $error'),
      loading: () => const CircularProgressIndicator(),
    );
  }
}
