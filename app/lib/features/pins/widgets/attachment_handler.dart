import 'package:acter/features/pins/widgets/image_attachment_preview.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show ActerPin, Attachment;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttachmentTypeHandler extends StatelessWidget {
  final ActerPin pin;
  final Attachment attachment;
  final double? size;
  const AttachmentTypeHandler({
    super.key,
    required this.attachment,
    required this.pin,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    var msgContent = attachment.msgContent();
    String? mimeType = msgContent.mimetype();
    if (mimeType == null) {
      return ErrorWidget(Exception('Invalid Message Content'));
    }
    if (mimeType.startsWith('image/')) {
      return AttachmentContainer(
        pin: pin,
        filename: msgContent.body(),
        child: ImageAttachmentPreview(attachment: attachment),
      );
    } else if (mimeType.startsWith('video/')) {
      return AttachmentContainer(
        pin: pin,
        filename: msgContent.body(),
        child: Center(
          child: Icon(Atlas.file_video_thin, size: size),
        ),
      );
    } else if (mimeType.startsWith('audio/')) {
      return AttachmentContainer(
        pin: pin,
        filename: msgContent.body(),
        child: Center(
          child: Icon(Atlas.file_audio_thin, size: size),
        ),
      );
    } else {
      return AttachmentContainer(
        pin: pin,
        filename: msgContent.body(),
        child: Center(child: Icon(Atlas.file_thin, size: size)),
      );
    }
  }
}

// outer attachment container UI
class AttachmentContainer extends ConsumerWidget {
  const AttachmentContainer({
    super.key,
    required this.pin,
    required this.child,
    required this.filename,
  });
  final ActerPin pin;
  final Widget child;
  final String filename;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containerColor = Theme.of(context).colorScheme.background;
    final borderColor = Theme.of(context).colorScheme.primary;
    final containerTextStyle = Theme.of(context).textTheme.bodySmall;
    return Container(
      height: 100,
      width: 100,
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 0),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(child: child),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            child: Text(
              filename,
              style:
                  containerTextStyle!.copyWith(overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
