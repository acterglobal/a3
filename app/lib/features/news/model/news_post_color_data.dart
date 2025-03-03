import 'package:flutter/material.dart';

class PostColorScheme {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color linkColor;

  const PostColorScheme({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.linkColor,
  });
}

final List<PostColorScheme> postColorSchemes = [
  PostColorScheme(
    backgroundColor: Colors.pinkAccent, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.lightBlueAccent.shade700, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.green, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.lightBlueAccent.shade100, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.brown, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.lightBlueAccent, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.blueGrey, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.lightBlueAccent, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.amber.shade700, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.blue.shade600, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.cyan.shade800, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.lightBlueAccent.shade100, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.indigo.shade700, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.lightBlueAccent.shade100, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.pink.shade300, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.blue.shade600, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.black, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.lightBlue, // Blue 800
  ),
];
