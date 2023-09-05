import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatSelectPage extends ConsumerWidget {
  const ChatSelectPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox(
      child: Center(
        child: Text('Select any room to see see it'),
      ),
    );
  }
}
