import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';

class InviteResultCard extends StatelessWidget {
  final String? displayName;
  final String? username;

  const InviteResultCard({
    super.key,  this.displayName, required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ActerAvatar(
          mode: DisplayMode.User,
          uniqueId: username!,
          displayName: displayName,
          size: 50,

        ),
        Container(
          margin: const EdgeInsets.only(left: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:  [
              Text(displayName!),
              Text(username!),
            ],
          ),
        ),
      ],
    );
  }
}