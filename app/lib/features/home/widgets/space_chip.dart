import 'package:acter/common/extensions/options.dart';
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
  final bool useCompactView;
  final VoidCallback? onTapSelectSpace;

  const SpaceChip({
    super.key,
    required this.spaceId,
    this.onTapOpenSpaceDetail = true,
    this.useCompactView = false,
    this.onTapSelectSpace,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (useCompactView) {
      return renderCompactView(context, ref);
    }
    return renderFullChip(context, ref);
  }

  static Widget loading({useCompactView = false}) =>
      useCompactView ? loadingCompact() : loadingFull();

  static Widget loadingFull() => Skeletonizer(
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

  static Widget loadingCompact() => const Skeletonizer(
        child: Wrap(
          children: [
            Text('In: '),
            SizedBox(width: 4),
            Text('displayName'),
          ],
        ),
      );

  Widget renderCompactView(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final displayName =
        ref.watch(roomDisplayNameProvider(spaceId)).valueOrNull ?? spaceId;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          lang.inSpaceLabelInline,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: () {
            if (onTapOpenSpaceDetail) {
              goToSpace(context, spaceId);
              return;
            }
            onTapSelectSpace.map(
              (cb) => cb(),
              orElse: () => goToSpace(context, spaceId),
            );
          },
          child: Text(
            displayName,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(decoration: TextDecoration.underline),
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
