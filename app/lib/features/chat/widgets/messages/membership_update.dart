import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class MembershipUpdateWidget extends StatelessWidget {
  final CustomMessage message;
  const MembershipUpdateWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, bottom: 5),
      child: RichText(
        text: TextSpan(
          text: message.author.id,
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            const WidgetSpan(
              child: SizedBox(width: 3),
            ),
            TextSpan(
              text: message.metadata?['body'] ?? '',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
