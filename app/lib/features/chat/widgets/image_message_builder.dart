import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:string_validator/string_validator.dart';

class ImageMessageBuilder extends ConsumerStatefulWidget {
  final types.ImageMessage message;
  final int messageWidth;
  final bool isReplyContent;

  const ImageMessageBuilder({
    Key? key,
    required this.message,
    required this.messageWidth,
    this.isReplyContent = false,
  }) : super(key: key);

  @override
  ConsumerState<ImageMessageBuilder> createState() =>
      _ImageMessageBuilderConsumerState();
}

class _ImageMessageBuilderConsumerState
    extends ConsumerState<ImageMessageBuilder> {
  Uint8List? decodedImage;

  @override
  void initState() {
    super.initState();

    if (widget.message.metadata?.containsKey('base64') ?? false) {
      if (widget.message.metadata?['base64'].isNotEmpty) {
        decodedImage = base64Decode(widget.message.metadata?['base64']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (decodedImage != null && decodedImage!.isNotEmpty) {
      if (widget.isReplyContent) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.2,
              maxWidth: MediaQuery.of(context).size.width * 0.2,
            ),
            child: Image.memory(
              decodedImage!,
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
              fit: BoxFit.cover,
            ),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
            maxWidth: MediaQuery.of(context).size.width * 0.4,
          ),
          child: Image.memory(
            decodedImage!,
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
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (widget.message.uri.isNotEmpty && isURL(widget.message.uri)) {
      // remote url
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CachedNetworkImage(
          imageUrl: widget.message.uri,
          width: widget.messageWidth.toDouble(),
          errorWidget: (
            BuildContext context,
            Object url,
            dynamic error,
          ) {
            return Text('Could not load image due to $error');
          },
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
  }
}
