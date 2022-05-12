import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TagListItem extends StatefulWidget {
  const TagListItem({Key? key, required this.tagTitle}) : super(key: key);
  // final Tag tag;
  final String tagTitle;

  @override
  TagListItemState createState() => TagListItemState();
}

class TagListItemState extends State<TagListItem> {
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      margin: EdgeInsets.fromLTRB(
        4.0,
        0,
        4.0,
        0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.tagTitle,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
