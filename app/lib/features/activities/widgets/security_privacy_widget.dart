import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecurityPrivacyWidget extends ConsumerWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final List<ActionItem>? actions;
  final Color? color;

  const SecurityPrivacyWidget({
    super.key,
    this.icon,
    this.title,
    this.subtitle,
    this.actions,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return securityPrivacyCard(
      context,
      ref,
      icon: icon,
      title: title,
      subtitle: subtitle,
      actions: actions,
      color: color ?? Theme.of(context).colorScheme.error,
    );
  }

  Widget securityPrivacyCard(
    BuildContext context,
    WidgetRef ref, {
    IconData? icon,
    String? title,
    String? subtitle,
    List<ActionItem>? actions,
    Color? color,
  }) {
    final titleTextStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontSize: 15,
        );
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
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width -
                          100, // Account for padding and icon
                    ),
                    child: Text(
                      subtitle ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      if (actions != null)
                        ...actions.map((action) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: OutlinedButton(
                                onPressed: action.onPressed,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context).primaryColor,
                                  side: BorderSide(color: Theme.of(context).primaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  action.label,
                                  style: titleTextStyle,
                                ),
                              ),
                            ),),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionItem {
  final String label;
  final VoidCallback? onPressed;

  const ActionItem({required this.label, this.onPressed});
}
