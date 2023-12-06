import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/widgets/image_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

class ImageMessageBuilder extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final imageFile = ref.watch(imageFileFromMessageIdProvider(message.id));
    return imageFile.when(
      data: (imageFileData) {
        return InkWell(
          onTap: () {
            showAdaptiveDialog(
              context: context,
              barrierDismissible: false,
              useRootNavigator: false,
              builder: (ctx) => ImageDialog(
                title: 'Image',
                imageFile: imageFileData,
              ),
            );
          },
          child: ClipRRect(
            borderRadius: isReplyContent
                ? BorderRadius.circular(6)
                : BorderRadius.circular(15),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    isReplyContent ? size.height * 0.2 : size.height * 0.3,
                maxWidth: isReplyContent ? size.width * 0.2 : size.width * 0.3,
              ),
              child: Image.file(
                imageFileData,
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
          ),
        );
      },
      error: (error, stack) => Center(child: Text('Loading failed: $error')),
      loading: () => const Center(child: Text('Loading image..')),
    );
  }
}
