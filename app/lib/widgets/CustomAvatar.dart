import 'dart:typed_data';

import 'package:colorize_text_avatar/colorize_text_avatar.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAvatar extends StatefulWidget {
  final String uniqueKey;
  final Future<FfiBufferUint8>? avatar;
  final int? cacheHeight;
  final int? cacheWidth;
  final String? displayName;
  final double radius;
  final bool isGroup;
  final String stringName;

  const CustomAvatar({
    Key? key,
    required this.uniqueKey,
    this.avatar,
    this.displayName,
    required this.radius,
    required this.isGroup,
    required this.stringName,
    this.cacheHeight,
    this.cacheWidth,
  }) : super(key: key);

  @override
  State<CustomAvatar> createState() => _CustomAvatarState();
}

class _CustomAvatarState extends State<CustomAvatar> {
  late Future<Uint8List>? _avatar;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _avatar = getAvatar();
    });
  }

  Future<Uint8List>? getAvatar() async {
    if (widget.avatar == null) {
      // hasAvatar == false
      return Uint8List(0);
    }
    FfiBufferUint8 avatar = await widget.avatar!;
    return avatar.asTypedList(); // sometimes empty array may be returned
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _avatar,
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
            foregroundImage: ResizeImage(
              MemoryImage(
                snapshot.requireData,
              ),
              width: widget.cacheWidth ?? 50,
              height: widget.cacheHeight ?? 50,
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
          return SizedBox(
            height: widget.radius * 2,
            width: widget.radius * 2,
            child: _BuildTextAvatar(
              widget.displayName,
              stringName: widget.stringName,
            ),
          );
        }
      },
    );
  }
}

class _BuildTextAvatar extends StatelessWidget {
  const _BuildTextAvatar(this.displayName, {required this.stringName});
  final String? displayName;
  final String stringName;
  @override
  Widget build(BuildContext context) {
    if (displayName != null) {
      return TextAvatar(
        numberLetters: 2,
        shape: Shape.Circular,
        upperCase: true,
        text: displayName,
      );
    }
    return TextAvatar(
      fontSize: 12,
      numberLetters: 2,
      shape: Shape.Circular,
      upperCase: true,
      text: stringName,
    );
  }
}
