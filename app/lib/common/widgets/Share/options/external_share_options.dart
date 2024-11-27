import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ExternalShareOptions extends StatelessWidget {
  final String data;

  const ExternalShareOptions({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Share To',
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            iconItem('WhatsApp', PhosphorIcons.whatsappLogo(), Colors.green),
            iconItem('Signal', PhosphorIcons.chat(), Colors.blueGrey),
            iconItem('Telegram', PhosphorIcons.telegramLogo(), Colors.blue),
            iconItem('More', PhosphorIcons.dotsThree(), Colors.grey.shade800),
          ],
        ),
      ],
    );
  }

  Widget iconItem(String name, IconData iconData, Color color) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: color,
                  style: BorderStyle.solid,
                  width: 1.0,
                ),
              ),
              child: Icon(iconData)),
          SizedBox(height: 6),
          Text(name),
        ],
      ),
    );
  }
}
