import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecommendedSpacesPage extends ConsumerWidget {
  final VoidCallback? callNextPage;
  const RecommendedSpacesPage({super.key, required this.callNextPage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(body: _buildBody(context, ref));
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            _buildHeadlineText(context),
            const SizedBox(height: 10),
            _buildTitleText(context),
            const SizedBox(height: 20),
            _buildActionButtons(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      L10n.of(context).recommendedSpaces,
      style: theme.textTheme.headlineMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }
  // Title text widget
  Widget _buildTitleText(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      L10n.of(context).recommendedSpacesDesc,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  // Action buttons
  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: () {
            callNextPage?.call();
          },
          child: Text(lang.joinAndContinue),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () {
            callNextPage?.call();
          },
          child: Text(lang.skip),
        ),
      ],
    );
  }
}
