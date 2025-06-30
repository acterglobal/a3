import 'dart:math';

import 'package:acter/features/space/providers/suggested_provider.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/features/space/widgets/related/chats_helpers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OtherChatsSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const OtherChatsSection({super.key, required this.spaceId, this.limit = 3});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherChats = ref.watch(otherChatsProvider(spaceId)).valueOrNull;

    if (otherChats == null ||
        (otherChats.$1.isEmpty && otherChats.$2.isEmpty)) {
      return SizedBox.shrink();
    }

    return buildOtherChatsSectionUI(context, ref, otherChats.$1, otherChats.$2);
  }

  Widget buildOtherChatsSectionUI(
    BuildContext context,
    WidgetRef ref,
    List<String> otherLocalChats,
    List<SpaceHierarchyRoomInfo> otherRemoteChats,
  ) {
    final localChatCount = min(limit, otherLocalChats.length);
    final remoteChatCount = min(
      (limit - localChatCount),
      otherRemoteChats.length,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).chats,
          isShowSeeAllButton: true,
          onTapSeeAll:
              () => context.pushNamed(
                Routes.subChats.name,
                pathParameters: {'spaceId': spaceId},
              ),
        ),
        localChatsListUI(ref, spaceId, otherLocalChats, limit: localChatCount),
        remoteChatsListUI(
          ref,
          spaceId,
          otherRemoteChats,
          limit: remoteChatCount,
        ),
      ],
    );
  }
}
