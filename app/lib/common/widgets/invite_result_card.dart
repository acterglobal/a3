import 'package:flutter/material.dart';

import 'package:acter/features/home/widgets/user_avatar.dart';

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
        const UserAvatarWidget(),
        Container(
          margin: const EdgeInsets.only(left: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:  [
              Text(displayName!),
              Text(username!),
            ],
          ),
        )
      ],
    );
  }
}