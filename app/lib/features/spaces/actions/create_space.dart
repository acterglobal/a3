import 'dart:io';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/chat/actions/create_chat.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/room/model/room_join_rule.dart';
import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:acter/features/spaces/providers/space_creation_providers.dart';
import 'package:acter/features/spaces/model/permission_config.dart';

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
  RoomJoinRule? roomJoinRule,
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
    if (roomJoinRule != null) {
      config.joinRule(roomJoinRule.name);
    }
    final permissionsBuilder = await generatePermissionsBuilder(ref, lang);
    if (permissionsBuilder != null) {
      config.setPermissions(permissionsBuilder);
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

    if (!context.mounted) return null;
    EasyLoading.dismiss();
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

Future<AppPermissionsBuilder?> generatePermissionsBuilder(
  WidgetRef ref,
  L10n lang,
) async {
  try {
    final sdk = await ref.read(sdkProvider.future);
    final permissionsBuilder = sdk.api.newAppPermissionsBuilder();
    final featureStates = ref.read(featureActivationStateProvider);

    for (final entry in featureStates.entries) {
      final feature = entry.key;
      final state = entry.value;

      // Set feature activation
      setFeatureActivation(permissionsBuilder, feature, state.isActivated);

      // Set permissions for each feature
      setFeaturePermissions(permissionsBuilder, feature, state.permissions);
    }

    return permissionsBuilder;
  } catch (e, s) {
    _log.severe('Failed to apply features settings', e, s);
    EasyLoading.showError(
      lang.creatingSpaceFailed(e),
      duration: const Duration(seconds: 3),
    );
    return null;
  }
}

void setFeatureActivation(
  AppPermissionsBuilder builder,
  SpaceFeature feature,
  bool isActivated,
) {
  switch (feature) {
    case SpaceFeature.boosts:
      builder.news(isActivated);
      break;
    case SpaceFeature.stories:
      builder.stories(isActivated);
      break;
    case SpaceFeature.pins:
      builder.pins(isActivated);
      break;
    case SpaceFeature.events:
      builder.calendarEvents(isActivated);
      break;
    case SpaceFeature.tasks:
      builder.tasks(isActivated);
      break;
  }
}

void setFeaturePermissions(
  AppPermissionsBuilder builder,
  SpaceFeature feature,
  List<PermissionConfig> permissions,
) {
  for (final permission in permissions) {
    switch (feature) {
      case SpaceFeature.boosts:
        switch (permission.key) {
          case 'boost-post':
            builder.newsPermisisons(permission.permissionLevel.value);
            break;
        }
        break;
      case SpaceFeature.stories:
        switch (permission.key) {
          case 'story-post':
            builder.storiesPermisisons(permission.permissionLevel.value);
            break;
        }
        break;
      case SpaceFeature.pins:
        switch (permission.key) {
          case 'pin-post':
            builder.pinsPermisisons(permission.permissionLevel.value);
            break;
        }
        break;
      case SpaceFeature.events:
        switch (permission.key) {
          case 'event-post':
            builder.calendarEventsPermisisons(permission.permissionLevel.value);
            break;
          case 'event-rsvp':
            builder.rsvpPermisisons(permission.permissionLevel.value);
            break;
        }
        break;
      case SpaceFeature.tasks:
        switch (permission.key) {
          case 'task-list-post':
            builder.taskListsPermisisons(permission.permissionLevel.value);
            break;
          case 'task-item-post':
            builder.tasksPermisisons(permission.permissionLevel.value);
            break;
        }
        break;
    }
  }
}
