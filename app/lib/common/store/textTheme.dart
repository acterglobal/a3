import 'package:effektio/common/store/Colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextTheme {
 static TextTheme textTheme = TextTheme(
    bodyText1: GoogleFonts.roboto(
      fontSize: 16,
      color: AppColors.white,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );
}
