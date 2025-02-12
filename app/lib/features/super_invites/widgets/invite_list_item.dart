import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class InviteListItem extends StatelessWidget {
  final SuperInviteToken inviteToken;

  const InviteListItem({
    super.key,
    required this.inviteToken,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final token = inviteToken.token();
    final firstRoom = asDartStringList(inviteToken.rooms()).firstOrNull;
    final acceptedCount = lang.usedTimes(inviteToken.acceptedCount());
    return Card(
      child: ListTile(
        title: Text(token),
        subtitle: Text(acceptedCount),
        onTap: () {
          context.pushNamed(
            Routes.createSuperInvite.name,
            extra: inviteToken,
          );
        },
        trailing: firstRoom != null
            ? OutlinedButton(
                onPressed: () => context.pushNamed(
                  Routes.shareInviteCode.name,
                  queryParameters: {
                    'inviteCode': token,
                    'roomId': firstRoom,
                  },
                ),
                child: Text(lang.share),
              )
            : null,
      ),
    );
  }
}
