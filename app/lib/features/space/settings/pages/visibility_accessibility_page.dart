import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/spaces/has_space_permission.dart';
import 'package:acter/common/widgets/visibility/room_visibilty_type.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::space::settings::visibility_accessibility_settings');

class VisibilityAccessibilityPage extends ConsumerStatefulWidget {
  final String roomId;
  final bool showCloseX;

  const VisibilityAccessibilityPage({
    super.key,
    required this.roomId,
    this.showCloseX = false,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _VisibilityAccessibilityPageState();
}

class _VisibilityAccessibilityPageState
    extends ConsumerState<VisibilityAccessibilityPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppbar() {
    return AppBar(
      title: Text(L10n.of(context).visibilityAndAccessibility),
      centerTitle: true,
      // custom x-circle when we are in widescreen mode;
      leading: widget.showCloseX
          ? IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Atlas.xmark_circle_thin),
            )
          : null,
    );
  }

  Widget _buildBody() {
    return HasSpacePermission(
      spaceId: widget.roomId,
      permission: 'CanUpdateJoinRule',
      fallback: SingleChildScrollView(
        child: Column(
          children: [
            _buildVisibilityUI(hasPermission: false),
            const SizedBox(height: 20),
            if (ref.watch(roomVisibilityProvider(widget.roomId)).value ==
                RoomVisibility.SpaceVisible)
              _buildSpaceWithAccess(hasPermission: false),
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildVisibilityUI(),
            const SizedBox(height: 20),
            if (ref.watch(roomVisibilityProvider(widget.roomId)).value ==
                RoomVisibility.SpaceVisible)
              _buildSpaceWithAccess(),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityUI({bool hasPermission = true}) {
    final spaceId = widget.roomId;
    final selectedVisibility = ref.watch(roomVisibilityProvider(spaceId));
    final spaceList = ref.watch(joinRulesAllowedRoomsProvider(spaceId));
    return selectedVisibility.when(
      data: (visibility) {
        return RoomVisibilityType(
          selectedVisibilityEnum: visibility,
          canChange: hasPermission,
          onVisibilityChange: !hasPermission
              ? (value) =>
                  EasyLoading.showToast(L10n.of(context).visibilityNoPermission)
              : (value) {
                  if (value == RoomVisibility.SpaceVisible &&
                      spaceList.valueOrNull?.isEmpty == true) {
                    selectSpace(spaceId);
                  } else {
                    updateSpaceVisibility(
                      value ?? RoomVisibility.Private,
                      spaceIds: (spaceList.valueOrNull ?? []),
                    );
                  }
                },
        );
      },
      error: (e, st) => const RoomVisibilityType(
        selectedVisibilityEnum: RoomVisibility.Private,
      ),
      loading: () => const Skeletonizer(
        child: RoomVisibilityType(
          selectedVisibilityEnum: RoomVisibility.Private,
        ),
      ),
    );
  }

  Widget _buildSpaceWithAccess({bool hasPermission = true}) {
    final spaceIds = ref.watch(joinRulesAllowedRoomsProvider(widget.roomId));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                L10n.of(context).spaceWithAccess,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (hasPermission)
                IconButton(
                  onPressed: () => selectSpace(widget.roomId),
                  icon: const Icon(Atlas.plus_circle),
                ),
            ],
          ),
          spaceIds.when(
            data: (spacesList) => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: spacesList.length,
              itemBuilder: (context, index) {
                return _spaceItemUI(spacesList[index], hasPermission);
              },
            ),
            error: (error, stack) {
              _log.severe('Loading Space Info failed', error, stack);
              return _spaceItemCard(
                'Loading Space Info failed',
                subtitle: Text('$error'),
              );
            },
            loading: _loadingSpaceItem,
          ),
        ],
      ),
    );
  }

  Widget _loadingSpaceItem() {
    return Skeletonizer(
      child: _spaceItemCard(
        'loading',
      ),
    );
  }

  Widget _spaceItemCard(
    String title, {
    Widget? avatar,
    Widget? subtitle,
    void Function()? removeAction,
  }) {
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
        title: Text(title),
        leading: avatar ??
            ActerAvatar(
              options: const AvatarOptions(
                AvatarInfo(
                  uniqueId: 'unknown',
                ),
                size: 45,
                badgesSize: 45 / 2,
              ),
            ),
        subtitle: subtitle,
        trailing: IconButton(
          onPressed: removeAction,
          icon: Icon(
            Atlas.trash,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }

  Widget _spaceItemUI(String spaceId, bool canEdit) {
    return ref.watch(briefSpaceItemProvider(spaceId)).when(
          data: (d) => _spaceFoundUI(d, canEdit),
          error: (error, stack) {
            _log.severe('Loading Space Info failed', error, stack);
            return _spaceItemCard(
              spaceId,
              subtitle: Text('Loading Space Info failed: $error'),
              removeAction: canEdit ? () => removeSpace(spaceId) : null,
            );
          },
          loading: _loadingSpaceItem,
        );
  }

  Widget _spaceFoundUI(SpaceItem spaceItem, bool canEdit) {
    return _spaceItemCard(
      spaceItem.spaceProfileData.displayName ?? spaceItem.roomId,
      avatar: ActerAvatar(
        options: AvatarOptions(
          AvatarInfo(
            uniqueId: spaceItem.roomId,
            displayName: spaceItem.spaceProfileData.displayName,
            avatar: spaceItem.spaceProfileData.getAvatarImage(),
          ),
          size: 45,
          badgesSize: 45 / 2,
        ),
      ),
      removeAction: canEdit ? () => removeSpace(spaceItem.roomId) : null,
    );
  }

  Future<void> removeSpace(String spaceId) async {
    final newList =
        (await ref.read(joinRulesAllowedRoomsProvider(spaceId).future))
            .where((id) => id != spaceId)
            .toList();
    final visibility =
        newList.isEmpty ? RoomVisibility.Private : RoomVisibility.SpaceVisible;
    await updateSpaceVisibility(visibility, spaceIds: newList);
  }

  Future<void> selectSpace(String roomId) async {
    try {
      final spaceId = await selectSpaceDrawer(context: context);
      if (spaceId != null) {
        final spaceList =
            await ref.read(joinRulesAllowedRoomsProvider(spaceId).future);
        final isAlreadyAdded = spaceList.any((roomId) => roomId == spaceId);
        if (!isAlreadyAdded) {
          spaceList.add(spaceId);
          await updateSpaceVisibility(
            RoomVisibility.SpaceVisible,
            spaceIds: spaceList,
          );
        }
      }
    } catch (e, st) {
      _log.severe('Select Space Error =>>', e, st);
      if (!mounted) return;
      EasyLoading.showToast(
        L10n.of(context).failedToLoadSpace(e),
        toastPosition: EasyLoadingToastPosition.bottom,
      );
    }
  }

  Future<void> updateSpaceVisibility(
    RoomVisibility value, {
    List<String>? spaceIds,
  }) async {
    try {
      EasyLoading.show(status: 'Updating space settings', dismissOnTap: false);
      final sdk = await ref.read(sdkProvider.future);
      final update = sdk.api.newJoinRuleBuilder();
      final room = await ref.read(maybeRoomProvider(widget.roomId).future);
      if (room == null) {
        // should never actually happen in practice.
        throw 'Room not found';
      }
      switch (value) {
        case RoomVisibility.Public:
          update.joinRule('public');
          break;
        case RoomVisibility.Private:
          update.joinRule('invite');
          break;
        case RoomVisibility.SpaceVisible:
          update.joinRule('restricted');
          for (final roomId in (spaceIds ?? [])) {
            update.addRoom(roomId);
          }
      }

      await room.setJoinRule(update);
      EasyLoading.dismiss();
    } catch (e) {
      _log.severe('Error updating visibility: $e');
      EasyLoading.showError('Error updating visibility: $e');
      return;
    }
  }
}
