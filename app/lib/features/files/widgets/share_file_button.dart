import 'dart:io';
import 'package:acter/features/files/actions/file_share.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ShareFileButton extends StatelessWidget {
  final File file;

  const ShareFileButton({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => openFileShareDialog(context: context, file: file),
      icon: PhosphorIcon(PhosphorIcons.shareFat()),
    );
  }
}
