import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/widgets/related/chats_helpers.dart';
import 'package:acter/features/space/widgets/related/util.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::space::sections::chats');

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
    final lang = L10n.of(context);
    final suggestedChats =
        ref.watch(suggestedChatsProvider(spaceId)).valueOrNull;
    if (suggestedChats != null &&
        (suggestedChats.$1.isNotEmpty || suggestedChats.$2.isNotEmpty)) {
      return buildSuggestedChatsSectionUI(
        context,
        ref,
        suggestedChats.$1,
        suggestedChats.$2,
      );
    }
    final overviewLoader = ref.watch(spaceRelationsOverviewProvider(spaceId));
    return overviewLoader.when(
      data: (overview) => buildChatsSectionUI(
        context,
        ref,
        overview.knownChats,
      ),
      error: (e, s) {
        _log.severe('Failed to load the related spaces', e, s);
        return Center(
          child: Text(lang.loadingSpacesFailed(e)),
        );
      },
      loading: () => Skeletonizer(
        child: Center(
          child: Text(lang.loading),
        ),
      ),
    );
  }

  Widget buildSuggestedChatsSectionUI(
    BuildContext context,
    WidgetRef ref,
    List<String> suggestedLocalChats,
    List<SpaceHierarchyRoomInfo> suggestedRemoteChats,
  ) {
    final config = calculateSectionConfig(
      localListLen: suggestedLocalChats.length,
      limit: limit,
      remoteListLen: suggestedRemoteChats.length,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).chats,
          isShowSeeAllButton: true,
          onTapSeeAll: () => context.pushNamed(
            Routes.subChats.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        chatsListUI(
          ref,
          spaceId,
          suggestedLocalChats,
          config.listingLimit,
          showOptions: false,
          showSuggestedMarkIfGiven: false,
        ),
        if (config.renderRemote)
          renderRemoteChats(
            context,
            ref,
            spaceId,
            suggestedRemoteChats,
            config.remoteCount,
            showSuggestedMarkIfGiven: false,
            renderMenu: false,
          ),
      ],
    );
  }

  Widget buildChatsSectionUI(
    BuildContext context,
    WidgetRef ref,
    List<String> chats,
  ) {
    final relatedChats =
        ref.watch(remoteChatRelationsProvider(spaceId)).valueOrNull ?? [];
    final config = calculateSectionConfig(
      localListLen: chats.length,
      limit: limit,
      remoteListLen: relatedChats.length,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).chats,
          isShowSeeAllButton: config.isShowSeeAllButton,
          onTapSeeAll: () => context.pushNamed(
            Routes.subChats.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        chatsListUI(
          ref,
          spaceId,
          chats,
          config.listingLimit,
          showOptions: false,
        ),
        if (config.renderRemote)
          renderFurther(context, ref, spaceId, config.remoteCount),
      ],
    );
  }
}
