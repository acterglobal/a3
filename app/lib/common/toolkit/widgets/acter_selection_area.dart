import 'package:flutter/material.dart';

class ActerSelectionArea extends StatelessWidget {
  final Widget child;
  const ActerSelectionArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TextSelectionTheme(
      data: TextSelectionThemeData(
        selectionColor: Theme.of(
          context,
        ).colorScheme.secondary.withValues(alpha: 0.3),
      ),
      child: SelectionArea(child: child),
    );
  }
}
