import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceMemberInviteCard extends ConsumerWidget {
  final Space space;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const SpaceMemberInviteCard({
    super.key,
    required this.space,
    this.isSelected = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(spaceProfileDataProvider(space));

    return profile.when(
      data: (profile) => _spaceItemUI(context, ref, profile),
      error: (error, stack) => ListTile(
        title: Text(
          L10n.of(context).errorLoadingSpace(error),
        ),
      ),
      loading: () => Skeletonizer(
        child: ListTile(
          title: Text(space.getRoomIdStr()),
          subtitle: Text(L10n.of(context).loading),
        ),
      ),
    );
  }

  Widget _spaceItemUI(
    BuildContext context,
    WidgetRef ref,
    ProfileData profile,
  ) {
    final roomId = space.getRoomIdStr();
    final title =
        profile.displayName?.isNotEmpty == true ? profile.displayName! : roomId;
    final parentBadges =
        ref.watch(parentAvatarInfosProvider(roomId)).valueOrNull;

    final avatar = ActerAvatar(
      options: AvatarOptions(
        AvatarInfo(
          uniqueId: roomId,
          displayName: title,
          avatar: profile.getAvatarImage(),
        ),
        parentBadges: parentBadges,
        size: 45,
        badgesSize: 45 / 2,
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: FutureBuilder(
          future: space.activeMembersIds(),
          builder: (context, snapshot) {
            final memberCount = snapshot.data?.length ?? 0;
            return Text(
              L10n.of(context).countsMembers(memberCount),
              style: Theme.of(context).textTheme.bodySmall,
            );
          },
        ),
        leading: avatar,
        onTap: () => onChanged(!isSelected),
        trailing: Checkbox(
          value: isSelected,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
