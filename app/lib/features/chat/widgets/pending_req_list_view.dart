import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class PendingReqListView extends StatelessWidget {
  final String userId;
  final Future<OptionBuffer> avatar;
  final String? displayName;

  const PendingReqListView({
    Key? key,
    required this.userId,
    required this.avatar,
    this.displayName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: ActerAvatar(
          mode: DisplayMode.User,
          uniqueId: userId,
          displayName: displayName,
          size: 25,
        ),
        title: Text(
          displayName ?? 'Unknown',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        trailing: const Text(
          'Withdraw',
        ),
      ),
    );
  }
}
