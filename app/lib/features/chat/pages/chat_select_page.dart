import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/generated/l10n.dart';

class ChatSelectPage extends ConsumerWidget {
  const ChatSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(child: Text(L10n.of(context).selectAnyRoomToSeeIt));
  }
}
