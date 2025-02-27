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

//https://www.google.com
final List<PostColorScheme> postColorSchemes = [
  PostColorScheme(
    backgroundColor: Colors.brown,
    foregroundColor: Colors.white,
    linkColor: Colors.amber,
  ),
  PostColorScheme(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
    linkColor: Colors.amberAccent,
  ),
  PostColorScheme(
    backgroundColor: Colors.blueGrey,
    foregroundColor: Colors.white,
    linkColor: Colors.amber,
  ),
  PostColorScheme(
    backgroundColor: Colors.deepPurple,
    foregroundColor: Colors.white,
    linkColor: Colors.amberAccent,
  ),
  PostColorScheme(
    backgroundColor: Colors.purple,
    foregroundColor: Colors.white,
    linkColor: Colors.amberAccent,
  ),
  PostColorScheme(
    backgroundColor: Colors.indigo,
    foregroundColor: Colors.white,
    linkColor: Colors.amberAccent,
  ),
  PostColorScheme(
    backgroundColor: Colors.pink,
    foregroundColor: Colors.white,
    linkColor: Colors.cyanAccent,
  ),
];
