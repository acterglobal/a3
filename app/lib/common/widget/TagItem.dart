import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TagListItem extends StatefulWidget {
  const TagListItem({Key? key, required this.tagTitle, required this.tagColor})
      : super(key: key);
  // final Tag tag;
  final String tagTitle;
  final Color tagColor;

  @override
  TagListItemState createState() => TagListItemState();
}

class TagListItemState extends State<TagListItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.fromLTRB(
        4.0,
        0,
        4.0,
        0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.tagColor,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.tagTitle,
            style: GoogleFonts.roboto(
              color: widget.tagColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
