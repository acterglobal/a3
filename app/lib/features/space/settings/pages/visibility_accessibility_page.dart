import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/spaces/has_space_permission.dart';
import 'package:acter/common/widgets/visibility/room_visibilty_type.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::space::settings::visibility_accessibility_settings');

class VisibilityAccessibilityPage extends ConsumerStatefulWidget {
  final String spaceId;

  const VisibilityAccessibilityPage({super.key, required this.spaceId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _VisibilityAccessibilityPageState();
}

class _VisibilityAccessibilityPageState
    extends ConsumerState<VisibilityAccessibilityPage> {
  List<SpaceItem> spaceList = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final spaceVisibility =
        ref.read(spaceVisibilityProvider(widget.spaceId)).valueOrNull;
    if (spaceVisibility != null &&
        spaceVisibility == RoomVisibility.SpaceVisible) {
      _showLimitedSpacesAccess();
    }
  }

  Future<void> _showLimitedSpacesAccess() async {
    final space = await ref.read(spaceProvider(widget.spaceId).future);
    final relations = await space.spaceRelations();
    final mainParent = relations.mainParent();
    final otherParents = relations.otherParents().toList();
    final children = relations.children().toList();
    final linkedSpaces = <SpaceRelation>[];
    if (mainParent != null) {
      linkedSpaces.add(mainParent);
    }
    linkedSpaces.addAll(otherParents);
    linkedSpaces.addAll(children);
    for (SpaceRelation e in linkedSpaces) {
      final profileData = await ref.read(
        spaceProfileDataForSpaceIdProvider(e.roomId().toString()).future,
      );
      spaceList.add(
        SpaceItem(
          roomId: e.roomId().toString(),
          activeMembers: [],
          spaceProfileData: profileData.profile,
        ),
      );
    }
    setState(() {});
  }

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
    );
  }

  Widget _buildBody() {
    final space = ref.watch(spaceProvider(widget.spaceId));
    return space.when(
      data: (spaceData) {
        final spaceId = spaceData.getRoomIdStr();
        return HasSpacePermission(
          spaceId: spaceData.getRoomIdStr(),
          permission: 'CanUpdatePowerLevels',
          fallback: _buildVisibilityUI(spaceData, hasPermission: false),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildVisibilityUI(spaceData),
                const SizedBox(height: 20),
                if (ref.watch(spaceVisibilityProvider(spaceId)).value ==
                    RoomVisibility.SpaceVisible)
                  _buildSpaceWithAccess(spaceData),
              ],
            ),
          ),
        );
      },
      error: (error, stack) => Text(
        L10n.of(context).loadingFailed(error),
      ),
      loading: () => Skeletonizer(
        child: Text(L10n.of(context).loading),
      ),
    );
  }

  Widget _buildVisibilityUI(Space space, {bool hasPermission = true}) {
    final spaceId = space.getRoomIdStr();
    final selectedVisibility = ref.watch(spaceVisibilityProvider(spaceId));
    return selectedVisibility.when(
      data: (visibility) {
        return RoomVisibilityType(
          selectedVisibilityEnum: visibility,
          onVisibilityChange: !hasPermission
              ? (value) =>
                  EasyLoading.showToast(L10n.of(context).visibilityNoPermission)
              : (value) {
                  if (value == RoomVisibility.SpaceVisible &&
                      spaceList.isEmpty) {
                    selectSpace(spaceId);
                  } else {
                    updateSpaceVisibility(
                      value ?? RoomVisibility.Private,
                      spaceId,
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

  Widget _buildSpaceWithAccess(Space spaceData) {
    final spaceId = spaceData.getRoomIdStr();
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
              IconButton(
                onPressed: () => selectSpace(spaceId),
                icon: const Icon(Atlas.plus_circle),
              ),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: spaceList.length,
            itemBuilder: (context, index) {
              final spaceItem = spaceList[index];
              return spaceItemUI(spaceData, spaceItem);
            },
          ),
        ],
      ),
    );
  }

  Widget spaceItemUI(Space? space, SpaceItem spaceItem) {
    final avatar = ActerAvatar(
      options: AvatarOptions(
        AvatarInfo(
          uniqueId: spaceItem.roomId,
          displayName: spaceItem.spaceProfileData.displayName,
          avatar: spaceItem.spaceProfileData.getAvatarImage(),
        ),
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
          spaceItem.spaceProfileData.displayName ?? spaceItem.roomId,
        ),
        leading: avatar,
        trailing: IconButton(
          onPressed: () => removeSpace(space, spaceItem),
          icon: Icon(
            Atlas.trash,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }

  Future<void> removeSpace(Space? space, SpaceItem spaceItem) async {
    final room =
        await ref.read(maybeRoomProvider(space!.getRoomIdStr()).future);
    if (room != null) {
      if (await space.isChildSpaceOf(spaceItem.roomId)) {
        await room.removeParentRoom(spaceItem.roomId, null);
      } else {
        await space.removeChildRoom(spaceItem.roomId, null);
      }
    }
    setState(() {
      spaceList.remove(spaceItem);
      if (spaceList.isEmpty) {
        selectSpace(space.getRoomIdStr());
      }
    });
  }

  Future<void> selectSpace(String roomId) async {
    try {
      final spaceId = await selectSpaceDrawer(context: context);
      if (spaceId != null) {
        final spaceItem =
            await ref.watch(maybeSpaceInfoProvider(spaceId).future);
        final isAlreadyAdded =
            spaceList.any((element) => element.roomId == spaceItem?.roomId);
        if (spaceItem != null && !isAlreadyAdded) {
          spaceList.add(spaceItem);
          updateSpaceVisibility(
            RoomVisibility.SpaceVisible,
            spaceId,
            roomId: roomId,
          );
          setState(() {});
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
    RoomVisibility value,
    String spaceId, {
    String? roomId,
  }) async {
    try {
      EasyLoading.show(status: 'Updating space settings', dismissOnTap: false);
      final sdk = await ref.read(sdkProvider.future);
      final room = await ref.read(maybeRoomProvider(spaceId).future);
      final space = await ref.read(maybeSpaceProvider(spaceId).future);
      final update = sdk.api.newJoinRuleBuilder();
      switch (value) {
        case RoomVisibility.Public:
          update.joinRule('public');
          break;
        case RoomVisibility.Private:
          update.joinRule('invite');
          break;
        case RoomVisibility.SpaceVisible:
          update.joinRule('restricted');
          if (roomId != null) {
            if (!(await space!.isChildSpaceOf(roomId))) {
              await room!.addParentRoom(roomId, true);
              break;
            } else {
              await space.addChildRoom(roomId);
              break;
            }
          }
          break;
      }

      await room!.setJoinRule(update);
      EasyLoading.dismiss();
    } catch (e) {
      _log.severe('Error updating visibility: $e');
      EasyLoading.showError('Error updating visibility: $e');
      return;
    }
  }
}
