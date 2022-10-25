import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class GroupMember extends StatelessWidget {
  final String name;
  final bool isAdmin;
  final Future<FfiBufferUint8>? avatar;

  const GroupMember({
    Key? key,
    required this.name,
    required this.isAdmin,
    this.avatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.horizontal,
      children: [
        CustomAvatar(
          radius: 16,
          isGroup: false,
          stringName: name,
          avatar: avatar,
          displayName: name,
        ),
        Expanded(
          // fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              name,
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
