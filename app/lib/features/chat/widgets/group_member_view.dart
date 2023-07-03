import 'package:acter/common/models/profile_data.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GroupMember extends StatelessWidget {
  final String userId;
  final bool isAdmin;
  final ProfileData? profile;

  const GroupMember({
    Key? key,
    required this.userId,
    required this.isAdmin,
    this.profile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.horizontal,
      children: [
        ActerAvatar(
          mode: DisplayMode.User,
          uniqueId: userId,
          size: profile != null
              ? profile!.getAvatarImage() != null
                  ? 16
                  : 32
              : 32,
          displayName: profile!.displayName ?? '',
          avatar: profile?.getAvatarImage(),
        ),
        Expanded(
          // fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              profile!.displayName ?? AppLocalizations.of(context)!.noName,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        Visibility(
          visible: isAdmin,
          child: const Text('Admin', style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}
