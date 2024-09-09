import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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
  EasyLoading.show(status: L10n.of(context).creatingChat);
  try {
    final sdk = await ref.read(sdkProvider.future);

    final config = sdk.api.newConvoSettingsBuilder();
    // add the users
    selectedUsers.map((p0) {
      for (final userId in p0) {
        config.addInvitee(userId);
      }
    });
    // set the name
    name.map((p0) {
      if (p0.isNotEmpty) config.setName(p0);
    });
    // and an optional description
    description.map((p0) {
      if (p0.isNotEmpty) config.setTopic(p0);
    });
    avatarUri.map((p0) {
      // convo creation will upload it
      if (p0.isNotEmpty) config.setAvatarUri(p0);
    });
    parentId.map((p0) => config.setParent(p0));

    final client = ref.read(alwaysClientProvider);
    final settings = config.build();
    final roomIdStr = (await client.createConvo(settings)).toString();
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
      L10n.of(context).errorCreatingChat(e),
      duration: const Duration(seconds: 3),
    );
    return null;
  }
}
