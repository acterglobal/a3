import 'package:flutter/material.dart';

class EmojiReactionListItem extends StatelessWidget {
  final String emoji;

  const EmojiReactionListItem({
    Key? key,
    required this.emoji,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.horizontal,
      children: [
        const CircleAvatar(
          backgroundColor: Colors.white,
        ),
        const Expanded(
          // fit: FlexFit.loose,
          child: Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text(
              'Sample name',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        Text(
          emoji,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}
