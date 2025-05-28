import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/space/providers/suggested_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::actions::create_chat');

/// Create Room Method
Future<String?> createChat(
  BuildContext context,
  WidgetRef ref, {
  String? name,
  String? description,
  String? avatarUri,
  String? parentId,
  List<String>? selectedUsers,
  bool suggested = false,
}) async {
  final lang = L10n.of(context);
  EasyLoading.show(status: lang.creatingChat);
  try {
    final sdk = await ref.read(sdkProvider.future);
    final config = sdk.api.newConvoSettingsBuilder();
    if (selectedUsers != null) {
      // add the users
      for (final userId in selectedUsers) {
        config.addInvitee(userId);
      }
    }

    if (name != null && name.isNotEmpty) {
      // set the name
      config.setName(name);
    }

    if (description != null && description.isNotEmpty) {
      // and an optional description
      config.setTopic(description);
    }

    if (avatarUri != null && avatarUri.isNotEmpty) {
      config.setAvatarUri(avatarUri); // convo creation will upload it
    }

    if (parentId != null) {
      config.setParent(parentId);
    }
    final client = await ref.read(alwaysClientProvider.future);
    final roomId = await client.createConvo(config.build());
    final roomIdStr = roomId.toString();
    // add room to child of space (if given)
    if (parentId != null) {
      final space = await ref.read(spaceProvider(parentId).future);
      await space.addChildRoom(roomIdStr, suggested);
      // spaceRelations come from the server and must be manually invalidated
      ref.invalidate(spaceRelationsProvider(parentId));
      ref.invalidate(spaceRemoteRelationsProvider(parentId));
    }
    EasyLoading.dismiss();
    return roomIdStr;
  } catch (e, s) {
    _log.severe('Failed to create chat', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return null;
    }
    EasyLoading.showError(
      lang.errorCreatingChat(e),
      duration: const Duration(seconds: 3),
    );
    return null;
  }
}
