import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/providers/room_list_filter_provider.dart';
import 'package:acter/common/toolkit/widgets/animated_chats_list_widget.dart';
import 'package:acter/features/chat_ng/rooms_list/widgets/chat_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat_ng::chats_list');

class ChatsListNG extends ConsumerWidget {
  final Function(String)? onSelected;

  const ChatsListNG({super.key, this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(hasRoomFilters)) {
      return _renderFiltered(context, ref);
    }
    final chats = ref.watch(chatIdsProvider);

    if (chats.isEmpty) {
      if (!ref.watch(hasFirstSyncedProvider)) {
        return _renderSyncing(context);
      }
      return _renderEmpty(context);
    }
    return _renderList(context, chats);
  }

  Widget _renderFiltered(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final filteredChats = ref.watch(filteredChatsProvider);
    return filteredChats.when(
      data: (chatsIds) {
        if (chatsIds.isEmpty) {
          return Center(
            heightFactor: 10,
            child: Text(lang.noChatsFoundMatchingYourFilter),
          );
        }
        return _renderList(context, chatsIds);
      },
      loading:
          () => Center(heightFactor: 10, child: CircularProgressIndicator()),
      error: (e, s) {
        _log.severe('Failed to filter convos', e, s);
        return Center(heightFactor: 10, child: Text(lang.searchingFailed(e)));
      },
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );
  }

  Widget _renderSyncing(BuildContext context) {
    final lang = L10n.of(context);
    return Center(
      heightFactor: 1.5,
      child: EmptyState(
        title: lang.noChatsStillSyncing,
        subtitle: lang.noChatsStillSyncingSubtitle,
        image: 'assets/images/empty_chat.svg',
      ),
    );
  }

  Widget _renderEmpty(BuildContext context) {
    final lang = L10n.of(context);
    return Center(
      heightFactor: 1.5,
      child: EmptyState(
        title: lang.youHaveNoDMsAtTheMoment,
        subtitle: lang.getInTouchWithOtherChangeMakers,
        image: 'assets/images/empty_chat.svg',
        primaryButton: ActerPrimaryActionButton(
          onPressed: () => context.pushNamed(Routes.createChat.name),
          child: Text(lang.sendDM),
        ),
      ),
    );
  }

  Widget _renderList(BuildContext context, List<String> chats) {
    return ActerAnimatedListWidget(
      entries: chats,
      itemBuilder:
          ({required Animation<double> animation, required String roomId}) =>
              ChatItemWidget(
                animation: animation,
                key: Key('chat-room-card-$roomId'),
                roomId: roomId,
                onTap: () => onSelected?.call(roomId),
              ),
    );
  }
}
