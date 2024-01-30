import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        heightFactor: 1.5,
        child: EmptyState(
          title: 'You have no DMs at the moment',
          subtitle:
              'Get in touch with other change makers, organizers or activists and chat directly with them.',
          image: 'assets/images/empty_chat.svg',
          primaryButton: ElevatedButton(
            onPressed: () async => context.pushNamed(
              Routes.createChat.name,
            ),
            child: const Text('Send DM'),
          ),
        ),
      );
    }
    return renderList(context, chats);
  }

  Widget renderList(BuildContext context, List<Convo> chats) {
    return ListView.builder(
      itemCount: chats.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final roomId = chats[index].getRoomIdStr();
        return ConvoCard(
          key: Key('convo-card-$roomId'),
          room: chats[index],
          onTap: () =>
              widget.onSelected != null ? widget.onSelected!(roomId) : null,
        );
      },
    );
  }
}
