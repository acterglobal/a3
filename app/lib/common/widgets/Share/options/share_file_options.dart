import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ShareFileOptions extends StatelessWidget {
  final File file;

  const ShareFileOptions({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'More',
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            iconItem('Open', PhosphorIcons.fileArrowUp()),
            iconItem('Save', PhosphorIcons.download()),
          ],
        ),
      ],
    );
  }

  Widget iconItem(String name, IconData iconData) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(iconData),
          SizedBox(height: 6),
          Text(name),
        ],
      ),
    );
  }
}
