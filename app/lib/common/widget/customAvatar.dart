import 'dart:typed_data';
import 'package:colorize_text_avatar/colorize_text_avatar.dart';
import 'package:flutter/material.dart';
import 'package:effektio/common/store/Colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAvatar extends StatelessWidget {
  final Future<List<int>> avatar;
  final Future<String>? displayName;
  final double radius;
  final bool isGroup;
  final String stringName;
  const CustomAvatar({
    Key? key,
    required this.radius,
    required this.avatar,
    this.displayName,
    required this.isGroup,
    required this.stringName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: avatar,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<int>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        } else {
          if (snapshot.hasData && snapshot.requireData.isNotEmpty) {
            return CircleAvatar(
              backgroundImage: MemoryImage(
                Uint8List.fromList(
                  snapshot.requireData,
                ),
              ),
              radius: radius,
            );
          } else {
            if (isGroup) {
              return CircleAvatar(
                radius: radius,
                backgroundColor: Colors.grey[700],
                child: SvgPicture.asset('assets/images/people.svg'),
              );
            } else {
              if (stringName.isNotEmpty) {
                return TextAvatar(
                  numberLetters: 2,
                  shape: Shape.Circular,
                  upperCase: true,
                  text: stringName,
                  size: radius,
                );
              } else {
                return FutureBuilder<String>(
                  future: displayName,
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<String> snapshot,
                  ) {
                    if (snapshot.hasData) {
                      return Container(
                        margin: const EdgeInsets.all(10),
                        child: TextAvatar(
                          numberLetters: 2,
                          shape: Shape.Circular,
                          upperCase: true,
                          text: snapshot.data ?? 'N',
                          size: radius,
                        ),
                      );
                    } else {
                      return const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      );
                    }
                  },
                );
              }
            }
          }
        }
      },
    );
  }
}
