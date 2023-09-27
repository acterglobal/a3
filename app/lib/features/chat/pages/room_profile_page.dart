import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/spaces/space_parent_badge.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/member_list.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RoomProfilePage extends ConsumerWidget {
  final String roomId;
  const RoomProfilePage({
    required this.roomId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convo = ref.watch(chatProvider(roomId));
    final convoProfile = ref.watch(chatProfileDataProviderById(roomId));
    final members = ref.watch(chatMembersProvider(roomId));
    final myMembership = ref.watch(roomMembershipProvider(roomId));
    final location = ref.watch(currentRoutingLocation);
    final List<Widget> topMenu = [
      members.when(
        data: (list) {
          return Text(
            'Members (${list.length})',
            style: Theme.of(context).textTheme.titleSmall,
          );
        },
        error: (error, stackTrace) =>
            Text('Error loading members count $error'),
        loading: () => const CircularProgressIndicator(),
      ),
    ];
    if (myMembership.hasValue) {
      final membership = myMembership.value!;
      if (membership.canString('CanInvite')) {
        topMenu.add(
          IconButton(
            padding: const EdgeInsets.only(bottom: 8),
            icon: Icon(
              Atlas.plus_circle_thin,
              color: Theme.of(context).colorScheme.neutral5,
            ),
            iconSize: 24,
            color: Theme.of(context).colorScheme.surface,
            onPressed: () => context.pushNamed(
              Routes.chatInvite.name,
              pathParameters: {'roomId': roomId},
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.neutral,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              leading: Visibility(
                visible: location == Routes.chat.route,
                replacement: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.chevron_left),
                ),
                child: IconButton(
                  onPressed: () => ref
                      .read(showFullSplitView.notifier)
                      .update((state) => false),
                  icon: const Icon(Atlas.xmark_circle_thin),
                ),
              ),
              elevation: 0.0,
              actions: <Widget>[
                PopupMenuButton<int>(
                  icon: const Icon(Atlas.dots_vertical, size: 22),
                  color: Colors.transparent,
                  itemBuilder: (context) => [
                    PopupMenuItem<int>(
                      value: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Leave Room'),
                          const SizedBox(width: 50),
                          Icon(
                            Icons.exit_to_app_outlined,
                            color: Theme.of(context).colorScheme.errorContainer,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
                            mode: DisplayMode.GroupChat,
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
              padding: const EdgeInsets.all(8.0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        roomId,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).colorScheme.neutral5,
                            ),
                        softWrap: true,
                      ),
                    ),
                    IconButton(
                      iconSize: 14,
                      icon: Icon(
                        Atlas.pages_thin,
                        color: Theme.of(context).colorScheme.neutral5,
                      ),
                      onPressed: () async {
                        Clipboard.setData(
                          ClipboardData(
                            text: roomId,
                          ),
                        );
                        customMsgSnackbar(
                          context,
                          'Room ID copied to clipboard',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: SliverToBoxAdapter(
                child: convo.when(
                  data: (data) => Center(
                    child: Text(
                      data.topic() ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  loading: () => const Text('loading...'),
                  error: (e, s) => Text('Error: $e'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: topMenu,
                ),
              ),
            ),
            convo.when(
              data: (data) => MemberList(convo: data),
              loading: () => const Text('loading...'),
              error: (e, s) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
