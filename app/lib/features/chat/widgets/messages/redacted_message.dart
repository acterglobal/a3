import 'package:acter/features/chat_ng/widgets/events/state_event_container_widget.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

class RedactedMessageWidget extends StatelessWidget {
  const RedactedMessageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(
                  Atlas.trash_can_thin,
                  size: textTheme.labelSmall?.fontSize,
                  color: textTheme.labelSmall?.color,
                ),
              ),
            ),
            TextSpan(
              text: L10n.of(context).chatMessageDeleted,
              style: stateEventTextStyle(context),
            ),
          ],
        ),
      ),
    );
  }
}
