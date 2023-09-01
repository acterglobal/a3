import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class StatusBuilder extends ConsumerWidget {
  final types.Message m;
  final BuildContext ctx;
  const StatusBuilder(this.m, this.ctx, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (m.metadata!.containsKey('seenBy')) {
      List<String> userIds = m.metadata?['seenBy'];
    }

    return const SizedBox();
  }
}
