import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:flutter/material.dart';

Widget galleryImagesView(String image) {
  return Container(
    decoration: BoxDecoration(
      color: AppCommonTheme.textFieldColor,
      borderRadius: BorderRadius.circular(25),
    ),
    width: double.infinity,
    height: 200,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Image.network(
        image,
        fit: BoxFit.cover,
      ),
    ),
  );
}
