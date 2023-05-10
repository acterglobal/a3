import 'package:flutter/material.dart';

class SquareAvatar extends StatelessWidget {
   final double? height;
  final double? width;
  final String? displayImage;
  
  const SquareAvatar({
    super.key, this.height, this.width, this.displayImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: height,
      height: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey,
          width: 2,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.asset(displayImage!),),
      );
  }
}