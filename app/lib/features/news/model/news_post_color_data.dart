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
    backgroundColor: const Color.fromARGB(255, 107, 65, 50),
    foregroundColor: Colors.white,
    linkColor: Colors.amberAccent,
  ),
  PostColorScheme(
    backgroundColor: const Color.fromARGB(255, 11, 72, 123),
    foregroundColor: Colors.white,
    linkColor: Colors.amberAccent,
  ),
  PostColorScheme(
    backgroundColor: const Color.fromARGB(255, 6, 60, 104),
    foregroundColor: Colors.white,
    linkColor: Colors.amberAccent,
  ),
  PostColorScheme(
    backgroundColor: const Color.fromARGB(255, 2, 106, 96),
    foregroundColor: Colors.white,
    linkColor: Colors.amberAccent,
  ),
  PostColorScheme(
    backgroundColor: const Color.fromARGB(255, 69, 43, 114),
    foregroundColor: Colors.white,
    linkColor: Colors.amberAccent,
  ),
  PostColorScheme(
    backgroundColor: const Color.fromARGB(255, 38, 48, 104),
    foregroundColor: Colors.white,
    linkColor: Colors.amberAccent,
  ),
  PostColorScheme(
    backgroundColor: const Color.fromARGB(255, 10, 10, 10),
    foregroundColor: Colors.white,
    linkColor: Colors.amberAccent,
  ),
];
