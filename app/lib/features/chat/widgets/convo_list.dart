import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ConvosList extends ConsumerStatefulWidget {
  final Function(String)? onSelected;
  const ConvosList({this.onSelected, super.key});

  @override
  ConsumerState<ConvosList> createState() => _ConvosListConsumerState();
}

class _ConvosListConsumerState extends ConsumerState<ConvosList> {
  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(chatsProvider);
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
            loading: () => const Center(
              heightFactor: 10,
              child: CircularProgressIndicator(),
            ),
            error: (e, s) => Center(
              heightFactor: 10,
              child: Text(
                'Searching failed: $e',
              ),
            ),
          );
    }

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
    return AnimatedList(
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: chats.length,
      shrinkWrap: true,
      itemBuilder: (context, index, animation) => SizeTransition(
        sizeFactor: animation,
        child: ConvoCard(
          room: chats[index],
          onTap: () => widget.onSelected != null
              ? widget.onSelected!(chats[index].getRoomIdStr())
              : null,
        ),
      ),
    );
  }
}
