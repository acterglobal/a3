import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceMemberInviteCard extends ConsumerWidget {
  final String roomId;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const SpaceMemberInviteCard({
    super.key,
    required this.roomId,
    this.isSelected = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final title =
        ref.watch(roomDisplayNameProvider(roomId)).valueOrNull ?? roomId;
    final roomAvatar = ref.watch(roomAvatarInfoProvider(roomId));
    final parentBadges =
        ref.watch(parentAvatarInfosProvider(roomId)).valueOrNull;

    final avatar = ActerAvatar(
      options: AvatarOptions(
        roomAvatar,
        parentBadges: parentBadges,
        size: 45,
        badgesSize: 45 / 2,
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: ListTile(
        title: Text(title, style: textTheme.titleSmall),
        subtitle: FutureBuilder(
          future: ref.watch(membersIdsProvider(roomId).future),
          builder: (context, snapshot) {
            final memberCount = snapshot.data?.length ?? 0;
            return Text(
              L10n.of(context).countsMembers(memberCount),
              style: textTheme.bodySmall,
            );
          },
        ),
        leading: avatar,
        onTap: () => onChanged(!isSelected),
        trailing: Checkbox(value: isSelected, onChanged: onChanged),
      ),
    );
  }
}
