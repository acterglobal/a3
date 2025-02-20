import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum UpdateSlideType {
  text,
  image,
  video,
}

class UpdateSlideItem {
  UpdateSlideType type;
  String? text;
  String? html;
  Color? backgroundColor;
  Color? foregroundColor;
  XFile? mediaFile;
  RefDetails? refDetails;

  UpdateSlideItem({
    required this.type,
    this.text,
    this.html,
    this.backgroundColor,
    this.foregroundColor,
    this.mediaFile,
    this.refDetails,
  });
}
