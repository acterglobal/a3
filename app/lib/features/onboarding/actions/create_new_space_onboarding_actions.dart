import 'dart:io';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/spaces/actions/create_space.dart';
import 'package:acter/features/spaces/providers/space_creation_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<String?> createOnboardingSpace(BuildContext context, WidgetRef ref, String name, File? spaceAvatar) async {
    final createDefaultChat = ref.read(createDefaultChatProvider);
    final parentRoomId = ref.read(selectedSpaceIdProvider);
    final roomJoinRule = ref.read(selectedJoinRuleProvider);

    ref.invalidate(createDefaultChatProvider);
    ref.invalidate(selectedSpaceIdProvider);
    ref.invalidate(selectedJoinRuleProvider);

    final spaceId = await createSpace(
      context,
      ref,
      name: name,
      spaceAvatar: spaceAvatar,
      createDefaultChat: createDefaultChat,
      parentRoomId: parentRoomId,
      roomJoinRule: roomJoinRule,
    );

    return spaceId;
}