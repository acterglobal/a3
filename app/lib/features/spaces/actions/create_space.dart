import 'dart:io';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/chat/actions/create_chat.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/room/model/room_join_rule.dart';
import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter/features/space/settings/pages/apps_settings_page.dart';
import 'package:acter/features/spaces/model/permission_config.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:acter/features/spaces/providers/space_creation_providers.dart';

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

    EasyLoading.show(status: lang.applyingFeatureSettings);
    // Add a delay to ensure that space creation is completed
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!context.mounted) return null;
    await applySpaceFeatures(context, ref, roomId);
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

Future<void> applySpaceFeatures(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
) async {
  final lang = L10n.of(context);
  try {
    final featureStates = ref.read(featureActivationStateProvider);
    ref.invalidate(featureActivationStateProvider);
    final appSettingsAndMembership = await ref.read(
      spaceAppSettingsProvider(spaceId).future,
    );
    final space = appSettingsAndMembership.space;
    final appSettings = appSettingsAndMembership.settings;
    final powerLevels = appSettingsAndMembership.powerLevels;

    if (context.mounted) {
      for (final entry in featureStates.entries) {
        final feature = entry.key;
        final state = entry.value;

        if (state.isActivated) {
          //Activate the feature
          final builder = appSettings.setActivatedBuilder(feature, true);
          await space.updateAppSettings(builder);

          //Set the power level based on the permission level
          await setPowerLevel(space, powerLevels, state.permissions);

          // Add a delay between each update to ensure they complete in sequence
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
  } catch (e, s) {
    _log.severe('Failed to apply features settings', e, s);
    EasyLoading.showError(
      lang.creatingSpaceFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}

Future<void> setPowerLevel(
  Space space,
  RoomPowerLevels powerLevels,
  List<PermissionConfig> permissions,
) async {
  for (final permissionEntry in permissions) {
    PowerLevelKeyAndValue? powerLevelKeyAndValue = getPowerLevelKeyAndValue(
      powerLevels,
      permissionEntry,
    );
    if (powerLevelKeyAndValue != null) {
      await space.updateFeaturePowerLevels(
        powerLevelKeyAndValue.key,
        powerLevelKeyAndValue.value,
      );
      // Add a delay between each update to ensure they complete in sequence
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}

class PowerLevelKeyAndValue {
  final String key;
  final int value;

  const PowerLevelKeyAndValue({required this.key, required this.value});
}

PowerLevelKeyAndValue? getPowerLevelKeyAndValue(
  RoomPowerLevels powerLevels,
  PermissionConfig permissionConfig,
) {
  return switch (permissionConfig.key) {
    'boost-post' => PowerLevelKeyAndValue(
      key: powerLevels.newsKey().toString(),
      value: permissionConfig.permissionLevel.value,
    ),
    'story-post' => PowerLevelKeyAndValue(
      key: powerLevels.storiesKey().toString(),
      value: permissionConfig.permissionLevel.value,
    ),
    'pin-post' => PowerLevelKeyAndValue(
      key: powerLevels.pinsKey().toString(),
      value: permissionConfig.permissionLevel.value,
    ),
    'event-post' => PowerLevelKeyAndValue(
      key: powerLevels.eventsKey().toString(),
      value: permissionConfig.permissionLevel.value,
    ),
    'event-rsvp' => PowerLevelKeyAndValue(
      key: powerLevels.rsvpKey().toString(),
      value: permissionConfig.permissionLevel.value,
    ),
    'task-list-post' => PowerLevelKeyAndValue(
      key: powerLevels.taskListsKey().toString(),
      value: permissionConfig.permissionLevel.value,
    ),
    'task-item-post' => PowerLevelKeyAndValue(
      key: powerLevels.tasksKey().toString(),
      value: permissionConfig.permissionLevel.value,
    ),
    _ => null,
  };
}
