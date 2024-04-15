import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// reusable outer attachment container UI
class AttachmentContainer extends ConsumerWidget {
  const AttachmentContainer({
    super.key,
    required this.name,
    required this.child,
  });
  final String name;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containerColor = Theme.of(context).colorScheme.background;
    final borderColor = Theme.of(context).colorScheme.primary;
    final containerTextStyle = Theme.of(context).textTheme.bodySmall;
    return Container(
      height: 100,
      width: 100,
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 0),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(child: child),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            child: Text(
              name,
              style:
                  containerTextStyle!.copyWith(overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
