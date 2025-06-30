import 'package:acter/features/chat_ng/widgets/events/state_event_container_widget.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

class RedactedMessageWidget extends StatelessWidget {
  const RedactedMessageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = stateEventTextStyle(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            Atlas.trash_can_thin,
            size: textTheme.fontSize,
            color: textTheme.color,
          ),
          const SizedBox(width: 6),
          Text(L10n.of(context).chatMessageDeleted, style: textTheme),
        ],
      ),
    );
  }
}
