import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;
import 'package:flutter/material.dart';

class StateUpdateEvent extends StatelessWidget {
  final RoomEventItem item;
  const StateUpdateEvent({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authorId = item.sender();
    final messageBody = item.msgContent()?.body() ?? '';

    return Container(
      padding: const EdgeInsets.only(
        left: 10,
        bottom: 5,
      ),
      child: RichText(
        text: TextSpan(
          text: authorId,
          style: textTheme.bodySmall,
          children: [
            const WidgetSpan(
              child: SizedBox(width: 3),
            ),
            TextSpan(
              text: messageBody,
              style: textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
