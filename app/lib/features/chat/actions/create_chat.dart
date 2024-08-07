import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  EasyLoading.show(status: L10n.of(context).creatingChat);
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
    final client = ref.read(alwaysClientProvider);
    final roomIdStr = (await client.createConvo(config.build())).toString();
    // add room to child of space (if given)
    if (parentId != null) {
      final space = await ref.read(spaceProvider(parentId).future);
      await space.addChildRoom(roomIdStr, suggested);
      // spaceRelations come from the server and must be manually invalidated
      ref.invalidate(spaceRelationsProvider(parentId));
      ref.invalidate(spaceRemoteRelationsProvider(parentId));
    }
    return roomIdStr;
  } catch (e) {
    if (context.mounted) {
      EasyLoading.showError(
        L10n.of(context).errorCreatingChat(e),
        duration: const Duration(seconds: 3),
      );
    }
    return null;
  }
}
