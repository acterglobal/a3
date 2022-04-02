import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';

class FaqListItem extends StatefulWidget {
  const FaqListItem({Key? key, required this.client, required this.faq})
      : super(key: key);
  final Client client;
  final Faq faq;

  @override
  FaqListItemState createState() => FaqListItemState();
}

class FaqListItemState extends State<FaqListItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        widget.faq.title(),
        style: TextStyle(color: Colors.white),
      ),
      //leading: FlutterLogo(),
      // subtitle: widget.faq,
      leading: Icon(Icons.turned_in_outlined, color: Colors.white),
      // trailing: Radio(
      //   value: 1,
      //   groupValue: groupValue,
      //   onChanged: (value) {
      //     // Update value.
      //   },
      // ),
    );
  }
}
