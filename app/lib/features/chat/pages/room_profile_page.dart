import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/common/widgets/spaces/space_parent_badge.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/member_list.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';

class RoomProfilePage extends ConsumerWidget {
  final String roomId;
  const RoomProfilePage({
    required this.roomId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inSideBar = ref.watch(inSideBarProvider);
    final isExpanded = ref.watch(hasExpandedPanel);
    final convo = ref.watch(chatProvider(roomId));
    final convoProfile = ref.watch(chatProfileDataProviderById(roomId));
    final members = ref.watch(chatMembersProvider(roomId));
    final myMembership = ref.watch(roomMembershipProvider(roomId));
    final tileTextTheme = Theme.of(context).textTheme.bodySmall;
    final Widget topMenu = members.when(
      data: (list) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Members (${list.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        );
      },
      error: (error, stackTrace) => Text('Error loading members count $error'),
      loading: () => const CircularProgressIndicator(),
    );

    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.onSecondary.withOpacity(0.5),
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        shrinkWrap: true,
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            leading: Visibility(
              visible: inSideBar && isExpanded,
              replacement: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.chevron_left_outlined),
              ),
              child: IconButton(
                onPressed: () => ref
                    .read(hasExpandedPanel.notifier)
                    .update((state) => false),
                icon: const Icon(Atlas.xmark_circle_thin),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0.0,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 38,
                      bottom: 12,
                    ),
                    child: SpaceParentBadge(
                      badgeSize: 20,
                      roomId: roomId,
                      child: convoProfile.when(
                        data: (profile) => ActerAvatar(
                          mode: profile.isDm
                              ? DisplayMode.User
                              : DisplayMode.Space,
                          uniqueId: roomId,
                          displayName: profile.displayName ?? roomId,
                          avatar: profile.getAvatarImage(),
                          size: 75,
                        ),
                        error: (err, stackTrace) {
                          debugPrint('Some error occured $err');
                          return ActerAvatar(
                            mode: DisplayMode.GroupChat,
                            uniqueId: roomId,
                            displayName: roomId,
                            size: 75,
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
                convoProfile.when(
                  data: (profile) => Text(
                    profile.displayName ?? roomId,
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  error: (err, stackTrace) {
                    debugPrint('Some error occured $err');
                    return Text(
                      roomId,
                      overflow: TextOverflow.clip,
                      style: Theme.of(context).textTheme.titleSmall,
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: convo.when(
              data: (data) => SliverToBoxAdapter(
                child: RenderHtml(
                  text: data.topic() ?? '',
                  defaultTextStyle: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              loading: () => const Text('loading...'),
              error: (e, s) => Text('Error: $e'),
            ),
          ),
          SliverToBoxAdapter(
            child: SettingsList(
              physics: const NeverScrollableScrollPhysics(),
              darkTheme: SettingsThemeData(
                settingsListBackground: Colors.transparent,
                settingsSectionBackground:
                    Theme.of(context).colorScheme.onPrimary,
                dividerColor: Colors.transparent,
                leadingIconsColor: Theme.of(context).colorScheme.neutral6,
              ),
              shrinkWrap: true,
              sections: [
                SettingsSection(
                  tiles: [
                    myMembership.when(
                      data: (membership) => SettingsTile.navigation(
                        onPressed: (ctx) {
                          membership!.canString('CanInvite')
                              ? ctx.pushNamed(
                                  Routes.spaceInvite.name,
                                  pathParameters: {'spaceId': roomId},
                                )
                              : customMsgSnackbar(
                                  ctx,
                                  'Not enough power level for invites, ask room administrator to change it',
                                );
                        },
                        title: Text(
                          'Request and Invites',
                          style: tileTextTheme,
                        ),
                        leading: const Icon(Atlas.user_plus_thin, size: 18),
                        trailing: const Icon(
                          Icons.chevron_right_outlined,
                          size: 18,
                        ),
                      ),
                      error: (e, st) => SettingsTile(
                        title: Text('Error loading tile due to $e'),
                      ),
                      loading: () => SettingsTile(
                        title: const Text('Loading'),
                      ),
                    ),
                    SettingsTile(
                      onPressed: (ctx) {
                        Clipboard.setData(
                          ClipboardData(
                            text: roomId,
                          ),
                        );
                        customMsgSnackbar(
                          context,
                          'Room ID: $roomId copied to clipboard',
                        );
                      },
                      title: Text(
                        'Copy Room Link',
                        style: tileTextTheme,
                      ),
                      leading: const Icon(Atlas.chain_link_thin, size: 18),
                      trailing: Icon(
                        Atlas.pages_thin,
                        size: 18,
                        color: Theme.of(context).colorScheme.success,
                      ),
                    ),
                  ],
                ),
                SettingsSection(
                  tiles: [
                    SettingsTile(
                      onPressed: (ctx) async {
                        await showAdaptiveDialog(
                          barrierDismissible: true,
                          context: ctx,
                          builder: (ctx) => DefaultDialog(
                            height: MediaQuery.of(context).size.height * 0.5,
                            title: topMenu,
                            description: convo.when(
                              data: (data) => MemberList(convo: data),
                              loading: () => const Text('loading...'),
                              error: (e, s) => Text('Error: $e'),
                            ),
                          ),
                        );
                      },
                      title: Text(
                        'Members',
                        style: tileTextTheme,
                      ),
                      leading: const Icon(
                        Atlas.accounts_group_people_thin,
                        size: 18,
                      ),
                      trailing:
                          const Icon(Icons.chevron_right_outlined, size: 18),
                    ),
                  ],
                ),
                SettingsSection(
                  title: Text(
                    'Danger Zone',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(context).colorScheme.badgeUrgent,
                        ),
                  ),
                  tiles: [
                    SettingsTile(
                      title: Text(
                        'Leave Room',
                        style: tileTextTheme!.copyWith(
                          color: Theme.of(context).colorScheme.badgeUrgent,
                        ),
                      ),
                      leading: Icon(
                        Atlas.trash_thin,
                        size: 18,
                        color: Theme.of(context).colorScheme.badgeUrgent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
