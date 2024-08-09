enum PinAttachmentType {
  link,
  image,
  audio,
  video,
  file,
}

class PinAttachment {
  final PinAttachmentType pinAttachmentType;
  final String title;
  final String? link;
  final String? fileExtension;
  final String? path;
  final String? size;

  PinAttachment({
    required this.pinAttachmentType,
    required this.title,
    this.link,
    this.fileExtension,
    this.path,
    this.size,
  });

  PinAttachment copyWith({
    PinAttachmentType? pinAttachmentType,
    String? title,
    String? link,
    String? fileExtension,
    String? path,
    String? size,
  }) =>
      PinAttachment(
        pinAttachmentType: pinAttachmentType ?? this.pinAttachmentType,
        title: title ?? this.title,
        link: link ?? this.link,
        fileExtension: fileExtension ?? this.fileExtension,
        path: path ?? this.path,
        size: size ?? this.size,
      );
}
