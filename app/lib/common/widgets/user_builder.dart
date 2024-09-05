import 'dart:typed_data';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::common::user');

final userAvatarProvider =
    FutureProvider.family<MemoryImage?, UserProfile>((ref, user) async {
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

final userAvatarInfoProvider =
    Provider.family<AvatarInfo, UserProfile>((ref, user) {
  final displayName = user.displayName();
  final avatarData = ref.watch(userAvatarProvider(user)).valueOrNull;

  return AvatarInfo(
    uniqueId: user.userId().toString(),
    displayName: displayName,
    avatar: avatarData,
  );
});

bool isInvited(String userId, List<Member> invited) {
  for (final i in invited) {
    if (i.userId().toString() == userId) {
      return true;
    }
  }
  return false;
}

bool isJoined(String userId, List<String> joined) {
  for (final i in joined) {
    if (i == userId) {
      return true;
    }
  }
  return false;
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
        style: const TextStyle(
          fontStyle: FontStyle.italic,
        ),
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
  final String roomId;
  final UserProfile? userProfile;
  final bool includeSharedRooms;

  const UserBuilder({
    super.key,
    required this.userId,
    required this.roomId,
    this.userProfile,
    this.includeSharedRooms = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(maybeRoomProvider(roomId)).valueOrNull;
    final avatarInfo = _avatarInfo(ref);
    final displayName = _displayName(ref);
    final tile = Card(
      child: ListTile(
        title: Text(displayName ?? userId),
        subtitle: (displayName == null) ? null : Text(userId),
        leading: ActerAvatar(
          options: AvatarOptions.DM(
            avatarInfo,
            size: 18,
          ),
        ),
        trailing: room != null
            ? UserStateButton(
                userId: userId,
                room: room,
              )
            : const Skeletonizer(
                child: Text('Loading user'),
              ),
      ),
    );
    if (includeSharedRooms) {
      return _buildSharedRooms(context, tile);
    }
    return tile;
  }

  Widget _buildSharedRooms(BuildContext context, Widget tile) {
    final sharedRooms =
        userProfile?.sharedRooms().map((s) => s.toDartString()).toList() ?? [];
    if (sharedRooms.isEmpty) {
      return tile;
    }

    const style = TextStyle(fontStyle: FontStyle.italic);

    Widget sharedRoomsRow = switch (sharedRooms.length) {
      1 => Wrap(
          children: [
            const Text(
              'you are both in ',
              style: style,
            ), //L10n.of(context).youAreBothIn),
            _RoomName(roomId: sharedRooms[0]),
          ],
        ),
      2 => Wrap(
          children: [
            Text(
              'you are both in ',
              style: style,
            ), //L10n.of(context).youAreBothIn),
            _RoomName(roomId: sharedRooms[0]),
            Text(
              ' and ',
              style: style,
            ),
            _RoomName(roomId: sharedRooms[1]),
          ],
        ),
      3 => Wrap(
          children: [
            Text(
              'you are both in ',
              style: style,
            ), //L10n.of(context).youAreBothIn),
            _RoomName(roomId: sharedRooms[0]),
            Text(
              ', ',
              style: style,
            ),
            _RoomName(roomId: sharedRooms[1]),
            Text(
              ' and ',
              style: style,
            ),
            _RoomName(roomId: sharedRooms[2]),
          ],
        ),
      _ => Wrap(
          children: [
            Text(
              'you are both in ',
              style: style,
            ), //L10n.of(context).youAreBothIn),
            _RoomName(roomId: sharedRooms[0]),
            Text(
              ', ',
              style: style,
            ),
            _RoomName(roomId: sharedRooms[1]),
            Text(
              ', and ${sharedRooms.length - 2} more',
              style: style,
            ),
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

  AvatarInfo _avatarInfo(WidgetRef ref) => (userProfile != null)
      ? ref.watch(userAvatarInfoProvider(userProfile!))
      : ref.watch(memberAvatarInfoProvider((roomId: roomId, userId: userId)));

  String? _displayName(WidgetRef ref) =>
      userProfile?.displayName() ??
      ref
          .watch(memberDisplayNameProvider((roomId: roomId, userId: userId)))
          .valueOrNull;
}

class UserStateButton extends ConsumerWidget {
  final String userId;
  final Room room;

  const UserStateButton({
    super.key,
    required this.room,
    required this.userId,
  });

  void _handleInvite(BuildContext context) async {
    EasyLoading.show(
      status: L10n.of(context).invitingLoading(userId),
      dismissOnTap: false,
    );
    try {
      await room.inviteUser(userId);
      EasyLoading.dismiss();
    } catch (e) {
      // ignore: use_build_context_synchronously
      EasyLoading.showToast(L10n.of(context).invitingError(e, userId));
    }
  }

  void _cancelInvite(BuildContext context, WidgetRef ref) async {
    EasyLoading.show(
      status: L10n.of(context).cancelInviteLoading(userId),
      dismissOnTap: false,
    );
    try {
      final member = ref
          .read(memberProvider((userId: userId, roomId: room.roomIdStr())))
          .valueOrNull;
      if (member != null) {
        await member.kick('Cancel Invite');
      }
      EasyLoading.dismiss();
    } catch (e) {
      // ignore: use_build_context_synchronously
      EasyLoading.showToast(L10n.of(context).cancelInviteError(e, userId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invited =
        ref.watch(roomInvitedMembersProvider(room.roomIdStr())).valueOrNull ??
            [];
    final joined =
        ref.watch(membersIdsProvider(room.roomIdStr())).valueOrNull ?? [];
    if (isInvited(userId, invited)) {
      return InkWell(
        onTap: () => _cancelInvite(context, ref),
        child: Chip(
          label: Text(L10n.of(context).revoke),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    if (isJoined(userId, joined)) {
      return Chip(
        label: Text(L10n.of(context).joined),
        backgroundColor: Theme.of(context).colorScheme.success,
      );
    }
    return InkWell(
      onTap: () => _handleInvite(context),
      child: Chip(
        avatar: const Icon(Atlas.paper_airplane_thin),
        label: Text(L10n.of(context).invite),
      ),
    );
  }
}
