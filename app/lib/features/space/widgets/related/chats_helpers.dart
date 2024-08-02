import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/common/widgets/chat/convo_hierarchy_card.dart';
import 'package:acter/router/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::space::related::chats_helpers');

Widget chatsListUI(WidgetRef ref, List<String> chats, int chatsLimit) {
  return ListView.builder(
    shrinkWrap: true,
    itemCount: chatsLimit,
    padding: EdgeInsets.zero,
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (context, index) {
      final roomId = chats[index];
      return ConvoCard(
        roomId: roomId,
        showParents: false,
        showSelectedIndication: false,
        onTap: () => goToChat(context, roomId),
      );
    },
  );
}

Widget renderFurther(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
  int? maxItems,
) {
  final remoteChats = ref.watch(remoteChatRelationsProvider(spaceId));

  return remoteChats.when(
    data: (chats) {
      if (chats.isEmpty) {
        return const SizedBox.shrink();
      }

      return ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: maxItems ?? chats.length,
        itemBuilder: (context, idx) {
          final item = chats[idx];
          return ConvoHierarchyCard(
            showIconIfSuggested: true,
            parentId: spaceId,
            roomInfo: item,
          );
        },
      );
    },
    error: (e, s) {
      _log.severe('Fetching of remote chat relations failed', e, s);
      return Card(
        child: Text(L10n.of(context).errorLoadingRelatedChats(e)),
      );
    },
    loading: () => Skeletonizer(
      child: Card(
        child: Text(L10n.of(context).loadingOtherChats),
      ),
    ),
  );
}
