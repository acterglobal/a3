import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// cached image binary provider.
final _imageBinaryProvider =
    FutureProvider.family<Uint8List, String>((ref, eventId) async {
  final room = ref.watch(currentConvoProvider)!;
  return await room.imageBinary(eventId).then((value) => value.asTypedList());
});

class ImageMessageBuilder extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final imageData = ref.watch(_imageBinaryProvider(message.id));
    return imageData.when(
      data: (data) {
        if (isReplyContent) {
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
