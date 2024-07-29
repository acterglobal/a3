import 'dart:io';

import 'package:acter/common/models/types.dart';

typedef OnAttachmentSelected = Future<void> Function(
  List<File> files,
  AttachmentType attachmentType,
);
