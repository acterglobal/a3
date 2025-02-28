import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomUpdateEvent extends ConsumerWidget {
  final RoomEventItem item;
  final String roomId;
  const RoomUpdateEvent({super.key, required this.item, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final authorId = item.sender();
    final firstName = ref
        .watch(memberDisplayNameProvider((roomId: roomId, userId: authorId)))
        .valueOrNull;

    final messageBody = item.msgContent()?.body() ?? '';

    print(item.eventType());

    return Container(
      padding: const EdgeInsets.only(
        left: 10,
        bottom: 5,
        right: 10,
      ),
      child: RichText(
        text: TextSpan(
          text: firstName ?? authorId,
          style: textTheme.labelSmall,
          children: [
            const WidgetSpan(
              child: SizedBox(width: 3),
            ),
            TextSpan(
              text: messageBody,
              style: textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
