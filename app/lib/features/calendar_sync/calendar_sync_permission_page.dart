import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CalendarSyncPermissionPage extends ConsumerWidget {
  const CalendarSyncPermissionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, lang, textTheme, ref),
    );
  }

  // AppBar for the calendar Permission Page
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      actions: [
        IconButton(
          icon: Icon(Icons.close),
          onPressed: () => context.goNamed(Routes.main.name),
          tooltip: 'Close',
        ),
      ],
    );
  }

  // Body content of the calendar Permission Page
  Widget _buildBody(
    BuildContext context,
    L10n lang,
    TextTheme textTheme,
    WidgetRef ref,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             const Spacer(),
            _buildIcon(context),
            const SizedBox(height: 20),
            _buildTitleText(context, lang, textTheme),
            const SizedBox(height: 20),
            _buildDescriptionText(lang, textTheme),
            const SizedBox(height: 40),
            _buildActionButton(context, lang, ref, textTheme),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // Icon at the top of the page
  Widget _buildIcon(BuildContext context) {
    return Icon(
      Icons.calendar_month_rounded,
      color: Theme.of(context).colorScheme.primary,
      size: 100,
    );
  }

  // Title text for the page
  Widget _buildTitleText(BuildContext context, L10n lang, TextTheme textTheme) {
    return Text(
      lang.calendarSync,
      style: textTheme.headlineMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  // Description text for the page
  Widget _buildDescriptionText(L10n lang, TextTheme textTheme) {
    return Text(
      lang.calendarSyncDesc,
      style: textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }

  // Action button for allowing permission or asking again
  Widget _buildActionButton(
    BuildContext context,
    L10n lang,
    WidgetRef ref,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: () async {},
          child: Text(lang.allowPermission),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {
            if (context.mounted) {
              // Navigate back to main page
              context.goNamed(Routes.main.name);
            }
          },
          child: Text(lang.askAgain),
        ),
      ],
    );
  }
}
