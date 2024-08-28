import 'dart:io';

import 'package:acter/common/models/types.dart';

typedef OnAttachmentSelected = Future<void> Function(
  List<File> files,
  AttachmentType attachmentType,
);
typedef OnLinkSelected = Future<void> Function(
  String title,
  String link,
);
