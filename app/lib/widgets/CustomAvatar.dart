import 'dart:typed_data';

import 'package:cached_memory_image/provider/cached_memory_image_provider.dart';
import 'package:colorize_text_avatar/colorize_text_avatar.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAvatar extends StatefulWidget {
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
  State<CustomAvatar> createState() => _CustomAvatarState();
}

class _CustomAvatarState extends State<CustomAvatar> {
  Future<List<int>>? getAvatar() async {
    if (widget.avatar != null) {
      List<int> bodyBytes = await widget.avatar!.then((fb) => fb.asTypedList());
      return bodyBytes;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return loadingWidget();
  }

  Widget loadingWidget() {
    return FutureBuilder<List<int>>(
      future: getAvatar(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          const SizedBox(
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
            radius: widget.radius,
          );
        } else if (snapshot.hasError) {
          debugPrint('${snapshot.error}');
          return const Text('❌', style: TextStyle(fontSize: 14.0));
        }
        if (widget.isGroup) {
          return CircleAvatar(
            radius: widget.radius,
            backgroundColor: Colors.grey[700],
            child: SvgPicture.asset('assets/images/people.svg'),
          );
        } else {
          return _buildTextAvatar();
        }
      },
    );
  }

  Widget _buildTextAvatar() {
    if (widget.displayName != null) {
      return TextAvatar(
        numberLetters: 2,
        shape: Shape.Circular,
        upperCase: true,
        text: widget.displayName,
        size: widget.radius,
      );
    }
    return TextAvatar(
      fontSize: 12,
      numberLetters: 2,
      shape: Shape.Circular,
      upperCase: true,
      text: widget.stringName,
      size: widget.radius,
    );
  }
}
