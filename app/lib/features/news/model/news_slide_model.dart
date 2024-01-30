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
  Color? backgroundColor;
  Color? foregroundColor;
  XFile? mediaFile;

  NewsSlideItem({
    required this.type,
    this.text,
    this.backgroundColor,
    this.foregroundColor,
    this.mediaFile,
  });
}