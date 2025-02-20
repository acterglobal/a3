import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecurityPrivacyWidget extends ConsumerWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const SecurityPrivacyWidget({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildLeadingIconUI(context),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTitleSubtitleUI(context),
                  const SizedBox(height: 12),
                  if (actions.isNotEmpty) Row(children: actions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLeadingIconUI(BuildContext context) {
    return Icon(
      icon,
      size: 24,
      color: iconColor ?? Theme.of(context).colorScheme.error,
    );
  }

  Widget buildTitleSubtitleUI(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 100,
          ),
          child: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
