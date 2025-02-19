import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/spaces/has_space_permission.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter/common/widgets/visibility/room_visibilty_type.dart';
import 'package:acter/features/room/model/room_visibility.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::space::settings::visibility_accessibility');

class VisibilityAccessibilityPage extends ConsumerStatefulWidget {
  final String roomId;
  final bool impliedClose;

  const VisibilityAccessibilityPage({
    super.key,
    required this.roomId,
    this.impliedClose = false,
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
      automaticallyImplyLeading: !context.isLargeScreen,
      leading: widget.impliedClose
          ? IconButton(
              onPressed: () => Navigator.pop(context),
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
    final visibilityLoader = ref.watch(roomVisibilityProvider(spaceId));
    final allowedSpaces = ref.watch(joinRulesAllowedRoomsProvider(spaceId));
    return visibilityLoader.when(
      data: (visibility) => RoomVisibilityType(
        selectedVisibilityEnum: visibility,
        canChange: hasPermission,
        onVisibilityChange: (value) {
          if (!hasPermission) {
            EasyLoading.showToast(L10n.of(context).visibilityNoPermission);
            return;
          }
          if (value == RoomVisibility.SpaceVisible &&
              allowedSpaces.valueOrNull?.isEmpty == true) {
            selectSpace(spaceId);
          } else {
            updateSpaceVisibility(
              value ?? RoomVisibility.Private,
              spaceIds: (allowedSpaces.valueOrNull ?? []),
            );
          }
        },
      ),
      error: (e, s) {
        _log.severe('Failed to load room visibility', e, s);
        return const RoomVisibilityType(
          selectedVisibilityEnum: RoomVisibility.Private,
        );
      },
      loading: () => const Skeletonizer(
        child: RoomVisibilityType(
          selectedVisibilityEnum: RoomVisibility.Private,
        ),
      ),
    );
  }

  Widget _buildSpaceWithAccess({bool hasPermission = true}) {
    final allowedSpacesLoader =
        ref.watch(joinRulesAllowedRoomsProvider(widget.roomId));
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
          allowedSpacesLoader.when(
            data: (allowedSpaces) => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allowedSpaces.length,
              itemBuilder: (context, index) {
                return _spaceItemUI(allowedSpaces[index], hasPermission);
              },
            ),
            error: (e, s) {
              _log.severe('Failed to load the allowed rooms', e, s);
              return _spaceItemCard(
                'Loading Spaces failed',
                subtitle: Text(e.toString()),
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
      child: _spaceItemCard('loading'),
    );
  }

  Widget _spaceItemCard(
    String title, {
    Widget? avatar,
    Widget? subtitle,
    void Function()? removeAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: colorScheme.primary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        title: Text(title),
        leading: avatar ??
            ActerAvatar(
              options: const AvatarOptions(
                AvatarInfo(uniqueId: 'unknown'),
                size: 45,
                badgesSize: 45 / 2,
              ),
            ),
        subtitle: subtitle,
        trailing: IconButton(
          onPressed: removeAction,
          icon: Icon(
            Atlas.trash,
            color: colorScheme.error,
          ),
        ),
      ),
    );
  }

  Widget _spaceItemUI(String spaceId, bool canEdit) {
    final space = ref.watch(briefSpaceItemProvider(spaceId));
    return _spaceFoundUI(space, canEdit);
  }

  Widget _spaceFoundUI(SpaceItem spaceItem, bool canEdit) {
    return _spaceItemCard(
      spaceItem.avatarInfo.displayName ?? spaceItem.roomId,
      avatar: ActerAvatar(
        options: AvatarOptions(
          AvatarInfo(
            uniqueId: spaceItem.roomId,
            displayName: spaceItem.avatarInfo.displayName,
            avatar: spaceItem.avatarInfo.avatar,
          ),
          size: 45,
          badgesSize: 45 / 2,
        ),
      ),
      removeAction: () {
        if (canEdit) removeSpace(spaceItem.roomId);
      },
    );
  }

  Future<void> removeSpace(String spaceId) async {
    final allowedRooms =
        await ref.read(joinRulesAllowedRoomsProvider(widget.roomId).future);
    final newList = allowedRooms.where((id) => id != spaceId).toList();
    final visibility =
        newList.isEmpty ? RoomVisibility.Private : RoomVisibility.SpaceVisible;
    await updateSpaceVisibility(visibility, spaceIds: newList);
  }

  Future<void> selectSpace(String roomId) async {
    try {
      final spaceId = await selectSpaceDrawer(context: context);
      if (spaceId != null) {
        final spaceList =
            await ref.read(joinRulesAllowedRoomsProvider(roomId).future);
        final isAlreadyAdded = spaceList.any((roomId) => roomId == spaceId);
        if (!isAlreadyAdded) {
          spaceList.add(spaceId);
          await updateSpaceVisibility(
            RoomVisibility.SpaceVisible,
            spaceIds: spaceList,
          );
        }
      }
    } catch (e, s) {
      _log.severe('Failed to select space', e, s);
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
      EasyLoading.show(
        status: 'Updating space settings',
        dismissOnTap: false,
      );
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
          break;
      }

      await room.setJoinRule(update);
      EasyLoading.dismiss();
    } catch (e, s) {
      _log.severe('Failed to change room visibility', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).updatingVisibilityFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
