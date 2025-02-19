import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class LocationMessageWidget extends StatelessWidget {
  final CustomMessage message;
  const LocationMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text(message.metadata?['body'] ?? ''),
          Text(message.metadata?['geoUri'] ?? ''),
        ],
      ),
    );
  }
}
