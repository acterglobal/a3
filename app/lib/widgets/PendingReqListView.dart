import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class PendingReqListView extends StatelessWidget {
  final String userId;
  final Future<FfiBufferUint8>? avatar;
  final String? displayName;

  const PendingReqListView({
    Key? key,
    required this.userId,
    this.avatar,
    this.displayName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: CustomAvatar(
          uniqueKey: userId,
          avatar: avatar,
          displayName: displayName,
          radius: 25,
          isGroup: true,
          stringName: simplifyUserId(userId)!,
        ),
        title: Text(
          displayName ?? 'Unknown',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        trailing: const Text(
          'Withdraw',
          style: TextStyle(color: AppCommonTheme.primaryColor, fontSize: 16),
        ),
      ),
    );
  }
}
