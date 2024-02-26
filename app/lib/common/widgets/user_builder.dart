import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        ),
        trailing: room.when(
          data: (data) => InviteButton(
            userId: userId,
            room: data.room!,
            invited: isInvited(userId, invited),
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

class InviteButton extends StatefulWidget {
  final String userId;
  final bool invited;
  final Room room;

  const InviteButton({
    super.key,
    required this.room,
    this.invited = false,
    required this.userId,
  });

  @override
  State<StatefulWidget> createState() => _InviteButtonState();
}

class _InviteButtonState extends State<InviteButton> {
  bool _loading = false;
  bool _success = false;

  @override
  Widget build(BuildContext context) {
    if (widget.invited || _success) {
      return const Chip(label: Text('invited'));
    }

    if (_loading) {
      return const CircularProgressIndicator();
    }

    return OutlinedButton.icon(
      onPressed: () async {
        if (mounted) {
          setState(() => _loading = true);
        }
        await widget.room.inviteUser(widget.userId);
        if (mounted) {
          setState(() => _success = true);
        }
      },
      icon: const Icon(Atlas.paper_airplane_thin),
      label: const Text('invite'),
    );
  }
}
