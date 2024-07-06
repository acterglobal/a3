import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
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
    final chatsList = ref.watch(relatedChatsProvider(spaceId));
    return chatsList.when(
      data: (events) => buildChatsSectionUI(context, events),
      error: (error, stack) =>
          Center(child: Text(L10n.of(context).loadingFailed(error))),
      loading: () => Skeletonizer(
        child: Center(
          child: Text(L10n.of(context).loading),
        ),
      ),
    );
  }

  Widget buildChatsSectionUI(BuildContext context, List<Convo> chats) {
    int chatsLimit = (chats.length > limit) ? limit : chats.length;
    bool isShowSeeAllButton = chats.length > chatsLimit;
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
}
