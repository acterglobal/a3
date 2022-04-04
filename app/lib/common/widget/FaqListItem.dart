import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio/screens/faq/Item.dart';

class FaqListItem extends StatefulWidget {
  const FaqListItem({Key? key, required this.client, required this.faq})
      : super(key: key);
  final Client client;
  final Faq faq;

  @override
  FaqListItemState createState() => FaqListItemState();
}

class FaqListItemState extends State<FaqListItem> {
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return FaqItemScreen(client: widget.client, faq: widget.faq);
          }));
        },
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text(
                widget.faq.title(),
                style: optionStyle,
                maxLines: 2,
              ),
              leading: Icon(Icons.turned_in_outlined, color: Colors.grey),
            ),
            Container(
              child: Divider(
                indent: 75,
                endIndent: 15,
                height: 1,
                thickness: 0.5,
                color: Colors.grey[700],
              ),
            ),
          ],
        ));
  }
}
