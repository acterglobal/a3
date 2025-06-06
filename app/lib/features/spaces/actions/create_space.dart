import 'dart:io';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/chat/actions/create_chat.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/room/model/room_join_rule.dart';
import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter/features/space/providers/suggested_provider.dart';
import 'package:acter/features/spaces/model/space_feature_state.dart';
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

    final permissionsBuilder = sdk.api.newAppPermissionsBuilder();
    final featureStates = ref.read(featureActivationStateProvider);
    try {
      applyPermissions(permissionsBuilder, featureStates);
    } catch (e, s) {
      _log.severe('Failed to apply features settings', e, s);
      EasyLoading.showError(
        lang.creatingSpaceFailed(e),
        duration: const Duration(seconds: 3),
      );
      return null;
    }

    ref.invalidate(featureActivationStateProvider);
    config.setPermissions(permissionsBuilder);

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

void applyPermissions(
  AppPermissionsBuilder builder,
  Map<SpaceFeature, FeatureActivationState> featureStates,
) {
  for (final entry in featureStates.entries) {
    final feature = entry.key;
    final state = entry.value;
    final isActivated = state.isActivated;

    // Set feature activation

    final _ = switch (feature) {
      SpaceFeature.boosts => builder.news(isActivated),
      SpaceFeature.stories => builder.stories(isActivated),
      SpaceFeature.pins => builder.pins(isActivated),
      SpaceFeature.events => builder.calendarEvents(isActivated),
      SpaceFeature.tasks => builder.tasks(isActivated),
    };

    // Set permissions for activated features
    if (isActivated) {
      for (final permission in state.permissions) {
        final permissionKey = permission.key;
        final permissionLevel = permission.permissionLevel.value;

        final _ = switch (permissionKey) {
          PermissionType.boostPost => builder.newsPermissions(permissionLevel),
          PermissionType.storyPost => builder.storiesPermissions(
            permissionLevel,
          ),
          PermissionType.pinPost => builder.pinsPermissions(permissionLevel),
          PermissionType.eventPost => builder.calendarEventsPermissions(
            permissionLevel,
          ),
          PermissionType.taskListPost => builder.taskListsPermissions(
            permissionLevel,
          ),
          PermissionType.taskItemPost => builder.tasksPermissions(
            permissionLevel,
          ),
          PermissionType.eventRsvp => builder.rsvpPermissions(permissionLevel),
          PermissionType.commentPost => builder.commentsPermissions(
            permissionLevel,
          ),
          PermissionType.attachmentPost => builder.attachmentsPermissions(
            permissionLevel,
          ),
        };
      }
    }
  }
}
