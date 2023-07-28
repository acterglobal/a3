import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:string_validator/string_validator.dart';

class ImageMessageBuilder extends StatelessWidget {
  final types.ImageMessage message;
  final int messageWidth;

  const ImageMessageBuilder({
    Key? key,
    required this.message,
    required this.messageWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.metadata?.containsKey('base64') ?? false) {
      if (message.metadata?['base64'].isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.memory(
            base64Decode(message.metadata?['base64']),
            errorBuilder: (
              BuildContext context,
              Object url,
              StackTrace? error,
            ) {
              return Text('Could not load image due to $error');
            },
            frameBuilder: (
              BuildContext context,
              Widget child,
              int? frame,
              bool wasSynchronouslyLoaded,
            ) {
              if (wasSynchronouslyLoaded) {
                return child;
              }
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(seconds: 1),
                curve: Curves.easeOut,
                child: child,
              );
            },
            cacheWidth: 256,
            width: messageWidth.toDouble() / 2,
            fit: BoxFit.cover,
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: const SizedBox(
            height: 60,
            width: 60,
            child: CircularProgressIndicator(strokeWidth: 6),
          ),
        );
      }
    } else if (message.uri.isNotEmpty && isURL(message.uri)) {
      // remote url
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CachedNetworkImage(
          imageUrl: message.uri,
          width: messageWidth.toDouble(),
          errorWidget: (
            BuildContext context,
            Object url,
            dynamic error,
          ) {
            return Text('Could not load image due to $error');
          },
        ),
      );
    }
    // local path
    // the image that just sent is displayed from local not remote
    else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          File(message.uri),
          width: messageWidth.toDouble(),
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return Text('Could not load image due to $error');
          },
        ),
      );
    }
  }
}
