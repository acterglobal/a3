import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_animated_list/auto_animated_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ConvosList extends ConsumerWidget {
  final Function(String)? onSelected;
  const ConvosList({this.onSelected, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchValue = ref.watch(chatSearchValueProvider);
    if (searchValue != null && searchValue.isNotEmpty) {
      return ref.watch(searchedChatsProvider).when(
            data: (chats) {
              if (chats.isEmpty) {
                return const Center(
                  heightFactor: 10,
                  child: Text('No chats found matching your search term'),
                );
              }
              return renderList(context, chats);
            },
            loading: () => Center(
              heightFactor: 10,
              child: Text(
                '${AppLocalizations.of(context)!.loadingConvo}...',
              ),
            ),
            error: (e, s) => Center(
              heightFactor: 10,
              child: Text(
                'Searching failed: $e',
              ),
            ),
          );
    }

    final chats = ref.watch(chatsProvider);

    if (chats.isEmpty) {
      return Center(
        heightFactor: 10,
        child: Text(
          '${AppLocalizations.of(context)!.loadingConvo}...',
        ),
      );
    }
    return renderList(context, chats);
  }

  Widget renderList(BuildContext context, List<Convo> chats) {
    return AutoAnimatedList<Convo>(
      items: chats,
      itemBuilder: (context, item, index, animation) => SizeFadeTransition(
        sizeFraction: 0.7,
        animation: animation,
        child: ConvoCard(
          room: item,
          onTap: () =>
              onSelected != null ? onSelected!(item.getRoomIdStr()) : null,
        ),
      ),
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
    );
  }
}
