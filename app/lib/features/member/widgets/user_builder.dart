import 'dart:typed_data';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::member::user');

final userAvatarProvider = FutureProvider.family<MemoryImage?, UserProfile>((
  ref,
  user,
) async {
  if (user.hasAvatar()) {
    try {
      final data = (await user.getAvatar(null)).data();
      if (data != null) {
        return MemoryImage(Uint8List.fromList(data.asTypedList()));
      }
    } catch (e, s) {
      _log.severe('failure fetching avatar', e, s);
    }
  }
  return null;
});

final userAvatarInfoProvider = Provider.family<AvatarInfo, UserProfile>((
  ref,
  user,
) {
  final displayName = user.displayName();
  final avatarData = ref.watch(userAvatarProvider(user)).valueOrNull;

  return AvatarInfo(
    uniqueId: user.userId().toString(),
    displayName: displayName,
    avatar: avatarData,
  );
});

bool isInvited(String userId, List<Member> invited) {
  return invited.any((member) => member.userId().toString() == userId);
}

bool isJoined(String userId, List<String> joined) {
  return joined.contains(userId);
}

class _RoomName extends ConsumerWidget {
  final String roomId;

  const _RoomName({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDirectChat =
        ref.watch(isDirectChatProvider(roomId)).valueOrNull ?? false;
    if (isDirectChat) {
      return Text(
        L10n.of(context).dmChat,
        style: const TextStyle(fontStyle: FontStyle.italic),
      );
    }
    return Text(
      ref.watch(roomDisplayNameProvider(roomId)).valueOrNull ?? roomId,
      style: const TextStyle(
        decoration: TextDecoration.underline,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class UserBuilder extends ConsumerWidget {
  final String userId;
  final String? roomId;
  final UserProfile? userProfile;
  final bool includeSharedRooms;
  final bool includeUserJoinState;
  final VoidCallback? onTap;

  const UserBuilder({
    super.key,
    required this.userId,
    this.roomId,
    this.userProfile,
    this.onTap,
    this.includeSharedRooms = false,
    this.includeUserJoinState = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarInfo = _avatarInfo(ref);
    final displayName = _displayName(ref);
    final tile = Card(
      child: ListTile(
        onTap: onTap,
        title: Text(displayName ?? userId),
        subtitle: (displayName == null) ? null : Text(userId),
        leading: ActerAvatar(options: AvatarOptions.DM(avatarInfo, size: 18)),
        trailing: _renderTrailing(context, ref),
      ),
    );
    if (includeSharedRooms) {
      return _buildSharedRooms(context, tile);
    }
    return tile;
  }

  Widget? _renderTrailing(BuildContext context, WidgetRef ref) {
    if (!includeUserJoinState) return null;
    return roomId.map((rId) {
      final room = ref.watch(maybeRoomProvider(rId)).valueOrNull;
      return room.map((r) => UserStateButton(userId: userId, room: r)) ??
          const Skeletonizer(child: Text('user'));
    });
  }

  Widget _buildSharedRooms(BuildContext context, Widget tile) {
    final sharedRooms =
        userProfile.map((p0) => asDartStringList(p0.sharedRooms())) ?? [];
    if (sharedRooms.isEmpty) return tile;

    final lang = L10n.of(context);
    const style = TextStyle(fontStyle: FontStyle.italic);

    Widget sharedRoomsRow = switch (sharedRooms.length) {
      1 => Wrap(
        children: [
          Text(lang.youAreBothIn, style: style), //lang.youAreBothIn),
          _RoomName(roomId: sharedRooms[0]),
        ],
      ),
      2 => Wrap(
        children: [
          Text(lang.youAreBothIn, style: style), //lang.youAreBothIn),
          _RoomName(roomId: sharedRooms[0]),
          Text(lang.andSeparator, style: style),
          _RoomName(roomId: sharedRooms[1]),
        ],
      ),
      3 => Wrap(
        children: [
          Text(lang.youAreBothIn, style: style), //lang.youAreBothIn),
          _RoomName(roomId: sharedRooms[0]),
          const Text(', ', style: style),
          _RoomName(roomId: sharedRooms[1]),
          Text(lang.andSeparator, style: style),
          _RoomName(roomId: sharedRooms[2]),
        ],
      ),
      _ => Wrap(
        children: [
          Text(lang.youAreBothIn, style: style), //lang.youAreBothIn),
          _RoomName(roomId: sharedRooms[0]),
          const Text(', ', style: style),
          _RoomName(roomId: sharedRooms[1]),
          Text(lang.andNMore(sharedRooms.length - 2), style: style),
        ],
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile,
        Padding(
          padding: const EdgeInsets.only(left: 25, bottom: 10),
          child: sharedRoomsRow,
        ),
      ],
    );
  }

  AvatarInfo _avatarInfo(WidgetRef ref) {
    return userProfile.map((profile) {
          return ref.watch(userAvatarInfoProvider(profile));
        }) ??
        roomId.map((rId) {
          return ref.watch(
            memberAvatarInfoProvider((roomId: rId, userId: userId)),
          );
        }) ??
        AvatarInfo(uniqueId: userId);
  }

  String? _displayName(WidgetRef ref) {
    return userProfile?.displayName() ??
        roomId.map((rId) {
          return ref
              .watch(memberDisplayNameProvider((roomId: rId, userId: userId)))
              .valueOrNull;
        });
  }
}

class UserStateButton extends ConsumerWidget {
  final String userId;
  final Room room;

  const UserStateButton({super.key, required this.room, required this.userId});

  Future<void> _handleInvite(BuildContext context) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.invitingLoading(userId), dismissOnTap: false);
    try {
      await room.inviteUser(userId);
      EasyLoading.dismiss();
    } catch (e) {
      // ignore: use_build_context_synchronously
      EasyLoading.showToast(lang.invitingError(e, userId));
    }
  }

  Future<void> _cancelInvite(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    EasyLoading.show(
      status: lang.cancelInviteLoading(userId),
      dismissOnTap: false,
    );
    try {
      final member =
          ref
              .read(memberProvider((userId: userId, roomId: room.roomIdStr())))
              .valueOrNull;
      if (member != null) {
        await member.kick('Cancel Invite');
      }
      EasyLoading.dismiss();
    } catch (e) {
      // ignore: use_build_context_synchronously
      EasyLoading.showToast(lang.cancelInviteError(e, userId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final roomId = room.roomIdStr();
    final invited =
        ref.watch(roomInvitedMembersProvider(roomId)).valueOrNull ?? [];
    final joined = ref.watch(membersIdsProvider(roomId)).valueOrNull ?? [];
    if (isInvited(userId, invited)) {
      return InkWell(
        onTap: () => _cancelInvite(context, ref),
        child: Chip(
          label: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              lang.revoke,
              style: TextStyle(color: colorScheme.errorContainer),
            ),
          ),
          side: BorderSide(color: colorScheme.errorContainer),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    if (isJoined(userId, joined)) {
      return Chip(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(lang.joined),
        ),
        backgroundColor: colorScheme.success,
        side: BorderSide(color: colorScheme.success),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    }
    return InkWell(
      onTap: () => _handleInvite(context),
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.invite, style: TextStyle(color: colorScheme.primary)),
            const SizedBox(width: 5),
            Icon(
              Atlas.paper_airplane_thin,
              color: colorScheme.primary,
              size: 16,
            ),
          ],
        ),
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
