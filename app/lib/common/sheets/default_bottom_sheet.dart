import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void defaultBottomSheet({
  required BuildContext context,
  required Widget content,
  BoxDecoration? sheetDecoration,
  bool isCupertino = false,
  Widget? header,
  double sheetHeight = 300.0,
}) {
  isCupertino
      ? showCupertinoModalPopup(
          context: context,
          builder: (BuildContext context) {
            return CupertinoActionSheet(
              title: header ?? const SizedBox.shrink(),
              message: content,
              actions: <Widget>[
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        )
      : showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return GestureDetector(
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
          },
        );
}
