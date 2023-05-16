import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart' show remapToImage;

class GroupMember extends StatelessWidget {
  final String userId;
  final String? name;
  final bool isAdmin;
  final Future<FfiBufferUint8>? avatar;

  const GroupMember({
    Key? key,
    required this.userId,
    this.name,
    required this.isAdmin,
    this.avatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.horizontal,
      children: [
        ActerAvatar(
          mode: DisplayMode.User,
          uniqueId: userId,
          size: 16,
          avatarProviderFuture: avatar != null
              ? remapToImage(
                  avatar!,
                  cacheHeight: 32,
                )
              : null,
          displayName: name,
        ),
        Expanded(
          // fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              name ?? AppLocalizations.of(context)!.noName,
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
