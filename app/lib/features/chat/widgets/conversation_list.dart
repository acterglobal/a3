import 'dart:ui';

import 'package:acter/features/chat/models/joined_room/joined_room.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/conversation_card.dart';
import 'package:acter/features/chat/widgets/invitations_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';

class ConversationsList extends ConsumerWidget {
  const ConversationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatList = ref.watch(chatListProvider);
    final joinedRooms = ref.watch(roomListProvider);
    return !chatList.initialLoaded
        ? Center(
            heightFactor: 10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  AppLocalizations.of(context)!.loadingConvo + '...',
                ),
                const SizedBox(height: 10),
                const CircularProgressIndicator(),
              ],
            ),
          )
        : ImplicitlyAnimatedReorderableList<JoinedRoom>(
            header: const InvitationsList(),
            items: chatList.showSearch ? chatList.searchData : joinedRooms,
            areItemsTheSame: (a, b) => a.id == b.id,
            // Remember to update the underlying data when the list has been reordered.
            onReorderFinished: (item, from, to, newItems) =>
                ref.read(chatListProvider.notifier).moveItem(from, to),
            itemBuilder: (context, itemAnimation, item, index) {
              return Reorderable(
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
              );
            },
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
                    child: ConversationCard(room: item),
                  ),
                );
              },
            ),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
          );
  }
}
