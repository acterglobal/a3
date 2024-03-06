import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Attachment, FfiBufferUint8;
import 'package:flutter/material.dart';

class ImageAttachmentPreview extends StatefulWidget {
  final Attachment attachment;
  const ImageAttachmentPreview({super.key, required this.attachment});

  @override
  State<ImageAttachmentPreview> createState() => _ImageAttachmentPreviewState();
}

class _ImageAttachmentPreviewState extends State<ImageAttachmentPreview> {
  late Future<FfiBufferUint8> attachmentImage;

  @override
  void initState() {
    super.initState();
    _getAttachmentImage();
  }

  void _getAttachmentImage() {
    attachmentImage = widget.attachment.sourceBinary(null);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: attachmentImage.then((value) => value.asTypedList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            child: Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
            ),
          );
        } else {
          return Placeholder(
            child: Text('Error loading image ${snapshot.error}'),
          );
        }
      },
    );
  }
}
