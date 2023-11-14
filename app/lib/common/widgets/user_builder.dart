import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userAvatarProvider =
    FutureProvider.family<MemoryImage?, UserProfile>((ref, user) async {
  if (await user.hasAvatar()) {
    try {
      final data = (await user.getAvatar()).data();
      if (data != null) {
        return MemoryImage(data.asTypedList());
      }
    } catch (e) {
      debugPrint('failure fetching avatar $e');
    }
  }
  return null;
});

final displayNameProvider =
    FutureProvider.family<String?, UserProfile>((ref, user) async {
  return (await user.getDisplayName()).text();
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
    Key? key,
    required this.profile,
    required this.roomId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(briefRoomItemWithMembershipProvider(roomId));
    final invited =
        ref.watch(roomInvitedMembersProvider(roomId)).valueOrNull ?? [];
    final avatarProv = ref.watch(userAvatarProvider(profile));
    final displayName = ref.watch(displayNameProvider(profile));
    final userId = profile.userId().toString();
    return Card(
      child: ListTile(
        title: displayName.when(
          data: (data) => Text(data ?? userId),
          error: (err, stackTrace) => Text('Error: $err'),
          loading: () => const Text('Loading display name'),
        ),
        subtitle: displayName.when(
          data: (data) {
            return (data == null) ? null : Text(userId);
          },
          error: (err, stackTrace) => Text('Error: $err'),
          loading: () => const Text('Loading display name'),
        ),
        leading: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(
            uniqueId: userId,
            displayName: displayName.valueOrNull,
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
          loading: () => const Text('Loading user'),
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
