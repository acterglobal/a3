import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/base_body_widget.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/member_list.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter/features/chat/widgets/skeletons/action_item_skeleton_widget.dart';
import 'package:acter/features/chat/widgets/skeletons/members_list_skeleton_widget.dart';
import 'package:acter/features/room/widgets/notifications_settings_tile.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::room_profile_page');

class RoomProfilePage extends ConsumerStatefulWidget {
  final String roomId;

  const RoomProfilePage({
    required this.roomId,
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
    final inSideBar = ref.watch(inSideBarProvider);
    final isExpanded = ref.watch(hasExpandedPanel);

    return AppBar(
      automaticallyImplyLeading: false,
      leading: Visibility(
        visible: inSideBar && isExpanded,
        replacement: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        child: IconButton(
          onPressed: () =>
              ref.read(hasExpandedPanel.notifier).update((state) => false),
          icon: const Icon(Atlas.xmark_circle_thin),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0.0,
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            _header(context),
            const SizedBox(height: 16),
            _description(context),
            const SizedBox(height: 16),
            _actions(context),
            const SizedBox(height: 20),
            _optionsBody(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
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
        convoProfile.when(
          data: (profile) => Text(
            profile.displayName ?? widget.roomId,
            softWrap: true,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
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

  Widget _description(BuildContext context) {
    final convo = ref.watch(chatProvider(widget.roomId));

    return convo.when(
      data: (data) => RenderHtml(
        text: data.topic() ?? '',
        defaultTextStyle: Theme.of(context).textTheme.bodySmall,
      ),
      loading: () => const Skeletonizer(child: Text('loading...')),
      error: (e, s) => Text('Error: $e'),
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
              actionName: 'Bookmark',
              onTap: () async {
                await conv.setFavorite(!isFav);
              },
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
          loading: () => const ActionItemSkeleton(
            iconData: Icons.bookmark_add_outlined,
            actionName: 'Bookmark',
          ),
        ),

        // Invite
        myMembership.when(
          data: (membership) {
            return _actionItem(
              context: context,
              iconData: Atlas.user_plus_thin,
              actionName: 'Invite',
              onTap: () {
                membership!.canString('CanInvite')
                    ? context.pushNamed(
                        Routes.spaceInvite.name,
                        pathParameters: {'spaceId': widget.roomId},
                      )
                    : customMsgSnackbar(
                        context,
                        'Not enough power level for invites, ask room administrator to change it',
                      );
              },
            );
          },
          error: (e, st) => Text('Error loading tile due to $e'),
          loading: () => const ActionItemSkeleton(
            iconData: Atlas.user_plus_thin,
            actionName: 'Invite',
          ),
        ),

        // Share
        _actionItem(
          context: context,
          iconData: Icons.ios_share,
          actionName: 'Share',
          onTap: () async {
            final roomLink =
                await (await ref.read(chatProvider(widget.roomId).future))
                    .permalink();
            Share.share(
              roomLink,
              subject: 'Room ID',
            );
          },
        ),

        // Leave room
        _actionItem(
          context: context,
          iconData: Icons.exit_to_app,
          actionName: 'Leave',
          actionItemColor: Theme.of(context).colorScheme.error,
          onTap: () => showLeaveRoomDialog(context: context),
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
    final members = ref.watch(chatMembersProvider(widget.roomId));

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Members (${list.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              );
            },
            loading: () => const Skeletonizer(
              child: Text(
                'Members (0)',
              ),
            ),
            error: (error, stackTrace) =>
                Text('Error loading members count $error'),
          ),
          convo.when(
            data: (data) => MemberList(convo: data),
            loading: () => const MembersListSkeleton(),
            error: (e, s) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Future<void> showLeaveRoomDialog({
    required BuildContext context,
  }) async {
    showAdaptiveDialog(
      context: context,
      builder: (ctx) => DefaultDialog(
        title: Text(
          'Leave Room',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(
          'Are you sure you want to leave room? This action cannot be undone',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              EasyLoading.show(status: 'Leaving Room');
              var res = await _handleLeaveRoom(ref, widget.roomId);
              if (res) {
                if (context.mounted) {
                  EasyLoading.dismiss();
                  context.goNamed(Routes.chat.name);
                }
              } else {
                EasyLoading.dismiss();
                EasyLoading.showError(
                  'Some error occurred leaving room',
                );
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<bool> _handleLeaveRoom(WidgetRef ref, String roomId) async {
    final convo = await ref.read(chatProvider(roomId).future);
    return await convo.leave();
  }
}
