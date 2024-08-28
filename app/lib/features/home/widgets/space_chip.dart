import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SpaceChip extends ConsumerWidget {
  final String spaceId;
  final bool onTapOpenSpaceDetail;
  final bool useCompatView;
  final VoidCallback? onTapSelectSpace;

  const SpaceChip({
    super.key,
    required this.spaceId,
    this.onTapOpenSpaceDetail = true,
    this.useCompatView = false,
    this.onTapSelectSpace,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (useCompatView) {
      return renderCompactView(context, ref);
    }
    return renderFullChip(context, ref);
  }

  static Widget loading() {
    return Skeletonizer(
      child: Chip(
        avatar: ActerAvatar(
          options: const AvatarOptions(
            AvatarInfo(uniqueId: 'unique Id'),
            size: 24,
          ),
        ),
        label: const Text('unique name'),
      ),
    );
  }

  Widget renderCompactView(BuildContext context, WidgetRef ref) {
    final displayName =
        ref.watch(roomDisplayNameProvider(spaceId)).valueOrNull ?? spaceId;
    return Row(
      children: [
        Text(L10n.of(context).inSpaceLabelInline),
        Text(L10n.of(context).colonCharacter),
        InkWell(
          onTap: () {
            if (!onTapOpenSpaceDetail) {
              if (onTapSelectSpace != null) {
                onTapSelectSpace!();
                return;
              }
            }
            goToSpace(context, spaceId);
          },
          child: Text(
            displayName,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
      ],
    );
  }

  Widget renderFullChip(BuildContext context, WidgetRef ref) {
    final avatarInfo = ref.watch(roomAvatarInfoProvider(spaceId));
    final spaceName = avatarInfo.displayName ?? spaceId;
    return InkWell(
      onTap: () {
        if (onTapOpenSpaceDetail) goToSpace(context, spaceId);
      },
      child: Chip(
        avatar: ActerAvatar(
          options: AvatarOptions(
            avatarInfo,
            size: 24,
          ),
        ),
        label: Text(spaceName),
      ),
    );
  }
}
