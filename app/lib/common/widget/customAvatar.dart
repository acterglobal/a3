import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:effektio/common/store/Colors.dart';

class CustomAvatar extends StatelessWidget {
  final Future<List<int>> avatar;
  final Future<String> displayName;
  final double radius;
  const CustomAvatar({
    Key? key,
    required this.radius,
    required this.avatar,
    required this.displayName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: avatar,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<int>> snapshot,
      ) {
        if (snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.all(10),
            child: CircleAvatar(
              backgroundImage: MemoryImage(
                Uint8List.fromList(
                  snapshot.requireData,
                ),
              ),
              radius: radius,
            ),
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
                  child: CircleAvatar(
                    backgroundColor: Colors.brown.shade800,
                    child: snapshot.data != null
                        ? Text(snapshot.data!.substring(0, 1))
                        : const Text('N'),
                    radius: radius,
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
      },
    );
  }
}