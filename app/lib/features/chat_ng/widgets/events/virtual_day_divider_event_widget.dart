import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VirtualDayDividerEventWidget extends StatelessWidget {
  const VirtualDayDividerEventWidget({super.key, required this.date});
  final String? date;

  @override
  Widget build(BuildContext context) {
    if (date == null) return const SizedBox.shrink();

    final formattedDate = _formatDateString(context, date!);
    return _buildDayDivider(context, formattedDate);
  }

  String _formatDateString(BuildContext context, String dateString) {
    try {
      final lang = L10n.of(context);

      // Parse the date string (assuming it's in YYYY-MM-DD format)
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final messageDate = DateTime(date.year, date.month, date.day);

      if (messageDate == today) {
        return lang.today;
      } else if (messageDate == yesterday) {
        return lang.yesterday;
      } else {
        // Check if it's the same year
        if (date.year == now.year) {
          // Same year: show day name, date and month (e.g., "Fri, May 17")
          return DateFormat('EEE, d MMM').format(date);
        } else {
          // Different year: show month, date and year (e.g., "May 17, 2025")
          return DateFormat('d MMM, y').format(date);
        }
      }
    } catch (e) {
      // If parsing fails, return the original string
      return dateString;
    }
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
