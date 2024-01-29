import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatSelectPage extends ConsumerWidget {
  const ChatSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        gradient: primaryGradient,
      ),
      child: const Center(
        child: Text('Select any room to see it'),
      ),
    );
  }
}
