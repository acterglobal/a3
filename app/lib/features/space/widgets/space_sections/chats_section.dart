import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/common/widgets/chat/convo_hierarchy_card.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ChatsSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const ChatsSection({
    super.key,
    required this.spaceId,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsList = ref.watch(spaceRelationsOverviewProvider(spaceId));
    return chatsList.when(
      data: (spaceRelationsOverview) => buildChatsSectionUI(
        context,
        ref,
        spaceRelationsOverview.knownChats,
        spaceRelationsOverview.hasMoreChats,
      ),
      error: (error, stack) =>
          Center(child: Text(L10n.of(context).loadingFailed(error))),
      loading: () => Skeletonizer(
        child: Center(
          child: Text(L10n.of(context).loading),
        ),
      ),
    );
  }

  Widget buildChatsSectionUI(
    BuildContext context,
    WidgetRef ref,
    List<Convo> chats,
    bool hasMore,
  ) {
    int chatsLimit = (chats.length > limit) ? limit : chats.length;
    int moreCount = limit > chats.length ? limit - chats.length : 0;
    bool isShowSeeAllButton = (chats.length > chatsLimit) || hasMore;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).chats,
          isShowSeeAllButton: isShowSeeAllButton,
          onTapSeeAll: () => context.pushNamed(
            Routes.spaceChats.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        chatsListUI(chats, chatsLimit),
        if (moreCount > 0 && hasMore) renderFurther(context, ref, moreCount),
      ],
    );
  }

  Widget chatsListUI(List<Convo> chats, int chatsLimit) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: chatsLimit,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return ConvoCard(
          room: chats[index],
          showParents: false,
          showSelectedIndication: false,
          onTap: () => goToChat(context, chats[index].getRoomIdStr()),
        );
      },
    );
  }

  Widget renderFurther(BuildContext context, WidgetRef ref, int maxItems) {
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
          itemCount: maxItems,
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
      error: (e, s) =>
          Card(child: Text(L10n.of(context).errorLoadingRelatedChats(e))),
      loading: () => Skeletonizer(
        child: Card(child: Text(L10n.of(context).loadingOtherChats)),
      ),
    );
  }
}
