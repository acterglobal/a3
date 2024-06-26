import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ChatSelectPage extends ConsumerWidget {
  const ChatSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Text(L10n.of(context).selectAnyRoomToSeeIt),
    );
  }
}
