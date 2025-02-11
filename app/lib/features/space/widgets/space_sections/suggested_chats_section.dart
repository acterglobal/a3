import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/widgets/related/chats_helpers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SuggestedChatsSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const SuggestedChatsSection({
    super.key,
    required this.spaceId,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedChats =
        ref.watch(suggestedChatsProvider(spaceId)).valueOrNull;

    if (suggestedChats == null ||
        (suggestedChats.$1.isEmpty && suggestedChats.$2.isEmpty)) {
      return SizedBox.shrink();
    }

    return buildSuggestedChatsSectionUI(
      context,
      ref,
      suggestedChats.$1,
      suggestedChats.$2,
    );
  }

  Widget buildSuggestedChatsSectionUI(
    BuildContext context,
    WidgetRef ref,
    List<String> suggestedLocalChats,
    List<SpaceHierarchyRoomInfo> suggestedRemoteChats,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).suggestedChats,
          isShowSeeAllButton: true,
          onTapSeeAll: () => context.pushNamed(
            Routes.subChats.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        localChatsListUI(ref, spaceId, suggestedLocalChats),
        remoteChatsListUI(ref, spaceId, suggestedRemoteChats),
      ],
    );
  }
}
