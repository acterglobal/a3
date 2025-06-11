import 'package:acter/common/utils/utils.dart';
import 'package:flutter/material.dart';

class VirtualDayDividerEventWidget extends StatelessWidget {
  const VirtualDayDividerEventWidget({super.key, required this.date});
  final String? date;

  @override
  Widget build(BuildContext context) {
    if (date == null) return const SizedBox.shrink();

    final formattedDate = formatChatDayDividerDateString(context, date!);
    return _buildDayDivider(context, formattedDate);
  }

  Widget _buildDayDivider(BuildContext context, String date) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: IntrinsicWidth(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: Text(
              date,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.surfaceTint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
