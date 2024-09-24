import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:flutter/material.dart';

class CategoryModelLocal {
  final String title;
  final Color? color;
  final ActerIcon? icon;
  final List<String> entries;

  const CategoryModelLocal({
    required this.title,
    this.color,
    this.icon,
    required this.entries,
  });
}
