import 'package:acter/common/widgets/render_html.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class CommentWidget extends StatelessWidget {
  final Comment comment;
  const CommentWidget({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final msgContent = comment.msgContent();
    final formatted = msgContent.formattedBody();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(title: Text(comment.sender().toString())),
          formatted != null
              ? RenderHtml(
                  text: formatted,
                )
              : Text(msgContent.body()),
        ],
      ),
    );
  }
}
