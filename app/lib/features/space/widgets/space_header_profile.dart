import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/common/widgets/spaces/space_info.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
              size: 70,
              badgesSize: 30,
            ),
          ),
          const SizedBox(width: 8),
          Column(
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
                padding: const EdgeInsets.only(bottom: 10, left: 10),
                child: SpaceInfo(spaceId: spaceId),
              ),
            ],
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
}
