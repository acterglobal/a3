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
    linkColor: Colors.blue, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.green, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.blue.shade700, // Blue 800
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
    backgroundColor: Colors.amber, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.lightBlueAccent, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.cyan, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.blue.shade800, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.deepOrange, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.blue, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.deepPurple, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.blue, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.indigo, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.lightBlueAccent, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.pink, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.lightBlue, // Blue 800
  ),
  PostColorScheme(
    backgroundColor: Colors.black, // Purple 200
    foregroundColor: Colors.white, // Deep Purple 900
    linkColor: Colors.lightBlue, // Blue 800
  ),
];
