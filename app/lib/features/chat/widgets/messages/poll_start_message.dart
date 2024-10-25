import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class PollStartMessageWidget extends StatelessWidget {
  final CustomMessage message;

  const PollStartMessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.only(
        left: 10,
        bottom: 5,
      ),
      child: RichText(
        text: TextSpan(
          text: message.author.id,
          style: textTheme.bodySmall,
          children: [
            const WidgetSpan(
              child: SizedBox(width: 3),
            ),
            TextSpan(
              text: message.metadata?['body'] ?? '',
              style: textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
