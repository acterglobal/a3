import 'package:acter/features/space/providers/pins_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

class PinListItem extends ConsumerStatefulWidget {
  final ActerPin pin;
  const PinListItem({super.key, required this.pin});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PinListItemState();
}

class _PinListItemState extends ConsumerState<PinListItem> {
  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    final isLink = pin.isLink();
    return ListTile(
      key: Key(pin.eventId().toString()),
      leading: Icon(isLink ? Atlas.link_chain_thin : Atlas.document_thin),
      title: Text(pin.title()),
    );
  }
}

// class ChildItem extends StatelessWidget {
//   final ActerPin pin;
//   const ChildItem({Key? key, required this.pin}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final profile = space.spaceProfileData;
//     final roomId = space.roomId;
//     return Card(
//       shape: RoundedRectangleBorder(
//         side: BorderSide(
//           color: Theme.of(context).colorScheme.inversePrimary,
//           width: 1.5,
//         ),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       color: Theme.of(context).colorScheme.surface,
//       child: ListTile(
//         contentPadding: const EdgeInsets.all(15),
//         onTap: () => context.go('/$roomId'),
//         title: Text(
//           profile.displayName ?? roomId,
//           style: Theme.of(context).textTheme.bodySmall,
//         ),
//         leading: ActerAvatar(
//           mode: DisplayMode.Space,
//           displayName: profile.displayName,
//           uniqueId: roomId,
//           avatar: profile.getAvatarImage(),
//           size: 48,
//         ),
//         trailing: const Icon(Icons.more_vert),
//       ),
//     );
//   }
// }