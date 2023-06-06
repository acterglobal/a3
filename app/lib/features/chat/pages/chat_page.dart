import 'dart:ui';

import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/controllers/chat_list_controller.dart';
import 'package:acter/features/chat/widgets/conversation_card.dart';
import 'package:acter/features/chat/widgets/invitation_card.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/chat/models/joined_room.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProvider)!;
    final chatList = ref.watch(chatListProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            pinned: false,
            snap: false,
            floating: true,
            flexibleSpace: chatList.showSearch
                ? Padding(
                    padding: const EdgeInsets.only(
                      top: 5,
                      bottom: 6,
                      left: 10,
                      right: 5,
                    ),
                    child: TextField(
                      onChanged: (value) =>
                          ref.read(chatListProvider.notifier).searchRoom(value),
                      cursorColor: Theme.of(context).colorScheme.tertiary2,
                      decoration: InputDecoration(
                        hintStyle: const TextStyle(
                          color: Colors.white,
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () => ref
                              .read(chatListProvider.notifier)
                              .toggleSearchView(),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                        contentPadding: const EdgeInsets.only(
                          left: 12,
                          bottom: 2,
                          top: 2,
                        ),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text(
                      AppLocalizations.of(context)!.chat,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
            actions: chatList.showSearch
                ? []
                : [
                    IconButton(
                      onPressed: () => ref
                          .read(chatListProvider.notifier)
                          .toggleSearchView(),
                      padding: const EdgeInsets.only(right: 10, left: 5),
                      icon: const Icon(
                        Atlas.magnifying_glass,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        customMsgSnackbar(
                          context,
                          'Multiselect is not implemented yet',
                        );
                      },
                      padding: const EdgeInsets.only(right: 10, left: 5),
                      icon: const Icon(
                        Atlas.menu_square,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        customMsgSnackbar(
                          context,
                          'Starting a new chat is not implemented yet',
                        );
                      },
                      padding: const EdgeInsets.only(right: 10, left: 10),
                      icon: const Icon(
                        Atlas.plus_circle_thin,
                      ),
                    ),
                  ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (client.isGuest()) empty else const ConversationsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SvgPicture get empty {
    return SvgPicture.asset('assets/images/empty_messages.svg');
  }
}

class ConversationsList extends ConsumerWidget {
  const ConversationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatList = ref.watch(chatListProvider);
    if (!chatList.initialLoaded) {
      return Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Text(
            AppLocalizations.of(context)!.loadingConvo,
          ),
        ),
      );
    }
    return ImplicitlyAnimatedReorderableList<JoinedRoom>(
      header: const InvitationsList(),
      items: chatList.showSearch ? chatList.searchData : chatList.joinedRooms,
      areItemsTheSame: (a, b) =>
          a.conversation.getRoomId() == b.conversation.getRoomId(),
      // Remember to update the underlying data when the list has been reordered.
      onReorderFinished: (item, from, to, newItems) =>
          ref.read(chatListProvider.notifier).moveItem(from, to),
      itemBuilder: (context, itemAnimation, item, index) => Reorderable(
        key: ValueKey(item),
        builder: (context, dragAnimation, inDrag) {
          final t = dragAnimation.value;
          final elevation = lerpDouble(0, 8, t);
          final color = Color.lerp(
            Colors.white,
            Colors.white.withOpacity(0.8),
            t,
          );
          return SizeFadeTransition(
            sizeFraction: 0.7,
            curve: Curves.easeInOut,
            animation: itemAnimation,
            child: Material(
              color: color,
              elevation: elevation ?? 0.0,
              type: MaterialType.transparency,
              child: ConversationCard(room: item),
            ),
          );
        },
      ),
      removeItemBuilder: (context, animation, item) => Reorderable(
        key: ValueKey(item),
        builder: (context, animation, inDrag) {
          return FadeTransition(
            opacity: animation,
            child: ConversationCard(room: item),
          );
        },
      ),
      updateItemBuilder: (context, itemAnimation, item) => Reorderable(
        key: ValueKey(item),
        builder: (context, dragAnimation, inDrag) {
          final t = dragAnimation.value;
          final elevation = lerpDouble(0, 8, t);
          final color =
              Color.lerp(Colors.white, Colors.white.withOpacity(0.8), t);
          return SizeFadeTransition(
            sizeFraction: 0.7,
            curve: Curves.easeInOut,
            animation: itemAnimation,
            child: Material(
              color: color,
              elevation: elevation ?? 0.0,
              type: MaterialType.transparency,
              child: ConversationCard(
                key: Key(item.conversation.getRoomId().toString()),
                room: item,
              ),
            ),
          );
        },
      ),
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
    );
  }
}

class InvitationsList extends ConsumerWidget {
  const InvitationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatList = ref.watch(chatListProvider);
    if (chatList.invitations.isEmpty) {
      return const SizedBox();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.only(left: 18),
          child: Text(
            AppLocalizations.of(context)!.invitedRooms,
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: chatList.invitations.length,
          itemBuilder: (BuildContext context, int index) {
            return InvitationCard(
              invitation: chatList.invitations[index],
              avatarColor: Colors.white,
            );
          },
        ),
        Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.only(left: 18, top: 10),
          child: Text(
            AppLocalizations.of(context)!.joinedRooms,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
