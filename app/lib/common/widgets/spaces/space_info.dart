import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      data: (space) => Consumer(
        builder: (context, ref, child) {
          final isEncrypted = ref.watch(isEncryptedForSpace(space));
          final isActerSpace = ref.watch(isActerSpaceForSpace(space));
          final joinRuleStr = space.joinRuleStr();

          Widget joinRule;
          switch (joinRuleStr) {
            case 'invite':
              joinRule = Tooltip(
                message: 'This space is invite-only',
                child: Icon(
                  Atlas.shield_envelope_thin,
                  size: size,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            case 'restricted':
              final roomIds =
                  asDartStringList(space.restrictedRoomIdsStr()).join(', ');
              joinRule = Tooltip(
                message: 'Anyone from these rooms can join: $roomIds',
                child: Icon(
                  Atlas.arrow_down_shield_thin,
                  size: size,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            case 'knock':
              joinRule = Tooltip(
                message: 'Anyone can ask to join this space',
                child: Icon(
                  Atlas.arrow_down_shield_thin,
                  size: size,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            case 'knock_restricted':
              final roomIds =
                  asDartStringList(space.restrictedRoomIdsStr()).join(', ');
              joinRule = Tooltip(
                message: 'Anyone from these rooms can ask to join: $roomIds',
                child: Icon(
                  Atlas.arrow_down_shield_thin,
                  size: size,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            case 'public':
              joinRule = Tooltip(
                message: 'This space is publicly accessible',
                child: Icon(
                  Atlas.glasses_vision_thin,
                  size: size,
                  color: Theme.of(context).colorScheme.error,
                ),
              );
            case 'private':
            default:
              joinRule = Tooltip(
                message: 'Unclear join rule: $joinRuleStr',
                child: Icon(
                  Atlas.shield_exclamation_thin,
                  size: size,
                  color: Theme.of(context).colorScheme.error,
                ),
              );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              isActerSpace
                      .whenData(
                        (isProper) => isProper
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(right: 3),
                                child: Tooltip(
                                  message:
                                      'This is not a proper acter space. Some features may not be available.',
                                  child: Icon(
                                    Atlas.triangle_exclamation_thin,
                                    size: size,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                      )
                      .valueOrNull ??
                  const SizedBox.shrink(),
              isEncrypted
                      .whenData(
                        (isEnc) => isEnc
                            ? Tooltip(
                                message: 'This space is end-to-end-encrypted',
                                child: Icon(
                                  Atlas.lock_clipboard_thin,
                                  size: size,
                                  color: Theme.of(context).colorScheme.success,
                                ),
                              )
                            : Tooltip(
                                message:
                                    'This space is not end-to-end-encrypted.',
                                child: Icon(
                                  Atlas.unlock_keyhole_thin,
                                  size: size,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                      )
                      .valueOrNull ??
                  const SizedBox.shrink(),
              joinRule,
            ],
          );
        },
      ),
      error: (e, s) => Text('error: $e'),
      loading: () => const SizedBox.shrink(),
    );
  }
}
