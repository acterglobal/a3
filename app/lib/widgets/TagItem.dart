import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TagListItem extends StatelessWidget {
  const TagListItem({Key? key, required this.tagTitle, required this.tagColor})
      : super(key: key);
  // final Tag tag;
  final String tagTitle;
  final Color tagColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tagColor,
        ),
      ),
      child: Text(
        tagTitle,
        style: GoogleFonts.roboto(
          color: tagColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
