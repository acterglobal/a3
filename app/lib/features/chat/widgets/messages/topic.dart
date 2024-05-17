import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class TopicWidget extends StatelessWidget {
  final SystemMessage message;
  const TopicWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L10n.of(context).topic,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Html(data: message.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
