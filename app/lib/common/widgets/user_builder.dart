import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';

import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::user');

final userAvatarProvider =
    FutureProvider.family<MemoryImage?, UserProfile>((ref, user) async {
  if (user.hasAvatar()) {
    try {
      final data = (await user.getAvatar(null)).data();
      if (data != null) {
        return MemoryImage(data.asTypedList());
      }
    } catch (e, s) {
      _log.severe('failure fetching avatar', e, s);
    }
  }
  return null;
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

class UserBuilder extends ConsumerWidget {
  final UserProfile profile;
  final String roomId;

  const UserBuilder({
    super.key,
    required this.profile,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(maybeRoomProvider(roomId)).valueOrNull;
    final avatarProv = ref.watch(userAvatarProvider(profile));
    final displayName = profile.getDisplayName();
    final userId = profile.userId().toString();
    return Card(
      child: ListTile(
        title: Text(displayName ?? userId),
        subtitle: (displayName == null) ? null : Text(userId),
        leading: ActerAvatar(
          options: AvatarOptions.DM(
            AvatarInfo(
              uniqueId: userId,
              displayName: displayName,
              avatar: avatarProv.valueOrNull,
            ),
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
  }
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
