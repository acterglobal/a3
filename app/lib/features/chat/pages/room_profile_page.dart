import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/base_body_widget.dart';
import 'package:acter/common/widgets/chat/edit_room_description_sheet.dart';
import 'package:acter/common/widgets/chat/edit_room_name_sheet.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/chat/widgets/member_list.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter/features/chat/widgets/skeletons/action_item_skeleton_widget.dart';
import 'package:acter/features/chat/widgets/skeletons/members_list_skeleton_widget.dart';
import 'package:acter/features/room/widgets/notifications_settings_tile.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat::room_profile_page');

class RoomProfilePage extends ConsumerStatefulWidget {
  final String roomId;
  final bool inSidebar;

  const RoomProfilePage({
    required this.roomId,
    required this.inSidebar,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RoomProfilePageState();
}

class _RoomProfilePageState extends ConsumerState<RoomProfilePage> {
  @override
  Widget build(BuildContext context) {
    return BaseBody(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildAppBar(context),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      // custom x-circle when we are in widescreen mode;
      leading: widget.inSidebar
          ? IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Atlas.xmark_circle_thin),
            )
          : null,
      backgroundColor: Colors.transparent,
      elevation: 0.0,
    );
  }

  Widget _buildBody(BuildContext context) {
    final membership =
        ref.watch(roomMembershipProvider(widget.roomId)).valueOrNull;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            _header(context, membership),
            const SizedBox(height: 16),
            _description(context, membership),
            const SizedBox(height: 16),
            _actions(context),
            const SizedBox(height: 20),
            _optionsBody(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Member? membership) {
    final convoProfile = ref.watch(chatProfileDataProviderById(widget.roomId));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RoomAvatar(
          roomId: widget.roomId,
          avatarSize: 75,
          showParent: true,
        ),
        const SizedBox(height: 10),
        if (membership?.canString('CanUpdateAvatar') == true)
          ActerInlineTextButton(
            onPressed: () => _updateAvatar(),
            child: Text(L10n.of(context).changeAvatar),
          ),
        convoProfile.when(
          data: (profile) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.displayName ?? widget.roomId,
                softWrap: true,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (membership?.canString('CanSetName') == true)
                IconButton(
                  onPressed: () => showEditRoomNameBottomSheet(
                    context: context,
                    name: profile.displayName ?? '',
                    roomId: widget.roomId,
                  ),
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.neutral5,
                  ),
                ),
            ],
          ),
          error: (err, stackTrace) {
            _log.severe('Error loading convo profile', err, stackTrace);
            return Text(
              widget.roomId,
              overflow: TextOverflow.clip,
              style: Theme.of(context).textTheme.titleSmall,
            );
          },
          loading: () => Skeletonizer(child: Text(widget.roomId)),
        ),
      ],
    );
  }

  Future<void> _updateAvatar() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: L10n.of(context).uploadAvatar,
      type: FileType.image,
    );
    if (result == null || result.files.isEmpty) return;
    try {
      if (!mounted) return;
      EasyLoading.show(status: L10n.of(context).uploadAvatar);
      final convo = await ref.read(chatProvider(widget.roomId).future);
      final file = result.files.first;
      if (file.path != null) await convo.uploadAvatar(file.path!);
      // close loading
      EasyLoading.dismiss();
    } catch (e, st) {
      _log.severe('Failed to edit chat', e, st);
      EasyLoading.dismiss();
    }
  }

  Widget _description(BuildContext context, Member? membership) {
    final convo = ref.watch(chatProvider(widget.roomId));

    return convo.when(
      data: (data) => Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: RenderHtml(
              text: data.topic() ?? '',
              defaultTextStyle: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (membership?.canString('CanSetTopic') == true)
            addDescriptionButton(data),
        ],
      ),
      loading: () => Skeletonizer(
        child: Text(L10n.of(context).loading),
      ),
      error: (e, s) => Text(L10n.of(context).error(e)),
    );
  }

  Widget addDescriptionButton(data) {
    return (data.topic() == null || data.topic().toString().isEmpty)
        ? ActerInlineTextButton(
            onPressed: () => showEditRoomDescriptionBottomSheet(
              context: context,
              description: data.topic() ?? '',
              roomId: widget.roomId,
            ),
            child: Text(L10n.of(context).addDescription),
          )
        : IconButton(
            onPressed: () => showEditRoomDescriptionBottomSheet(
              context: context,
              description: data.topic() ?? '',
              roomId: widget.roomId,
            ),
            icon: Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.neutral5,
            ),
          );
  }

  Widget _actions(BuildContext context) {
    final convoLoader = ref.watch(chatProvider(widget.roomId));
    final myMembership = ref.watch(roomMembershipProvider(widget.roomId));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bookmark
        convoLoader.when(
          data: (conv) {
            final isFav = conv.isFavorite();
            return _actionItem(
              context: context,
              iconData: isFav ? Icons.bookmark : Icons.bookmark_border,
              actionName: L10n.of(context).bookmark,
              onTap: () async => await conv.setFavorite(!isFav),
            );
          },
          error: (e, st) => Skeletonizer(
            child: IconButton.filled(
              icon: const Icon(
                Icons.bookmark_add_outlined,
                size: 20,
              ),
              onPressed: () {},
            ),
          ),
          loading: () => ActionItemSkeleton(
            iconData: Icons.bookmark_add_outlined,
            actionName: L10n.of(context).bookmark,
          ),
        ),

        // Invite
        myMembership.when(
          data: (membership) {
            if (membership == null) return const SizedBox();
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
          error: (e, st) => Text(L10n.of(context).errorLoadingTileDueTo(e)),
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
          color: Theme.of(context).colorScheme.background,
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

  Widget _optionsBody(BuildContext context) {
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
              leadingIconsColor: Theme.of(context).colorScheme.neutral6,
            ),
            sections: [
              SettingsSection(
                tiles: [
                  NotificationsSettingsTile(roomId: widget.roomId),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Room members list section
        _convoMembersList(),
      ],
    );
  }

  Widget _convoMembersList() {
    final convo = ref.watch(chatProvider(widget.roomId));
    final members = ref.watch(membersIdsProvider(widget.roomId));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          members.when(
            data: (list) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  L10n.of(context).membersCount(list.length),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              );
            },
            loading: () => Skeletonizer(
              child: Text(L10n.of(context).membersCount(0)),
            ),
            error: (error, stackTrace) =>
                Text(L10n.of(context).errorLoadingMembersCount(error)),
          ),
          convo.when(
            data: (data) => MemberList(convo: data),
            loading: () => const MembersListSkeleton(),
            error: (e, s) => Text('${L10n.of(context).error}: $e'),
          ),
        ],
      ),
    );
  }

  Future<void> showLeaveRoomDialog() async {
    showAdaptiveDialog(
      context: context,
      builder: (ctx) => DefaultDialog(
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
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
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
    Navigator.of(context, rootNavigator: true).pop();
    EasyLoading.show(status: L10n.of(context).leavingRoom);
    try {
      final convo = await ref.read(chatProvider(widget.roomId).future);
      final res = await convo.leave();
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      if (res) {
        EasyLoading.dismiss();
        context.goNamed(Routes.chat.name);
      } else {
        EasyLoading.showError(
          L10n.of(context).someErrorOccurredLeavingRoom,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e, st) {
      _log.severe("Couldn't leave room", e, st);
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
        Routes.spaceInvite.name,
        pathParameters: {'spaceId': widget.roomId},
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
    } catch (e, st) {
      _log.severe("Couldn't share this room", e, st);
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
}
