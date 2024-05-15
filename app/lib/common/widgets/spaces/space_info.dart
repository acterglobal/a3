import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';

final isActerSpaceForSpace =
    FutureProvider.autoDispose.family<bool, Space>((ref, space) async {
  return await space.isActerSpace();
});

final isEncryptedForSpace =
    FutureProvider.autoDispose.family<bool, Space>((ref, space) async {
  return await space.isEncrypted();
});

class SpaceInfo extends ConsumerWidget {
  final String spaceId;
  final double size;

  const SpaceInfo({super.key, this.size = 16, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(spaceId));
    return space.when(
      data: (space) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            acterSpaceInfoUI(context, ref, space),
            encryptedInfoUI(context, ref, space),
            joinRuleUI(context, space),
          ],
        );
      },
      error: (e, s) => Text(L10n.of(context).error(e)),
      loading: () => skeletonUI(),
    );
  }

  Widget skeletonUI() {
    return Skeletonizer(
      child: Row(
        children: [
          Tooltip(
            message: '',
            child: Icon(
              Atlas.glasses_vision_thin,
              size: size,
            ),
          ),
          Tooltip(
            message: '',
            child: Icon(
              Atlas.lock_clipboard_thin,
              size: size,
            ),
          ),
          Tooltip(
            message: '',
            child: Icon(
              Atlas.shield_exclamation_thin,
              size: size,
            ),
          ),
        ],
      ),
    );
  }

  Widget acterSpaceInfoUI(BuildContext context, WidgetRef ref, Space space) {
    final isActerSpace = ref.watch(isActerSpaceForSpace(space));
    return isActerSpace
            .whenData(
              (isProper) => isProper
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Tooltip(
                        message: L10n.of(context).thisIsNotAProperActerSpace,
                        child: Icon(
                          Atlas.triangle_exclamation_thin,
                          size: size,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
            )
            .valueOrNull ??
        const SizedBox.shrink();
  }

  Widget encryptedInfoUI(BuildContext context, WidgetRef ref, Space space) {
    final isEncrypted = ref.watch(isEncryptedForSpace(space));
    return isEncrypted
            .whenData(
              (isEnc) => isEnc
                  ? Tooltip(
                      message: L10n.of(context).thisApaceIsEndToEndEncrypted,
                      child: Icon(
                        Atlas.lock_clipboard_thin,
                        size: size,
                        color: Theme.of(context).colorScheme.success,
                      ),
                    )
                  : Tooltip(
                      message: L10n.of(context).thisApaceIsNotEndToEndEncrypted,
                      child: Icon(
                        Atlas.unlock_keyhole_thin,
                        size: size,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
            )
            .valueOrNull ??
        const SizedBox.shrink();
  }

  Widget joinRuleUI(BuildContext context, Space space) {
    final joinRuleStr = space.joinRuleStr();
    switch (joinRuleStr) {
      case 'invite':
        return Tooltip(
          message: L10n.of(context).thisSpaceIsInviteOnly,
          child: Icon(
            Atlas.shield_envelope_thin,
            size: size,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      case 'restricted':
        final roomIds =
            asDartStringList(space.restrictedRoomIdsStr()).join(', ');
        return Tooltip(
          message: L10n.of(context).anyoneFromTheseRoomsCanJoin(roomIds),
          child: Icon(
            Atlas.arrow_down_shield_thin,
            size: size,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      case 'knock':
        return Tooltip(
          message: L10n.of(context).anyoneCanAskToJoinThisSpace,
          child: Icon(
            Atlas.arrow_down_shield_thin,
            size: size,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      case 'knock_restricted':
        final roomIds =
            asDartStringList(space.restrictedRoomIdsStr()).join(', ');
        return Tooltip(
          message: L10n.of(context).anyoneFromTheseRoomsCanAskToJoin(roomIds),
          child: Icon(
            Atlas.arrow_down_shield_thin,
            size: size,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      case 'public':
        return Tooltip(
          message: L10n.of(context).thisSpaceIsPubliclyAccessible,
          child: Icon(
            Atlas.glasses_vision_thin,
            size: size,
            color: Theme.of(context).colorScheme.error,
          ),
        );
      case 'private':
      default:
        return Tooltip(
          message: L10n.of(context).unclearJoinRule(joinRuleStr),
          child: Icon(
            Atlas.shield_exclamation_thin,
            size: size,
            color: Theme.of(context).colorScheme.error,
          ),
        );
    }
  }
}
