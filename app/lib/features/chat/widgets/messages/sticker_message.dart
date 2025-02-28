import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:acter/l10n/l10n.dart';

class StickerMessageWidget extends StatelessWidget {
  final CustomMessage message;
  final int messageWidth;

  const StickerMessageWidget({
    super.key,
    required this.message,
    required this.messageWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: message.metadata?['width'],
      padding: const EdgeInsets.all(18),
      constraints: const BoxConstraints(minWidth: 57),
      child: Image.memory(
        base64Decode(message.metadata?['base64'] ?? ''),
        errorBuilder: stickerErrorBuilder,
        frameBuilder: stickerFrameBuilder,
        cacheWidth: 256,
        width: messageWidth.toDouble() / 2,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget stickerErrorBuilder(
    BuildContext context,
    Object url,
    StackTrace? error,
  ) {
    return Text(L10n.of(context).couldNotLoadImage(error.toString()));
  }

  Widget stickerFrameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded) {
      return child;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child:
          frame != null
              ? child
              : const SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(strokeWidth: 6),
              ),
    );
  }
}
