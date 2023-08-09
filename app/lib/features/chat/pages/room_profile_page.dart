import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/spaces/space_parent_badge.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/member_list.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RoomProfilePage extends ConsumerWidget {
  const RoomProfilePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(currentConvoProvider)!;
    final members =
        ref.watch(chatMembersProvider(room.getRoomIdStr())).requireValue;
    final myMembership =
        ref.watch(spaceMembershipProvider(room.getRoomIdStr()));
    final List<Widget> topMenu = [
      Text(
        'Members (${members.length})',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ];
    if (myMembership.hasValue) {
      final membership = myMembership.value!;
      if (membership.canString('CanInvite')) {
        topMenu.add(
          IconButton(
            icon: Icon(
              Atlas.plus_circle_thin,
              color: Theme.of(context).colorScheme.neutral5,
            ),
            iconSize: 28,
            color: Theme.of(context).colorScheme.surface,
            onPressed: () => context.pushNamed(
              Routes.spaceInvite.name,
              pathParameters: {'spaceId': room.getRoomIdStr()},
            ),
          ),
        );
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            elevation: 0.0,
            actions: <Widget>[
              PopupMenuButton<int>(
                icon: const Icon(Atlas.dots_vertical, size: 22),
                itemBuilder: (context) => [
                  PopupMenuItem<int>(
                    onTap: () => _handleLeaveRoom(context),
                    value: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Leave Room'),
                        const SizedBox(width: 50),
                        Icon(
                          Icons.exit_to_app_outlined,
                          color: Theme.of(context).colorScheme.errorContainer,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, child) {
                final convoProfile = ref.watch(chatProfileDataProvider(room));
                final roomId = room.getRoomIdStr();
                return convoProfile.when(
                  data: (profile) => Column(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 38,
                            bottom: 12,
                          ),
                          child: SpaceParentBadge(
                            badgeSize: 20,
                            spaceId: room.getRoomIdStr(),
                            child: ActerAvatar(
                              mode: DisplayMode.GroupChat,
                              uniqueId: roomId,
                              displayName: profile.displayName ?? roomId,
                              avatar: profile.getAvatarImage(),
                              size: 75,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        profile.displayName ?? roomId,
                        overflow: TextOverflow.clip,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, st) => Text('Some error occured ${e.toString()}'),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(8.0),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: Text(
                  room.topic() ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                  softWrap: true,
                  textAlign: TextAlign.center,
                ),
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
          const MemberList(),
        ],
      ),
    );
  }

  void _handleLeaveRoom(BuildContext context) {
    popUpDialog(context: context, title: Text('Are you sure?'));
  }
}
