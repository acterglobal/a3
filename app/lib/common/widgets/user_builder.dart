import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';

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
    final room = ref.watch(briefRoomItemWithMembershipProvider(roomId));
    final invited =
        ref.watch(roomInvitedMembersProvider(roomId)).valueOrNull ?? [];
    final joined = ref.watch(membersIdsProvider(roomId)).valueOrNull ?? [];
    final avatarProv = ref.watch(userAvatarProvider(profile));
    final displayName = profile.getDisplayName();
    final userId = profile.userId().toString();
    return Card(
      child: ListTile(
        title: Text(displayName ?? userId),
        subtitle: (displayName == null) ? null : Text(userId),
        leading: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(
            uniqueId: userId,
            displayName: displayName,
            avatar: avatarProv.valueOrNull,
          ),
          size: 18,
        ),
        trailing: room.when(
          data: (data) => UserStateButton(
            userId: userId,
            room: data.room!,
            invited: isInvited(userId, invited),
            joined: isJoined(userId, joined),
          ),
          error: (err, stackTrace) => Text('Error: $err'),
          loading: () => const Skeletonizer(
            child: Text('Loading user'),
          ),
        ),
      ),
    );
  }
}

class UserStateButton extends StatefulWidget {
  final String userId;
  final bool invited;
  final bool joined;
  final Room room;

  const UserStateButton({
    super.key,
    required this.room,
    this.invited = false,
    this.joined = false,
    required this.userId,
  });

  @override
  State<StatefulWidget> createState() => _UserStateButtonState();
}

class _UserStateButtonState extends State<UserStateButton> {
  void _handleInvite() async {
    EasyLoading.show(
      status: L10n.of(context).invitingLoading(widget.userId),
      dismissOnTap: false,
    );
    try {
      await widget.room.inviteUser(widget.userId);
      EasyLoading.dismiss();
    } catch (e) {
      // ignore: use_build_context_synchronously
      EasyLoading.showToast(L10n.of(context).invitingError(e, widget.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.invited) {
      return Chip(
        label: Text(L10n.of(context).invited),
        backgroundColor: Theme.of(context).colorScheme.success,
      );
    }
    if (widget.joined) {
      return Chip(
        label: Text(L10n.of(context).joined),
        backgroundColor: Theme.of(context).colorScheme.success,
      );
    }
    return InkWell(
      onTap: _handleInvite,
      child: Chip(
        avatar: Icon(
          Atlas.paper_airplane_thin,
          color: Theme.of(context).colorScheme.neutral6,
        ),
        label: Text(L10n.of(context).invite),
      ),
    );
  }
}
