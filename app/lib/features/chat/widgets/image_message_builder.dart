import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

class ImageMessageBuilder extends StatefulWidget {
  final types.ImageMessage message;
  final int messageWidth;
  final bool isReplyContent;
  final Convo convo;

  const ImageMessageBuilder({
    Key? key,
    required this.convo,
    required this.message,
    required this.messageWidth,
    this.isReplyContent = false,
  }) : super(key: key);

  @override
  _ImageMessageBuilderState createState() => _ImageMessageBuilderState();
}

class _ImageMessageBuilderState extends State<ImageMessageBuilder> {
  AsyncValue<Uint8List> imageData = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
  }

  Future<void> loadImage() async {
    try {
      imageData = AsyncValue.data(
        await widget.convo
            .imageBinary(widget.message.id)
            .then((value) => value.asTypedList()),
      );
    } catch (e, s) {
      imageData = AsyncValue.error(e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return imageData.when(
      data: (data) {
        if (widget.isReplyContent) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.2,
                maxWidth: MediaQuery.of(context).size.width * 0.2,
              ),
              child: Image.memory(
                data,
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
                errorBuilder: (
                  BuildContext context,
                  Object url,
                  StackTrace? error,
                ) {
                  return Text('Could not load image due to $error');
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
              maxHeight: MediaQuery.of(context).size.height * 0.3,
              maxWidth: MediaQuery.of(context).size.width * 0.3,
            ),
            child: Image.memory(
              data,
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
              errorBuilder: (
                BuildContext context,
                Object url,
                StackTrace? error,
              ) {
                return Text('Could not load image due to $error');
              },
              fit: BoxFit.cover,
            ),
          ),
        );
      },
      error: (e, st) => Text('Error loading image $e'),
      loading: () => const CircularProgressIndicator(),
    );
  }
}
