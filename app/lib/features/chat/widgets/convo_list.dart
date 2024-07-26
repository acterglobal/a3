import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/providers/room_list_filter_provider.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ConvosList extends ConsumerStatefulWidget {
  final Function(String)? onSelected;

  const ConvosList({this.onSelected, super.key});

  @override
  ConsumerState<ConvosList> createState() => _ConvosListConsumerState();
}

class _ConvosListConsumerState extends ConsumerState<ConvosList> {
  @override
  Widget build(BuildContext context) {
    final hasSearchFilter = ref.watch(hasRoomFilters);
    if (hasSearchFilter) {
      return ref.watch(filteredChatsProvider).when(
            data: (chats) {
              if (chats.isEmpty) {
                return Center(
                  heightFactor: 10,
                  child: Text(L10n.of(context).noChatsFoundMatchingYourFilter),
                );
              }
              return renderList(
                context,
                chats.map((e) => e.getRoomIdStr()).toList(),
              );
            },
            loading: () => const Center(
              heightFactor: 10,
              child: CircularProgressIndicator(),
            ),
            error: (e, s) => Center(
              heightFactor: 10,
              child: Text(
                '${L10n.of(context).searchingFailed}: $e',
              ),
            ),
            skipLoadingOnReload: true,
          );
    }
    final chats = ref.watch(chatIdsProvider);

    if (chats.isEmpty) {
      final hasFirstSynced =
          ref.watch(syncStateProvider.select((x) => !x.initialSync));
      if (!hasFirstSynced) {
        return Center(
          heightFactor: 1.5,
          child: EmptyState(
            title: L10n.of(context).noChatsStillSyncing,
            subtitle: L10n.of(context).noChatsStillSyncingSubtitle,
            image: 'assets/images/empty_chat.svg',
          ),
        );
      }
      return Center(
        heightFactor: 1.5,
        child: EmptyState(
          title: L10n.of(context).youHaveNoDMsAtTheMoment,
          subtitle: L10n.of(context).getInTouchWithOtherChangeMakers,
          image: 'assets/images/empty_chat.svg',
          primaryButton: ActerPrimaryActionButton(
            onPressed: () async => context.pushNamed(
              Routes.createChat.name,
            ),
            child: Text(L10n.of(context).sendDM),
          ),
        ),
      );
    }
    return renderList(context, chats);
  }

  Widget renderList(BuildContext context, List<String> chats) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: chats.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final roomId = chats[index];
        return ConvoCard(
          key: Key('convo-card-$roomId'),
          roomId: roomId,
          onTap: () =>
              widget.onSelected != null ? widget.onSelected!(roomId) : null,
        );
      },
    );
  }
}
