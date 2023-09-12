import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reusable bottom sheet widget
class DefaultBottomSheet extends ConsumerWidget {
  final Widget content;
  final Widget? header;
  final BoxDecoration? sheetDecoration;
  final bool isCupertino;
  final double sheetHeight;
  const DefaultBottomSheet({
    super.key,
    required this.content,
    this.sheetDecoration,
    this.header,
    this.isCupertino = false,
    this.sheetHeight = 300.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isCupertino
        ? CupertinoActionSheet(
            title: header ?? const SizedBox.shrink(),
            message: content,
            actions: <Widget>[
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          )
        : GestureDetector(
            onTap: () {
              // Close the bottom sheet when tapping outside of it.
              Navigator.of(context).pop();
            },
            child: Container(
              height: sheetHeight,
              padding: const EdgeInsets.all(16.0),
              decoration: sheetDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  header ?? const SizedBox.shrink(),
                  const SizedBox(height: 16.0),
                  Expanded(
                    child: SingleChildScrollView(
                      child: content,
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
