import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget navBarTitle(String title) {
  return Text(
    title,
    style: GoogleFonts.montserrat(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
  );
}
