import 'package:acter/common/toolkit/widgets/acter_selection_area.dart';
import 'package:flutter/material.dart';

class StateEventContainerWidget extends StatelessWidget {
  final Widget child;
  const StateEventContainerWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (child == const SizedBox.shrink()) return child;

    return ActerSelectionArea(
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 100,
          ),
          child: child,
        ),
      ),
    );
  }
}

TextStyle stateEventTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelSmall!.copyWith(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
  );
}
