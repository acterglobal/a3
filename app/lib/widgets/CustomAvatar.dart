import 'dart:typed_data';

import 'package:cached_memory_image/provider/cached_memory_image_provider.dart';
import 'package:colorize_text_avatar/colorize_text_avatar.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAvatar extends StatelessWidget {
  final Future<FfiBufferUint8>? avatar;
  final String? displayName;
  final double radius;
  final bool isGroup;
  final String stringName;

  const CustomAvatar({
    Key? key,
    this.avatar,
    this.displayName,
    required this.radius,
    required this.isGroup,
    required this.stringName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (avatar != null) {
      return FutureBuilder<List<int>>(
        future: avatar!.then((fb) => fb.asTypedList()),
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: AppCommonTheme.primaryColor,
              ),
            );
          }
          if (snapshot.hasData && snapshot.requireData.isNotEmpty) {
            return CircleAvatar(
              backgroundImage: CachedMemoryImageProvider(
                UniqueKey().toString(),
                bytes: Uint8List.fromList(snapshot.requireData),
              ),
              radius: radius,
            );
          }
          return _buildTextAvatar();
        },
      );
    }
    if (isGroup) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[700],
        child: SvgPicture.asset('assets/images/people.svg'),
      );
    }
    return _buildTextAvatar();
  }

  Widget _buildTextAvatar() {
    if (displayName != null) {
      return TextAvatar(
        numberLetters: 2,
        shape: Shape.Circular,
        upperCase: true,
        text: displayName,
        size: radius,
      );
    }
    return TextAvatar(
      fontSize: 12,
      numberLetters: 2,
      shape: Shape.Circular,
      upperCase: true,
      text: stringName,
      size: radius,
    );
  }
}
