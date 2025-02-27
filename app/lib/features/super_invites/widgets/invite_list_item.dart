import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class InviteListItem extends StatelessWidget {
  final SuperInviteToken? inviteToken;
  final EdgeInsetsGeometry? cardMargin;
  final Function(SuperInviteToken)? onSelectInviteCode;

  const InviteListItem({
    super.key,
    this.inviteToken,
    this.cardMargin,
    this.onSelectInviteCode,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);

    if (inviteToken == null) return SizedBox.shrink();

    final token = inviteToken!.token();
    final firstRoom = asDartStringList(inviteToken!.rooms()).firstOrNull;
    final acceptedCount = lang.usedTimes(inviteToken!.acceptedCount());
    return ClipPath(
      clipper: MyClipper(),
      child: Card(
        margin: cardMargin,
        child: ListTile(
          title: Text(token),
          subtitle: Text(
            acceptedCount,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          onTap: () {
            if (onSelectInviteCode != null && inviteToken != null) {
              onSelectInviteCode!(inviteToken!);
            } else {
              context.pushNamed(
                Routes.createSuperInvite.name,
                extra: inviteToken,
              );
            }
          },
          trailing:
              firstRoom != null && onSelectInviteCode == null
                  ? IconButton(
                    onPressed:
                        () => context.pushNamed(
                          Routes.shareInviteCode.name,
                          queryParameters: {
                            'inviteCode': token,
                            'roomId': firstRoom,
                          },
                        ),
                    icon: Icon(PhosphorIcons.share()),
                  )
                  : null,
        ),
      ),
    );
  }
}

class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var smallLineLength = size.width / 20;
    const smallLineHeight = 20;
    var path = Path();

    path.lineTo(0, size.height);
    for (int i = 1; i <= 20; i++) {
      if (i % 2 == 0) {
        path.lineTo(smallLineLength * i, size.height);
      } else {
        path.lineTo(smallLineLength * i, size.height - smallLineHeight);
      }
    }
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) => false;
}
