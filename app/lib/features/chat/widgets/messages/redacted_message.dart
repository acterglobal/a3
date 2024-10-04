import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class RedactedMessageWidget extends StatelessWidget {
  const RedactedMessageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      child: Text(
        L10n.of(context).chatMessageDeleted,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
