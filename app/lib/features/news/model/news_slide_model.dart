import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum NewsSlideType {
  text,
  image,
  video,
}

class NewsSlideItem {
  NewsSlideType type;
  String? text;
  String? html;
  Color? backgroundColor;
  Color? foregroundColor;
  XFile? mediaFile;
  RefDetails? refDetails;

  NewsSlideItem({
    required this.type,
    this.text,
    this.html,
    this.backgroundColor,
    this.foregroundColor,
    this.mediaFile,
    this.refDetails,
  });
}
