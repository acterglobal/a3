import 'dart:ui';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ConvosList extends ConsumerWidget {
  const ConvosList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    late List<Convo> chats;
    final searchValue = ref.watch(chatSearchValueProvider);
    if (searchValue != null && searchValue.isNotEmpty) {
      chats = ref.watch(chatsSearchProvider);

      if (chats.isEmpty) {
        return const Center(
          heightFactor: 10,
          child: Text('No chats found matching your search term'),
        );
      }
    } else {
      chats = ref.watch(chatsProvider);

      if (chats.isEmpty) {
        return Center(
          heightFactor: 10,
          child: Text(
            '${AppLocalizations.of(context)!.loadingConvo}...',
          ),
        );
      }
    }

    return ImplicitlyAnimatedReorderableList<Convo>(
      items: chats,
      areItemsTheSame: (a, b) => a.getRoomIdStr() == b.getRoomIdStr(),
      // Remember to update the underlying data when the list has been reordered.
      onReorderFinished: (item, from, to, newItems) => {},
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
                child: ConvoCard(room: item),
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
            child: ConvoCard(room: item),
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
              child: ConvoCard(room: item),
            ),
          );
        },
      ),
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
    );
  }
}
