import 'package:acter/features/search/widgets/quick_jump.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

const Map<String, String> empty = {};

class QuickjumpDialog extends ConsumerWidget {
  const QuickjumpDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 400),
      child: Scaffold(
        appBar: AppBar(title: Text(L10n.of(context).jumpTo)),
        body: const QuickJump(
          expand: false,
        ),
      ),
    );
  }
}
