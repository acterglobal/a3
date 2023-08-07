import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/spaces/space_parent_badge.dart';
import 'package:acter/features/chat/pages/group_link_page.dart';
import 'package:acter/features/chat/pages/link_settings_page.dart';
import 'package:acter/features/chat/pages/requests_page.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/invite_list_view.dart';
import 'package:acter/features/chat/widgets/member_list.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
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
                    value: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Leave Group'),
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
}

class _RequestsAndInvitesWidget extends StatelessWidget {
  final Client client;
  final Convo room;

  const _RequestsAndInvitesWidget({
    Key? key,
    required this.client,
    required this.room,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onClick(context),
      child: const Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Atlas.user_plus, color: Colors.white),
          ),
          Text(
            'Requests & Invites',
            style: TextStyle(color: Colors.white),
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              '3',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  void onClick(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext ctx) => RequestsPage(
          client: client,
          room: room,
        ),
      ),
    );
  }
}

class _GroupLinkSwitch extends StatelessWidget {
  const _GroupLinkSwitch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onClick(context),
      child: const Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Atlas.link, color: Colors.white),
          ),
          Text(
            'Chat Link',
            style: TextStyle(color: Colors.white),
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              'On',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void onClick(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (BuildContext ctx) => const GroupLinkView()),
    );
  }
}

class _CreateRoomInviteButton extends StatelessWidget {
  final Convo room;

  const _CreateRoomInviteButton({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onClick(context),
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(bottom: 12, left: 16),
        child: const Text(
          'Create Chat Invite',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  void onClick(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return DraggableScrollableSheet(
            expand: false,
            builder: (BuildContext context, ScrollController scrollController) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Invite a Friend to this chat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        width: double.infinity,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Atlas.magnifying_glass,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            hintText: 'Search for friends',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Your invite link expires in 24 hours.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () => onEditLink(context),
                            child: const Text(
                              'Edit invite link',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: 10,
                        itemBuilder: (context, index) => const Padding(
                          padding: EdgeInsets.all(12),
                          child: InviteListView(
                            isAdded: false,
                            name: 'Abhishek',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void onEditLink(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext ctx) => LinkSettingsPage(room: room),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Atlas.group_team, color: Colors.white),
                ),
                Text(
                  'Group in common',
                  style: TextStyle(color: Colors.white),
                ),
                Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    '3',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 2),
            ),
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Atlas.link, color: Colors.white),
                ),
                Text(
                  'Share Username',
                  style: TextStyle(color: Colors.white),
                ),
                Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text('@marthacraig'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
