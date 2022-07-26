
import 'package:flutter/material.dart';

class LikeAnimation {
  static AnimationController? controller;
  static bool isCliked = false;
  static Set<int> likedIndex = {};
  static void run(int index) {
    likedIndex.add(index);
    isCliked = true;
    controller!.reset();
    controller!.forward();
  }
}
