import 'dart:io';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/chat/actions/create_chat.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/room/model/room_visibility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::spaces::actions::create_space');

/// Create a new space as the current client
///
///
Future<String?> createSpace(
  BuildContext context,
  WidgetRef ref, {
  /// The name of the new new space
  required String name,

  /// Set the starting topic
  String? description,
  File? spaceAvatar,
  String? parentRoomId,
  RoomVisibility? roomVisibility,
  bool createDefaultChat = false,
}) async {
  final lang = L10n.of(context);
  EasyLoading.show(status: lang.creatingSpace);
  try {
    final sdk = await ref.read(sdkProvider.future);
    final config = sdk.api.newSpaceSettingsBuilder();
    config.setName(name);
    if (description != null && description.isNotEmpty) {
      config.setTopic(description.trim());
    }
    if (spaceAvatar != null && spaceAvatar.path.isNotEmpty) {
      // space creation will upload it
      config.setAvatarUri(spaceAvatar.path);
    }
    if (parentRoomId != null) {
      config.setParent(parentRoomId);
    }
    if (roomVisibility != null) {
      config.setVisibility(roomVisibility.name);
    }
    final client = await ref.read(alwaysClientProvider.future);
    final result = await client.createActerSpace(config.build());
    final roomId = result.toString();
    if (parentRoomId != null) {
      final space = await ref.read(spaceProvider(parentRoomId).future);
      await space.addChildRoom(roomId, false);
      // spaceRelations come from the server and must be manually invalidated
      ref.invalidate(spaceRelationsProvider(parentRoomId));
      ref.invalidate(spaceRemoteRelationsProvider(parentRoomId));
    }
    EasyLoading.dismiss();

    if (createDefaultChat) {
      if (!context.mounted) return null;
      final chatId = await createChat(
        context,
        ref,
        name: lang.defaultChatName(name),
        parentId: roomId,
        suggested: true,
      );
      if (chatId != null) {
        // close the UI if the chat successfully created
        EasyLoading.dismiss();
      }
    }
    return roomId;
  } catch (e, s) {
    _log.severe('Failed to create space', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return null;
    }
    EasyLoading.showError(
      lang.creatingSpaceFailed(e),
      duration: const Duration(seconds: 3),
    );
    return null;
  }
}
