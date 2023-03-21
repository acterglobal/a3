import 'dart:typed_data';

import 'package:atlas_icons/atlas_icons.dart';
import 'package:colorize_text_avatar/colorize_text_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

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

  // avoid re-run future when object state isn't changed.
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
    try {
      FfiBufferUint8 avatar = await widget.avatar!;
      return avatar.asTypedList();
    } catch (e) {
      return Uint8List(0);
    } // sometimes empty array may be returned
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _avatar,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.tertiary,
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
            child: const Icon(Atlas.team_group_thin),
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
        numberLetters: 1,
        shape: Shape.Circular,
        upperCase: true,
        text: displayName,
      );
    }
    return TextAvatar(
      fontSize: 12,
      numberLetters: 1,
      shape: Shape.Circular,
      upperCase: true,
      text: stringName,
    );
  }
}
