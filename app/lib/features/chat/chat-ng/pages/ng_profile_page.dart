import 'package:acter/common/actions/close_room.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/edit_plain_description_sheet.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/common/widgets/visibility/visibility_chip.dart';
import 'package:acter/features/chat/widgets/member_list.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter/features/chat/widgets/skeletons/action_item_skeleton_widget.dart';
import 'package:acter/features/room/widgets/notifications_settings_tile.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat::room_profile');

class ChatNGProfilePage extends ConsumerStatefulWidget {
  final String roomId;

  const ChatNGProfilePage({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ChatNGProfilePageState();
}

class _ChatNGProfilePageState extends ConsumerState<ChatNGProfilePage> {
  @override
  Widget build(BuildContext context) {
    final roomAvatarInfo = ref.watch(roomAvatarInfoProvider(widget.roomId));
    final membership =
        ref.watch(roomMembershipProvider(widget.roomId)).valueOrNull;
    final convo = ref.watch(chatProvider(widget.roomId)).valueOrNull;
    final isDirectChat =
        ref.watch(isDirectChatProvider(widget.roomId)).valueOrNull ?? false;

    return Column(
      children: [
        _buildAppBar(context, roomAvatarInfo, membership, convo, isDirectChat),
        Expanded(
          child: _buildBody(
            context,
            roomAvatarInfo,
            membership,
            convo,
            isDirectChat,
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    AvatarInfo roomAvatarInfo,
    Member? membership,
    Convo? convo,
    bool isDirectChat,
  ) {
    List<PopupMenuItem> menuListItems = [];
    if (membership?.canString('CanSetName') == true) {
      menuListItems.add(
        PopupMenuItem(
          onTap: () => showEditNameBottomSheet(roomAvatarInfo),
          child: Text(L10n.of(context).editName),
        ),
      );
    }
    if (membership?.canString('CanSetTopic') == true) {
      menuListItems.add(
        PopupMenuItem(
          onTap: () => showEditDescriptionBottomSheet(
            context: context,
            convo: convo,
            descriptionValue: convo?.topic() ?? '',
          ),
          child: Text(L10n.of(context).editDescription),
        ),
      );

      if (!isDirectChat &&
          convo != null &&
          membership?.canString('CanKick') == true &&
          membership?.canString('CanUpdateJoinRule') == true) {
        menuListItems.add(
          PopupMenuItem(
            onTap: () => openCloseRoomDialog(
              context: context,
              roomId: convo.getRoomIdStr(),
            ),
            child: Text(
              L10n.of(context).closeChat,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        );
      }
    }

    return AppBar(
      // custom x-circle when we are in widescreen mode;
      automaticallyImplyLeading: !context.isLargeScreen,
      leading: context.isLargeScreen
          ? IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Atlas.xmark_circle_thin),
            )
          : null,
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      actions: [
        if (menuListItems.isNotEmpty)
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => menuListItems,
          ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    AvatarInfo roomAvatarInfo,
    Member? membership,
    Convo? convo,
    bool isDirectChat,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            _header(
              context,
              roomAvatarInfo,
              membership,
              convo,
              isDirectChat,
            ),
            _description(context, membership, convo),
            _actions(
              context,
              convo,
              isDirectChat,
            ),
            const SizedBox(height: 20),
            _optionsBody(
              context,
              convo,
              isDirectChat,
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    AvatarInfo roomAvatarInfo,
    Member? membership,
    Convo? convo,
    bool isDirectChat,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            if (!isDirectChat) openAvatar(context, ref, widget.roomId);
          },
          child: RoomAvatar(
            roomId: widget.roomId,
            avatarSize: 75,
            showParents: true,
          ),
        ),
        const SizedBox(height: 10),
        SelectionArea(
          child: GestureDetector(
            onTap: () {
              if (membership?.canString('CanSetName') == true) {
                showEditNameBottomSheet(roomAvatarInfo);
              }
            },
            child: Text(
              roomAvatarInfo.displayName ?? widget.roomId,
              softWrap: true,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ],
    );
  }

  void showEditNameBottomSheet(AvatarInfo roomAvatarInfo) {
    showEditTitleBottomSheet(
      context: context,
      bottomSheetTitle: L10n.of(context).editName,
      titleValue: roomAvatarInfo.displayName ?? '',
      onSave: (newName) => _saveName(newName),
    );
  }

  Future<void> _saveName(String newName) async {
    try {
      EasyLoading.show(status: L10n.of(context).updateName);
      final convo = await ref.read(chatProvider(widget.roomId).future);
      if (convo == null) {
        throw RoomNotFound();
      }
      await convo.setName(newName.trim());
      EasyLoading.dismiss();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e, s) {
      _log.severe('Failed to edit chat name', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).updateNameFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _description(BuildContext context, Member? membership, Convo? convo) {
    String topic = convo?.topic() ?? '';
    return SelectionArea(
      child: GestureDetector(
        onTap: () {
          if (membership?.canString('CanSetTopic') == true) {
            showEditDescriptionBottomSheet(
              context: context,
              convo: convo,
              descriptionValue: convo?.topic() ?? '',
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.only(
            bottom: topic.isEmpty ? 0 : 16,
            left: 16,
            right: 16,
          ),
          child: Text(
            topic,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, Convo? convo, bool isDirectChat) {
    final membershipLoader = ref.watch(roomMembershipProvider(widget.roomId));
    final isBookmarked =
        ref.watch(isConvoBookmarked(widget.roomId)).valueOrNull ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bookmark
        _actionItem(
          context: context,
          iconData: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          actionName: L10n.of(context).bookmark,
          onTap: () async {
            (await ref.read(chatProvider(widget.roomId).future))
                ?.setBookmarked(!isBookmarked);
          },
        ),

        // Invite
        membershipLoader.when(
          data: (membership) {
            if (membership == null || isDirectChat) return const SizedBox();
            return _actionItem(
              context: context,
              iconData: Atlas.user_plus_thin,
              actionName: L10n.of(context).invite,
              actionItemColor: membership.canString('CanInvite')
                  ? null
                  : Theme.of(context).colorScheme.onSurface,
              onTap: () => _handleInvite(membership),
            );
          },
          error: (e, s) {
            _log.severe('Failed to load room membership', e, s);
            return Text(L10n.of(context).errorLoadingTileDueTo(e));
          },
          loading: () => ActionItemSkeleton(
            iconData: Atlas.user_plus_thin,
            actionName: L10n.of(context).invite,
          ),
        ),

        // Share
        _actionItem(
          context: context,
          iconData: Icons.ios_share,
          actionName: L10n.of(context).share,
          onTap: _handleShare,
        ),

        // Leave room
        _actionItem(
          context: context,
          iconData: Icons.exit_to_app,
          actionName: L10n.of(context).leave,
          actionItemColor: Theme.of(context).colorScheme.error,
          onTap: showLeaveRoomDialog,
        ),
      ],
    );
  }

  Widget _actionItem({
    required BuildContext context,
    required IconData iconData,
    required String actionName,
    Color? actionItemColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Icon(
                iconData,
                color: actionItemColor,
              ),
              const SizedBox(height: 10),
              Text(
                actionName,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge!
                    .copyWith(color: actionItemColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionsBody(BuildContext context, Convo? convo, bool isDirectChat) {
    return Column(
      children: [
        // Notification section
        Card(
          margin: EdgeInsets.zero,
          child: SettingsList(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            darkTheme: SettingsThemeData(
              settingsListBackground: Colors.transparent,
              dividerColor: Colors.transparent,
              settingsSectionBackground: Colors.transparent,
              leadingIconsColor: Theme.of(context).colorScheme.onSurface,
            ),
            sections: [
              SettingsSection(
                tiles: [
                  NotificationsSettingsTile(roomId: widget.roomId),
                ],
              ),
              SettingsSection(
                tiles: [
                  SettingsTile(
                    title: Text(L10n.of(context).accessAndVisibility),
                    description: VisibilityChip(roomId: widget.roomId),
                    leading: const Icon(Atlas.lab_appliance_thin),
                    onPressed: (context) => context.pushNamed(
                      Routes.chatNGSettingsVisibility.name,
                      pathParameters: {'roomId': widget.roomId},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Room members list section
        if (!isDirectChat) _convoMembersList(),
      ],
    );
  }

  Widget _convoMembersList() {
    final membersLoader = ref.watch(membersIdsProvider(widget.roomId));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          membersLoader.when(
            data: (members) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Text(
                L10n.of(context).membersCount(members.length),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            loading: () => Skeletonizer(
              child: Text(L10n.of(context).membersCount(0)),
            ),
            error: (e, s) {
              _log.severe('Failed to load room members', e, s);
              return Text(L10n.of(context).errorLoadingMembersCount(e));
            },
          ),
          MemberList(roomId: widget.roomId),
        ],
      ),
    );
  }

  Future<void> showLeaveRoomDialog() async {
    showAdaptiveDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => DefaultDialog(
        title: Text(
          L10n.of(context).leaveRoom,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(
          L10n.of(context).areYouSureYouWantToLeaveRoom,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.of(context).no),
          ),
          ActerPrimaryActionButton(
            onPressed: _handleLeaveRoom,
            child: Text(L10n.of(context).yes),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLeaveRoom() async {
    Navigator.pop(context);
    EasyLoading.show(status: L10n.of(context).leavingRoom);
    try {
      final parentIds = await ref.read(parentIdsProvider(widget.roomId).future);
      final convo = await ref.read(chatProvider(widget.roomId).future);
      if (convo == null) {
        throw RoomNotFound();
      }
      final res = await convo.leave();
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }

      for (final parentId in parentIds) {
        ref.invalidate(spaceRelationsProvider(parentId));
        ref.invalidate(spaceRemoteRelationsProvider(parentId));
      }
      if (res) {
        EasyLoading.dismiss();
        context.goNamed(Routes.chat.name);
      } else {
        _log.severe('Failed to leave room');
        EasyLoading.showError(
          L10n.of(context).someErrorOccurredLeavingRoom,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e, s) {
      _log.severe('Couldn’t leave room', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToLeaveRoom(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _handleInvite(Member membership) {
    if (membership.canString('CanInvite')) {
      context.pushNamed(
        Routes.chatInvite.name,
        pathParameters: {'roomId': widget.roomId},
      );
    } else {
      EasyLoading.showError(
        L10n.of(context).notEnoughPowerLevelForInvites,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _handleShare() async {
    EasyLoading.show(status: L10n.of(context).sharingRoom);
    try {
      final convo = await ref.read(chatProvider(widget.roomId).future);
      if (convo == null) {
        throw RoomNotFound();
      }
      final roomLink = await convo.permalink();
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      Share.share(
        roomLink,
        subject: L10n.of(context).linkToChat,
      );
      EasyLoading.showToast(L10n.of(context).sharedSuccessfully);
    } catch (e, s) {
      _log.severe('Couldn’t share this room', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToShareRoom(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  void showEditDescriptionBottomSheet({
    required BuildContext context,
    required Convo? convo,
    required String descriptionValue,
  }) {
    showEditPlainDescriptionBottomSheet(
      context: context,
      descriptionValue: descriptionValue,
      onSave: (newDescription) async {
        try {
          EasyLoading.show(status: L10n.of(context).updateDescription);
          await convo?.setTopic(newDescription);
          EasyLoading.dismiss();
          if (!context.mounted) return;
          Navigator.pop(context);
        } catch (e, s) {
          _log.severe('Failed to change description', e, s);
          if (!context.mounted) {
            EasyLoading.dismiss();
            return;
          }
          EasyLoading.showError(
            L10n.of(context).updateDescriptionFailed(e),
            duration: const Duration(seconds: 3),
          );
        }
      },
    );
  }
}
