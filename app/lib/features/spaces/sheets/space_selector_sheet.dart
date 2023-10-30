import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<String?> selectSpaceDrawer({
  required BuildContext context,
  String canCheck = 'CanLinkSpaces',
  String? currentSpaceId,
  Widget? title,
}) async {
  final selected = await showModalBottomSheet(
    context: context,
    isDismissible: true,
    builder: (context) => Consumer(
      builder: (context, ref, child) {
        final spaces = ref.watch(briefSpaceItemsProviderWithMembership);
        return SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: title ?? const Text('Select Space'),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Atlas.minus_circle_thin),
                      onPressed: () {
                        Navigator.pop(context, '');
                      },
                      label: const Text('Clear'),
                    ),
                  ],
                ),
                Expanded(
                  child: spaces.when(
                    data: (spaces) => spaces.isEmpty
                        ? const Text('no spaces found')
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: spaces.length,
                            itemBuilder: (context, index) {
                              final item = spaces[index];
                              final membership = item.membership!;
                              final profile = item.spaceProfileData;
                              final roomId = item.roomId;
                              final canLink = membership.canString(canCheck);
                              return ListTile(
                                key: Key('select-space-$roomId'),
                                enabled: canLink,
                                leading: ActerAvatar(
                                  mode: DisplayMode.Space,
                                  displayName: profile.displayName,
                                  uniqueId: roomId,
                                  avatar: profile.getAvatarImage(),
                                  size: 24,
                                ),
                                title: Text(profile.displayName ?? roomId),
                                trailing: currentSpaceId == roomId
                                    ? const Icon(Icons.check_circle_outline)
                                    : null,
                                onTap: canLink
                                    ? () {
                                        Navigator.pop(context, roomId);
                                      }
                                    : null,
                              );
                            },
                          ),
                    error: (e, s) => Center(
                      child: Text('error loading spaces: $e'),
                    ),
                    loading: () => const Center(
                      child: Text('loading'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  if (selected == null) {
    // in case of being dismissed, we return the previously selected item
    return currentSpaceId;
  }
  if (selected == '') {
    // in case of being cleared, we return null
    return null;
  }
  return selected;
}
