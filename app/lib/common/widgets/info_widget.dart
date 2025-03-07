import 'package:flutter/material.dart';

class InfoWidget extends StatelessWidget {
  final String title;
  final String? subTitle;
  final IconData? icon;

  const InfoWidget({super.key, required this.title, this.subTitle, this.icon});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.3),
        border: Border.all(color: primaryColor.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon ?? Icons.info),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: textTheme.titleSmall),
                if (subTitle != null)
                  Text(subTitle!, style: textTheme.labelMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
