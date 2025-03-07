import 'package:acter/common/models/types.dart';

class PinAttachment {
  final AttachmentType attachmentType;
  final String title;
  final String? link;
  final String? fileExtension;
  final String? path;
  final String? size;

  PinAttachment({
    required this.attachmentType,
    required this.title,
    this.link,
    this.fileExtension,
    this.path,
    this.size,
  });

  PinAttachment copyWith({
    AttachmentType? attachmentType,
    String? title,
    String? link,
    String? fileExtension,
    String? path,
    String? size,
  }) => PinAttachment(
    attachmentType: attachmentType ?? this.attachmentType,
    title: title ?? this.title,
    link: link ?? this.link,
    fileExtension: fileExtension ?? this.fileExtension,
    path: path ?? this.path,
    size: size ?? this.size,
  );
}
